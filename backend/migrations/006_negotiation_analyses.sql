-- Negotiation Analyses table
CREATE TABLE IF NOT EXISTS public.negotiation_analyses (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    case_id UUID REFERENCES public.arbitration_cases(id) ON DELETE SET NULL,
    dispute_summary TEXT NOT NULL,
    batna JSONB DEFAULT '[]'::jsonb,
    watna JSONB DEFAULT '[]'::jsonb,
    settlement_range JSONB DEFAULT '{}'::jsonb,
    strategy_notes TEXT DEFAULT '',
    created_at TIMESTAMPTZ DEFAULT now() NOT NULL
);

ALTER TABLE public.negotiation_analyses ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view own analyses"
    ON public.negotiation_analyses FOR SELECT
    USING (auth.uid() = user_id);

CREATE POLICY "Users can create own analyses"
    ON public.negotiation_analyses FOR INSERT
    WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can delete own analyses"
    ON public.negotiation_analyses FOR DELETE
    USING (auth.uid() = user_id);

CREATE INDEX idx_negotiation_user_id ON public.negotiation_analyses(user_id);
