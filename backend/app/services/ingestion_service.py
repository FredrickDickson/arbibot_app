"""Ingestion service for processing and storing legal documents.

Coordinates document processing, embedding generation, and storage
in Supabase with pgvector support.
"""

from typing import List, Dict, Optional
from supabase import Client
from .document_processor import get_document_processor
from .embedding_service import get_embedding_service


class IngestionService:
    """Service for ingesting legal documents into the RAG system."""

    def __init__(self, db: Client):
        self.db = db
        self.document_processor = get_document_processor()
        self.embedding_service = get_embedding_service()

    async def ingest_document(
        self,
        file_path: str,
        title: str,
        source_type: str,
        jurisdiction: str = "GH",
        use_ocr: bool = False,
        user_id: Optional[str] = None,
    ) -> Dict:
        """Ingest a document end-to-end.

        Args:
            file_path: Path to document file
            title: Document title
            source_type: Type of legal source (statute, case_law, regulation)
            jurisdiction: Jurisdiction code
            use_ocr: Whether to use OCR for PDFs
            user_id: User ID for tracking (optional)

        Returns:
            Dictionary with source_id, chunk_count, and status
        """
        # Process document
        processed = self.document_processor.process_document(
            file_path=file_path,
            title=title,
            source_type=source_type,
            jurisdiction=jurisdiction,
            use_ocr=use_ocr,
        )

        # Create legal source record
        source_data = {
            "title": title,
            "source_type": source_type,
            "jurisdiction": jurisdiction,
            "content": processed["full_text"],
            "metadata": processed["metadata"],
        }

        source_result = self.db.table("legal_sources").insert(source_data).execute()
        source_id = source_result.data[0]["id"]

        # Generate embeddings for chunks
        chunks = processed["chunks"]
        chunk_texts = [chunk["chunk_text"] for chunk in chunks]
        embeddings = await self.embedding_service.generate_embeddings_batch(chunk_texts)

        # Store chunks with embeddings
        chunk_records = []
        for idx, (chunk, embedding) in enumerate(zip(chunks, embeddings)):
            chunk_record = {
                "source_id": source_id,
                "chunk_text": chunk["chunk_text"],
                "chunk_index": chunk["chunk_index"],
                "section_reference": chunk.get("section_reference"),
                "page_number": chunk.get("page_number"),
                "embedding": embedding,
                "confidence_score": 1.0,
            }
            chunk_records.append(chunk_record)

        # Insert chunks in batches
        batch_size = 100
        for i in range(0, len(chunk_records), batch_size):
            batch = chunk_records[i : i + batch_size]
            self.db.table("document_chunks").insert(batch).execute()

        return {
            "source_id": source_id,
            "chunk_count": len(chunk_records),
            "status": "completed",
            "metadata": processed["metadata"],
        }

    async def ingest_text(
        self,
        text: str,
        title: str,
        source_type: str,
        jurisdiction: str = "GH",
        user_id: Optional[str] = None,
    ) -> Dict:
        """Ingest plain text directly.

        Args:
            text: Plain text content
            title: Document title
            source_type: Type of legal source
            jurisdiction: Jurisdiction code
            user_id: User ID for tracking (optional)

        Returns:
            Dictionary with source_id, chunk_count, and status
        """
        # Create document metadata
        doc_metadata = {
            "title": title,
            "source_type": source_type,
            "jurisdiction": jurisdiction,
            "total_characters": len(text),
        }

        # Chunk the text
        chunks = self.document_processor.chunk_text(text, doc_metadata)

        # Create legal source record
        source_data = {
            "title": title,
            "source_type": source_type,
            "jurisdiction": jurisdiction,
            "content": text,
            "metadata": doc_metadata,
        }

        source_result = self.db.table("legal_sources").insert(source_data).execute()
        source_id = source_result.data[0]["id"]

        # Generate embeddings
        chunk_texts = [chunk["chunk_text"] for chunk in chunks]
        embeddings = await self.embedding_service.generate_embeddings_batch(chunk_texts)

        # Store chunks
        chunk_records = []
        for idx, (chunk, embedding) in enumerate(zip(chunks, embeddings)):
            chunk_record = {
                "source_id": source_id,
                "chunk_text": chunk["chunk_text"],
                "chunk_index": chunk["chunk_index"],
                "section_reference": chunk.get("section_reference"),
                "embedding": embedding,
                "confidence_score": 1.0,
            }
            chunk_records.append(chunk_record)

        # Insert chunks
        batch_size = 100
        for i in range(0, len(chunk_records), batch_size):
            batch = chunk_records[i : i + batch_size]
            self.db.table("document_chunks").insert(batch).execute()

        return {
            "source_id": source_id,
            "chunk_count": len(chunk_records),
            "status": "completed",
            "metadata": doc_metadata,
        }

    async def delete_document(self, source_id: str) -> Dict:
        """Delete a document and all its chunks.

        Args:
            source_id: UUID of the legal source

        Returns:
            Status dictionary
        """
        # Chunks are deleted automatically via CASCADE
        result = self.db.table("legal_sources").delete().eq("id", source_id).execute()
        return {"status": "deleted", "source_id": source_id}

    async def search_similar_chunks(
        self,
        query: str,
        match_threshold: float = 0.75,
        match_count: int = 10,
        source_type: Optional[str] = None,
        jurisdiction: Optional[str] = None,
    ) -> List[Dict]:
        """Search for similar chunks using vector similarity.

        Args:
            query: Search query text
            match_threshold: Similarity threshold (0-1)
            match_count: Maximum number of results
            source_type: Filter by source type (optional)
            jurisdiction: Filter by jurisdiction (optional)

        Returns:
            List of matching chunks with similarity scores
        """
        # Generate query embedding
        query_embedding = await self.embedding_service.generate_query_embedding(query)

        # Use Supabase RPC function for similarity search
        params = {
            "query_embedding": query_embedding,
            "match_threshold": match_threshold,
            "match_count": match_count,
        }

        result = self.db.rpc("match_documents", params=params).execute()

        chunks = result.data

        # Apply additional filters if specified
        if source_type or jurisdiction:
            # Get source_ids for chunks
            source_ids = [chunk["source_id"] for chunk in chunks]
            sources = (
                self.db.table("legal_sources")
                .select("id, source_type, jurisdiction, title")
                .in_("id", source_ids)
                .execute()
            )
            sources_dict = {s["id"]: s for s in sources.data}

            # Filter chunks
            filtered_chunks = []
            for chunk in chunks:
                source = sources_dict.get(chunk["source_id"])
                if source:
                    if source_type and source["source_type"] != source_type:
                        continue
                    if jurisdiction and source["jurisdiction"] != jurisdiction:
                        continue
                    chunk["source_metadata"] = source
                    filtered_chunks.append(chunk)

            return filtered_chunks

        # Add source metadata to all chunks
        source_ids = [chunk["source_id"] for chunk in chunks]
        sources = (
            self.db.table("legal_sources")
            .select("id, source_type, jurisdiction, title")
            .in_("id", source_ids)
            .execute()
        )
        sources_dict = {s["id"]: s for s in sources.data}

        for chunk in chunks:
            chunk["source_metadata"] = sources_dict.get(chunk["source_id"])

        return chunks

    async def get_document_stats(self) -> Dict:
        """Get statistics about ingested documents.

        Returns:
            Dictionary with document counts by type, jurisdiction, etc.
        """
        sources = self.db.table("legal_sources").select("*").execute()
        chunks = self.db.table("document_chunks").select("source_id").execute()

        total_sources = len(sources.data)
        total_chunks = len(chunks.data)

        # Count by source type
        by_type = {}
        for source in sources.data:
            stype = source["source_type"]
            by_type[stype] = by_type.get(stype, 0) + 1

        # Count by jurisdiction
        by_jurisdiction = {}
        for source in sources.data:
            jur = source["jurisdiction"]
            by_jurisdiction[jur] = by_jurisdiction.get(jur, 0) + 1

        return {
            "total_sources": total_sources,
            "total_chunks": total_chunks,
            "by_type": by_type,
            "by_jurisdiction": by_jurisdiction,
        }


def get_ingestion_service(db: Client) -> IngestionService:
    return IngestionService(db)
