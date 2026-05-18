-- Drafts table
CREATE TYPE public.document_type AS ENUM ('statement_of_case', 'legal_opinion', 'submission');
CREATE TYPE public.draft_status AS ENUM ('draft', 'pending_review', 'approved', 'rejected');

CREATE TABLE IF NOT EXISTS public.drafts (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    conversation_id UUID REFERENCES public.conversations(id) ON DELETE SET NULL,
    document_type public.document_type NOT NULL,
    title TEXT NOT NULL,
    jurisdiction TEXT NOT NULL DEFAULT 'GH',
    status public.draft_status NOT NULL DEFAULT 'draft',
    sections JSONB DEFAULT '[]'::jsonb,
    citations JSONB DEFAULT '[]'::jsonb,
    created_at TIMESTAMPTZ DEFAULT now() NOT NULL,
    updated_at TIMESTAMPTZ DEFAULT now() NOT NULL,
    approved_at TIMESTAMPTZ
);

ALTER TABLE public.drafts ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view own drafts"
    ON public.drafts FOR SELECT
    USING (auth.uid() = user_id);

CREATE POLICY "Users can create own drafts"
    ON public.drafts FOR INSERT
    WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own drafts"
    ON public.drafts FOR UPDATE
    USING (auth.uid() = user_id);

CREATE POLICY "Users can delete own drafts"
    ON public.drafts FOR DELETE
    USING (auth.uid() = user_id);

CREATE TRIGGER on_drafts_updated
    BEFORE UPDATE ON public.drafts
    FOR EACH ROW EXECUTE FUNCTION public.handle_updated_at();

CREATE INDEX idx_drafts_user_id ON public.drafts(user_id);
CREATE INDEX idx_drafts_status ON public.drafts(status);
