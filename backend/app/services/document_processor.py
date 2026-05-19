"""Document processing service for PDF/text extraction and legal-aware chunking.

Supports:
- PDF text extraction (pypdf, pdfplumber)
- OCR for scanned PDFs (Tesseract)
- Legal-aware chunking (preserves sections, paragraphs)
- Metadata extraction (section, page, jurisdiction)
"""

import re
from typing import List, Dict, Optional, Tuple
from pathlib import Path
import pypdf
import pdfplumber
from langchain_text_splitters import RecursiveCharacterTextSplitter


class DocumentProcessor:
    """Process legal documents with legal-aware chunking strategy."""

    def __init__(self):
        # Legal-aware text splitter
        self.splitter = RecursiveCharacterTextSplitter(
            chunk_size=800,  # ~500-1000 tokens
            chunk_overlap=150,  # ~100-200 tokens overlap
            length_function=len,
            separators=["\n\n\n", "\n\n", "\n", ". ", " ", ""],
        )

    def extract_text_from_pdf(
        self, pdf_path: str, use_ocr: bool = False
    ) -> Tuple[str, List[Dict]]:
        """Extract text from PDF file.

        Args:
            pdf_path: Path to PDF file
            use_ocr: Whether to use OCR for scanned PDFs

        Returns:
            Tuple of (extracted_text, page_metadata)
        """
        if use_ocr:
            return self._extract_with_ocr(pdf_path)
        return self._extract_with_pdfplumber(pdf_path)

    def _extract_with_pdfplumber(self, pdf_path: str) -> Tuple[str, List[Dict]]:
        """Extract text using pdfplumber (better for structured PDFs)."""
        text_parts = []
        page_metadata = []

        try:
            with pdfplumber.open(pdf_path) as pdf:
                for page_num, page in enumerate(pdf.pages, start=1):
                    page_text = page.extract_text()
                    if page_text:
                        text_parts.append(page_text)
                        page_metadata.append({
                            "page_number": page_num,
                            "text_length": len(page_text),
                        })
        except Exception as e:
            # Fallback to pypdf if pdfplumber fails
            return self._extract_with_pypdf(pdf_path)

        return "\n\n".join(text_parts), page_metadata

    def _extract_with_pypdf(self, pdf_path: str) -> Tuple[str, List[Dict]]:
        """Extract text using pypdf (fallback)."""
        text_parts = []
        page_metadata = []

        try:
            with open(pdf_path, "rb") as file:
                pdf_reader = pypdf.PdfReader(file)
                for page_num, page in enumerate(pdf_reader.pages, start=1):
                    page_text = page.extract_text()
                    if page_text:
                        text_parts.append(page_text)
                        page_metadata.append({
                            "page_number": page_num,
                            "text_length": len(page_text),
                        })
        except Exception as e:
            raise Exception(f"Failed to extract PDF text: {str(e)}")

        return "\n\n".join(text_parts), page_metadata

    def _extract_with_ocr(self, pdf_path: str) -> Tuple[str, List[Dict]]:
        """Extract text using OCR for scanned PDFs."""
        try:
            import pytesseract
            from PIL import Image
            import io

            text_parts = []
            page_metadata = []

            with open(pdf_path, "rb") as file:
                pdf_reader = pypdf.PdfReader(file)
                for page_num, page in enumerate(pdf_reader.pages, start=1):
                    # Convert PDF page to image
                    page_text = pytesseract.image_to_string(
                        Image.open(io.BytesIO(page))
                    )
                    if page_text:
                        text_parts.append(page_text)
                        page_metadata.append({
                            "page_number": page_num,
                            "text_length": len(page_text),
                            "ocr_used": True,
                        })

            return "\n\n".join(text_parts), page_metadata
        except ImportError:
            raise Exception(
                "Tesseract OCR not installed. "
                "Install it or disable OCR for this document."
            )
        except Exception as e:
            raise Exception(f"OCR extraction failed: {str(e)}")

    def extract_sections(self, text: str) -> List[Dict]:
        """Extract legal sections from text (e.g., Section 1, Article 2).

        Args:
            text: Document text

        Returns:
            List of section dictionaries with start/end positions
        """
        sections = []

        # Common legal section patterns
        section_patterns = [
            r"Section\s+(\d+[A-Za-z]*)",  # Section 1, Section 2A
            r"Article\s+(\d+[A-Za-z]*)",  # Article 1, Article 2A
            r"Chapter\s+(\d+[A-Za-z]*)",  # Chapter 1
            r"Part\s+(\d+[A-Za-z]*)",  # Part 1
            r"\d+\.\s+",  # Numbered paragraphs
        ]

        for pattern in section_patterns:
            for match in re.finditer(pattern, text, re.IGNORECASE):
                sections.append({
                    "section_reference": match.group(),
                    "start_pos": match.start(),
                    "pattern": pattern,
                })

        # Sort by position
        sections.sort(key=lambda x: x["start_pos"])
        return sections

    def chunk_text(
        self,
        text: str,
        metadata: Dict = None,
        preserve_sections: bool = True,
    ) -> List[Dict]:
        """Chunk text with legal-aware strategy.

        Args:
            text: Document text
            metadata: Document metadata (title, jurisdiction, etc.)
            preserve_sections: Whether to preserve section boundaries

        Returns:
            List of chunk dictionaries with text and metadata
        """
        if metadata is None:
            metadata = {}

        if preserve_sections:
            # Extract sections first
            sections = self.extract_sections(text)
            if sections:
                return self._chunk_by_sections(text, sections, metadata)

        # Fallback to standard chunking
        chunks = self.splitter.split_text(text)

        chunk_dicts = []
        for idx, chunk in enumerate(chunks):
            chunk_dict = {
                "chunk_text": chunk,
                "chunk_index": idx,
                "section_reference": None,
                "page_number": metadata.get("page_number"),
                "metadata": metadata,
            }
            chunk_dicts.append(chunk_dict)

        return chunk_dicts

    def _chunk_by_sections(
        self, text: str, sections: List[Dict], metadata: Dict
    ) -> List[Dict]:
        """Chunk text preserving section boundaries."""
        chunk_dicts = []
        chunk_index = 0

        for i, section in enumerate(sections):
            start = section["start_pos"]
            end = sections[i + 1]["start_pos"] if i + 1 < len(sections) else len(text)
            section_text = text[start:end].strip()

            if not section_text:
                continue

            # Split section into chunks if too long
            section_chunks = self.splitter.split_text(section_text)

            for j, chunk in enumerate(section_chunks):
                chunk_dict = {
                    "chunk_text": chunk,
                    "chunk_index": chunk_index,
                    "section_reference": section["section_reference"],
                    "page_number": metadata.get("page_number"),
                    "metadata": metadata,
                }
                chunk_dicts.append(chunk_dict)
                chunk_index += 1

        # Handle text before first section
        if sections and sections[0]["start_pos"] > 0:
            intro_text = text[: sections[0]["start_pos"]].strip()
            if intro_text:
                intro_chunks = self.splitter.split_text(intro_text)
                for chunk in intro_chunks:
                    chunk_dict = {
                        "chunk_text": chunk,
                        "chunk_index": chunk_index,
                        "section_reference": "Introduction",
                        "page_number": metadata.get("page_number"),
                        "metadata": metadata,
                    }
                    chunk_dicts.append(chunk_dict)
                    chunk_index += 1

        return chunk_dicts

    def process_document(
        self,
        file_path: str,
        title: str,
        source_type: str,
        jurisdiction: str = "GH",
        use_ocr: bool = False,
    ) -> Dict:
        """Process document end-to-end.

        Args:
            file_path: Path to document file
            title: Document title
            source_type: Type of legal source (statute, case_law, regulation)
            jurisdiction: Jurisdiction code
            use_ocr: Whether to use OCR for PDFs

        Returns:
            Dictionary with processed data and chunks
        """
        file_ext = Path(file_path).suffix.lower()

        if file_ext == ".pdf":
            text, page_metadata = self.extract_text_from_pdf(file_path, use_ocr)
        elif file_ext in [".txt", ".md"]:
            with open(file_path, "r", encoding="utf-8") as f:
                text = f.read()
            page_metadata = [{"page_number": 1, "text_length": len(text)}]
        else:
            raise ValueError(f"Unsupported file type: {file_ext}")

        # Create document metadata
        doc_metadata = {
            "title": title,
            "source_type": source_type,
            "jurisdiction": jurisdiction,
            "total_pages": len(page_metadata),
            "total_characters": len(text),
        }

        # Chunk the text
        chunks = self.chunk_text(text, doc_metadata, preserve_sections=True)

        return {
            "metadata": doc_metadata,
            "full_text": text,
            "chunks": chunks,
            "page_metadata": page_metadata,
        }


def get_document_processor() -> DocumentProcessor:
    return DocumentProcessor()
