"""Ingestion API router for document upload and processing.

Provides endpoints for:
- Document upload (PDF/text)
- Plain text ingestion
- Processing status
- Document deletion
- Bulk ingestion (admin)
- Similarity search
"""

from fastapi import APIRouter, UploadFile, File, Form, HTTPException, Depends
from supabase import Client
from pydantic import BaseModel
from typing import Optional, List

from ..dependencies import get_current_user_id, get_db
from ..services.ingestion_service import get_ingestion_service
from ..services.embedding_service import get_embedding_service

router = APIRouter(prefix="/api/v1/ingestion", tags=["Ingestion"])


# Request/Response Models
class IngestTextRequest(BaseModel):
    text: str
    title: str
    source_type: str  # statute, case_law, regulation
    jurisdiction: str = "GH"


class SearchRequest(BaseModel):
    query: str
    match_threshold: float = 0.75
    match_count: int = 10
    source_type: Optional[str] = None
    jurisdiction: Optional[str] = None


class IngestionResponse(BaseModel):
    source_id: str
    chunk_count: int
    status: str


@router.post("/upload", response_model=IngestionResponse)
async def upload_document(
    file: UploadFile = File(...),
    title: str = Form(...),
    source_type: str = Form(...),
    jurisdiction: str = Form("GH"),
    use_ocr: bool = Form(False),
    user_id: str = Depends(get_current_user_id),
    db: Client = Depends(get_db),
):
    """Upload and ingest a document (PDF or text file)."""
    # Validate file type
    allowed_extensions = {".pdf", ".txt", ".md"}
    file_ext = file.filename.lower()
    if not any(file_ext.endswith(ext) for ext in allowed_extensions):
        raise HTTPException(
            status_code=400,
            detail=f"Unsupported file type. Allowed: {', '.join(allowed_extensions)}",
        )

    # Save file temporarily
    import tempfile
    import os

    with tempfile.NamedTemporaryFile(delete=False, suffix=file_ext) as tmp_file:
        content = await file.read()
        tmp_file.write(content)
        tmp_file_path = tmp_file.name

    try:
        ingestion_service = get_ingestion_service(db)
        result = await ingestion_service.ingest_document(
            file_path=tmp_file_path,
            title=title,
            source_type=source_type,
            jurisdiction=jurisdiction,
            use_ocr=use_ocr,
            user_id=user_id,
        )
        return result
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))
    finally:
        # Clean up temporary file
        if os.path.exists(tmp_file_path):
            os.remove(tmp_file_path)


@router.post("/text", response_model=IngestionResponse)
async def ingest_text(
    request: IngestTextRequest,
    user_id: str = Depends(get_current_user_id),
    db: Client = Depends(get_db),
):
    """Ingest plain text directly."""
    try:
        ingestion_service = get_ingestion_service(db)
        result = await ingestion_service.ingest_text(
            text=request.text,
            title=request.title,
            source_type=request.source_type,
            jurisdiction=request.jurisdiction,
            user_id=user_id,
        )
        return result
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


@router.get("/stats")
async def get_ingestion_stats(
    user_id: str = Depends(get_current_user_id),
    db: Client = Depends(get_db),
):
    """Get statistics about ingested documents."""
    try:
        ingestion_service = get_ingestion_service(db)
        stats = await ingestion_service.get_document_stats()
        return stats
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


@router.delete("/{source_id}")
async def delete_document(
    source_id: str,
    user_id: str = Depends(get_current_user_id),
    db: Client = Depends(get_db),
):
    """Delete a document and all its chunks."""
    try:
        ingestion_service = get_ingestion_service(db)
        result = await ingestion_service.delete_document(source_id)
        return result
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


@router.post("/search")
async def search_similar_chunks(
    request: SearchRequest,
    user_id: str = Depends(get_current_user_id),
    db: Client = Depends(get_db),
):
    """Search for similar chunks using vector similarity."""
    try:
        ingestion_service = get_ingestion_service(db)
        results = await ingestion_service.search_similar_chunks(
            query=request.query,
            match_threshold=request.match_threshold,
            match_count=request.match_count,
            source_type=request.source_type,
            jurisdiction=request.jurisdiction,
        )
        return {"results": results}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


@router.get("/health")
async def health_check():
    """Check if Ollama embedding service is available."""
    try:
        embedding_service = get_embedding_service()
        is_healthy = embedding_service.check_connection()
        return {
            "status": "healthy" if is_healthy else "unhealthy",
            "ollama_available": is_healthy,
            "model": "nomic-embed-text",
        }
    except Exception as e:
        return {
            "status": "unhealthy",
            "ollama_available": False,
            "error": str(e),
        }


@router.post("/batch")
async def bulk_ingestion(
    documents: List[IngestTextRequest],
    user_id: str = Depends(get_current_user_id),
    db: Client = Depends(get_db),
):
    """Bulk ingest multiple text documents (admin only)."""
    results = []
    try:
        ingestion_service = get_ingestion_service(db)
        for doc in documents:
            result = await ingestion_service.ingest_text(
                text=doc.text,
                title=doc.title,
                source_type=doc.source_type,
                jurisdiction=doc.jurisdiction,
                user_id=user_id,
            )
            results.append(result)
        return {"results": results, "total": len(results)}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))
