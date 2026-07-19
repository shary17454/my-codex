ALTER TABLE comparisons
    ADD COLUMN IF NOT EXISTS visibility TEXT NOT NULL DEFAULT 'publicRoom',
    ADD COLUMN IF NOT EXISTS invite_code VARCHAR(12),
    ADD COLUMN IF NOT EXISTS hide_results_until_vote BOOLEAN NOT NULL DEFAULT FALSE,
    ADD COLUMN IF NOT EXISTS owner_client_hash TEXT;

ALTER TABLE comparisons
    DROP CONSTRAINT IF EXISTS comparisons_visibility_check;

ALTER TABLE comparisons
    ADD CONSTRAINT comparisons_visibility_check
    CHECK (visibility IN ('publicRoom', 'linkOnly', 'inviteCode'));

CREATE UNIQUE INDEX IF NOT EXISTS idx_comparisons_invite_code
    ON comparisons(invite_code)
    WHERE invite_code IS NOT NULL;

ALTER TABLE votes
    ADD COLUMN IF NOT EXISTS tried_option BOOLEAN NOT NULL DEFAULT FALSE;

ALTER TABLE votes
    DROP CONSTRAINT IF EXISTS votes_reason_length_check;

ALTER TABLE votes
    ADD CONSTRAINT votes_reason_length_check
    CHECK (reason IS NULL OR char_length(reason) <= 300);

CREATE TABLE IF NOT EXISTS decision_outcomes (
    id UUID PRIMARY KEY,
    comparison_id UUID NOT NULL REFERENCES comparisons(id) ON DELETE CASCADE,
    option_id UUID NOT NULL REFERENCES comparison_options(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    satisfaction_score INTEGER NOT NULL CHECK (satisfaction_score BETWEEN 1 AND 5),
    would_choose_again BOOLEAN NOT NULL,
    note VARCHAR(300) NOT NULL DEFAULT '',
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    UNIQUE (comparison_id, user_id)
);

CREATE INDEX IF NOT EXISTS idx_outcomes_comparison_option
    ON decision_outcomes(comparison_id, option_id);

CREATE TABLE IF NOT EXISTS moderation_audit_events (
    id UUID PRIMARY KEY,
    actor_id UUID REFERENCES users(id) ON DELETE SET NULL,
    action TEXT NOT NULL,
    content_id UUID,
    metadata JSONB NOT NULL DEFAULT '{}',
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_moderation_audit_created
    ON moderation_audit_events(created_at DESC);
