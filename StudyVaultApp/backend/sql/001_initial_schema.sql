CREATE TABLE IF NOT EXISTS users (
    id UUID PRIMARY KEY,
    apple_user_identifier TEXT UNIQUE,
    display_name TEXT NOT NULL,
    reputation_score INTEGER NOT NULL DEFAULT 0,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS comparisons (
    id UUID PRIMARY KEY,
    title TEXT NOT NULL,
    details TEXT NOT NULL DEFAULT '',
    category TEXT NOT NULL,
    author_id UUID REFERENCES users(id) ON DELETE SET NULL,
    author_name TEXT NOT NULL DEFAULT 'مجهول',
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    expires_at TIMESTAMPTZ,
    is_anonymous BOOLEAN NOT NULL DEFAULT FALSE,
    allows_comments BOOLEAN NOT NULL DEFAULT TRUE,
    allows_vote_reasons BOOLEAN NOT NULL DEFAULT TRUE,
    tags TEXT[] NOT NULL DEFAULT '{}',
    status TEXT NOT NULL DEFAULT 'active'
);

CREATE TABLE IF NOT EXISTS comparison_options (
    id UUID PRIMARY KEY,
    comparison_id UUID NOT NULL REFERENCES comparisons(id) ON DELETE CASCADE,
    title TEXT NOT NULL,
    sort_order INTEGER NOT NULL DEFAULT 0,
    UNIQUE (comparison_id, title)
);

CREATE TABLE IF NOT EXISTS votes (
    id UUID PRIMARY KEY,
    comparison_id UUID NOT NULL REFERENCES comparisons(id) ON DELETE CASCADE,
    option_id UUID NOT NULL REFERENCES comparison_options(id) ON DELETE CASCADE,
    user_id UUID REFERENCES users(id) ON DELETE SET NULL,
    client_id_hash TEXT,
    reason TEXT,
    reason_category TEXT,
    is_verified_experience BOOLEAN NOT NULL DEFAULT FALSE,
    is_anonymous BOOLEAN NOT NULL DEFAULT FALSE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    UNIQUE (comparison_id, user_id),
    UNIQUE (comparison_id, client_id_hash)
);

CREATE TABLE IF NOT EXISTS comments (
    id UUID PRIMARY KEY,
    comparison_id UUID NOT NULL REFERENCES comparisons(id) ON DELETE CASCADE,
    option_id UUID REFERENCES comparison_options(id) ON DELETE SET NULL,
    author_id UUID REFERENCES users(id) ON DELETE SET NULL,
    author_name TEXT NOT NULL DEFAULT 'مستخدم',
    text TEXT NOT NULL,
    likes INTEGER NOT NULL DEFAULT 0,
    trust_badge TEXT,
    reason_category TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS reports (
    id UUID PRIMARY KEY,
    content_id UUID NOT NULL,
    content_type TEXT NOT NULL,
    reason TEXT NOT NULL,
    details TEXT,
    reporter_id UUID REFERENCES users(id) ON DELETE SET NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    status TEXT NOT NULL DEFAULT 'open'
);

CREATE INDEX IF NOT EXISTS idx_comparisons_category_created ON comparisons(category, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_options_comparison ON comparison_options(comparison_id);
CREATE INDEX IF NOT EXISTS idx_votes_comparison ON votes(comparison_id);
CREATE INDEX IF NOT EXISTS idx_comments_comparison_created ON comments(comparison_id, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_reports_status_created ON reports(status, created_at DESC);
