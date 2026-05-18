-- Arbitration Cases table
CREATE TYPE public.case_status AS ENUM ('active', 'pending', 'closed', 'settled');

CREATE TABLE IF NOT EXISTS public.arbitration_cases (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    case_title TEXT NOT NULL,
    case_number TEXT,
    parties JSONB DEFAULT '{}'::jsonb,
    arbitration_rules TEXT,
    jurisdiction TEXT NOT NULL DEFAULT 'GH',
    filing_date TIMESTAMPTZ,
    status public.case_status NOT NULL DEFAULT 'active',
    created_at TIMESTAMPTZ DEFAULT now() NOT NULL,
    updated_at TIMESTAMPTZ DEFAULT now() NOT NULL
);

ALTER TABLE public.arbitration_cases ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view own cases"
    ON public.arbitration_cases FOR SELECT
    USING (auth.uid() = user_id);

CREATE POLICY "Users can create own cases"
    ON public.arbitration_cases FOR INSERT
    WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own cases"
    ON public.arbitration_cases FOR UPDATE
    USING (auth.uid() = user_id);

CREATE POLICY "Users can delete own cases"
    ON public.arbitration_cases FOR DELETE
    USING (auth.uid() = user_id);

CREATE TRIGGER on_cases_updated
    BEFORE UPDATE ON public.arbitration_cases
    FOR EACH ROW EXECUTE FUNCTION public.handle_updated_at();

-- Case Events table (timelines, deadlines, hearings)
CREATE TYPE public.case_event_type AS ENUM ('deadline', 'hearing', 'filing', 'milestone');

CREATE TABLE IF NOT EXISTS public.case_events (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    case_id UUID NOT NULL REFERENCES public.arbitration_cases(id) ON DELETE CASCADE,
    event_type public.case_event_type NOT NULL,
    title TEXT NOT NULL,
    description TEXT,
    due_date TIMESTAMPTZ NOT NULL,
    is_completed BOOLEAN DEFAULT false,
    completed_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ DEFAULT now() NOT NULL
);

ALTER TABLE public.case_events ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view own case events"
    ON public.case_events FOR SELECT
    USING (
        EXISTS (
            SELECT 1 FROM public.arbitration_cases
            WHERE arbitration_cases.id = case_events.case_id
            AND arbitration_cases.user_id = auth.uid()
        )
    );

CREATE POLICY "Users can create events for own cases"
    ON public.case_events FOR INSERT
    WITH CHECK (
        EXISTS (
            SELECT 1 FROM public.arbitration_cases
            WHERE arbitration_cases.id = case_events.case_id
            AND arbitration_cases.user_id = auth.uid()
        )
    );

CREATE POLICY "Users can update own case events"
    ON public.case_events FOR UPDATE
    USING (
        EXISTS (
            SELECT 1 FROM public.arbitration_cases
            WHERE arbitration_cases.id = case_events.case_id
            AND arbitration_cases.user_id = auth.uid()
        )
    );

CREATE POLICY "Users can delete own case events"
    ON public.case_events FOR DELETE
    USING (
        EXISTS (
            SELECT 1 FROM public.arbitration_cases
            WHERE arbitration_cases.id = case_events.case_id
            AND arbitration_cases.user_id = auth.uid()
        )
    );

CREATE INDEX idx_case_events_case_id ON public.case_events(case_id);
CREATE INDEX idx_case_events_due_date ON public.case_events(due_date);
