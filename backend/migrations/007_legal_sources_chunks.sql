-- Legal Sources table (for RAG / OCR pipeline)
CREATE TYPE public.legal_source_type AS ENUM ('statute', 'case_law', 'regulation');

CREATE TABLE IF NOT EXISTS public.legal_sources (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    title TEXT NOT NULL,
    source_type public.legal_source_type NOT NULL,
    jurisdiction TEXT NOT NULL DEFAULT 'GH',
    year INTEGER,
    is_valid BOOLEAN DEFAULT true,
    content TEXT,
    metadata JSONB DEFAULT '{}'::jsonb,
    created_at TIMESTAMPTZ DEFAULT now() NOT NULL
);

ALTER TABLE public.legal_sources ENABLE ROW LEVEL SECURITY;

-- Legal sources are read-only for authenticated users (service role writes)
CREATE POLICY "Authenticated users can read legal sources"
    ON public.legal_sources FOR SELECT
    TO authenticated
    USING (true);

CREATE INDEX idx_legal_sources_type ON public.legal_sources(source_type);
CREATE INDEX idx_legal_sources_jurisdiction ON public.legal_sources(jurisdiction);

-- Document Chunks table (for pgvector embeddings)
CREATE TABLE IF NOT EXISTS public.document_chunks (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    source_id UUID NOT NULL REFERENCES public.legal_sources(id) ON DELETE CASCADE,
    chunk_text TEXT NOT NULL,
    chunk_index INTEGER NOT NULL,
    section_reference TEXT,
    page_number INTEGER,
    embedding extensions.vector(1536),
    confidence_score FLOAT DEFAULT 1.0,
    created_at TIMESTAMPTZ DEFAULT now() NOT NULL
);

ALTER TABLE public.document_chunks ENABLE ROW LEVEL SECURITY;

-- Chunks are read-only for authenticated users
CREATE POLICY "Authenticated users can read document chunks"
    ON public.document_chunks FOR SELECT
    TO authenticated
    USING (true);

-- pgvector index for similarity search
CREATE INDEX idx_document_chunks_embedding
    ON public.document_chunks
    USING ivfflat (embedding extensions.vector_cosine_ops)
    WITH (lists = 100);

CREATE INDEX idx_document_chunks_source_id ON public.document_chunks(source_id);
CREATE INDEX idx_document_chunks_confidence ON public.document_chunks(confidence_score);

-- Helper function for similarity search
CREATE OR REPLACE FUNCTION public.match_documents(
    query_embedding extensions.vector(1536),
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
