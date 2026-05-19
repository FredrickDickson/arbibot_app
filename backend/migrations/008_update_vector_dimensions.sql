-- Migration: Update pgvector dimensions from 1536 (OpenAI) to 768 (Ollama nomic-embed-text)
-- This drops and recreates document_chunks table with correct vector dimensions

-- Drop existing document_chunks table (no production data expected)
DROP TABLE IF EXISTS public.document_chunks CASCADE;

-- Recreate document_chunks with 768-dim embeddings for Ollama
CREATE TABLE IF NOT EXISTS public.document_chunks (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    source_id UUID NOT NULL REFERENCES public.legal_sources(id) ON DELETE CASCADE,
    chunk_text TEXT NOT NULL,
    chunk_index INTEGER NOT NULL,
    section_reference TEXT,
    page_number INTEGER,
    embedding extensions.vector(768),
    confidence_score FLOAT DEFAULT 1.0,
    created_at TIMESTAMPTZ DEFAULT now() NOT NULL
);

ALTER TABLE public.document_chunks ENABLE ROW LEVEL SECURITY;

-- Chunks are read-only for authenticated users
CREATE POLICY "Authenticated users can read document chunks"
    ON public.document_chunks FOR SELECT
    TO authenticated
    USING (true);

-- pgvector index for similarity search with 768-dim
CREATE INDEX idx_document_chunks_embedding
    ON public.document_chunks
    USING ivfflat (embedding extensions.vector_cosine_ops)
    WITH (lists = 100);

CREATE INDEX idx_document_chunks_source_id ON public.document_chunks(source_id);
CREATE INDEX idx_document_chunks_confidence ON public.document_chunks(confidence_score);

-- Update similarity search function for 768-dim embeddings
CREATE OR REPLACE FUNCTION public.match_documents(
    query_embedding extensions.vector(768),
    match_threshold FLOAT DEFAULT 0.75,
    match_count INT DEFAULT 10
)
RETURNS TABLE (
    id UUID,
    source_id UUID,
    chunk_text TEXT,
    section_reference TEXT,
    page_number INTEGER,
    confidence_score FLOAT,
    similarity FLOAT
)
LANGUAGE sql STABLE
AS $$
    SELECT
        dc.id,
        dc.source_id,
        dc.chunk_text,
        dc.section_reference,
        dc.page_number,
        dc.confidence_score,
        1 - (dc.embedding <=> query_embedding) AS similarity
    FROM public.document_chunks dc
    WHERE 1 - (dc.embedding <=> query_embedding) > match_threshold
      AND dc.confidence_score >= 0.75
    ORDER BY dc.embedding <=> query_embedding
    LIMIT match_count;
$$;
