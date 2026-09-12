-- ============================================================================
-- STUDENT PORTFOLIO TRACKER - COMPLETE SQL SCHEMA
-- Target DB: PostgreSQL 14+ (Compatible with Supabase, Neon, AWS RDS)
-- Features: Auth, Profiles, Academics, Extracurriculars, Service Hours,
--           Leadership, Interview Prep, Deadlines, Consents & Holistic Scoring
-- ============================================================================

-- Enable UUID extension
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- ============================================================================
-- 1. ENUMS & DOMAIN TYPES
-- ============================================================================
CREATE TYPE user_role AS ENUM ('student', 'teacher', 'counselor', 'parent', 'admin');
CREATE TYPE edu_board AS ENUM ('CBSE', 'ICSE', 'State', 'IB', 'Cambridge');
CREATE TYPE verify_status AS ENUM ('pending', 'verified', 'rejected');
CREATE TYPE activity_cat AS ENUM ('sports', 'arts', 'ncc', 'nss', 'club', 'stem', 'other');
CREATE TYPE activity_level AS ENUM ('school', 'district', 'state', 'national', 'international');
CREATE TYPE leadership_type AS ENUM ('school_captain', 'house_captain', 'club_president', 'event_organizer', 'prefect', 'other');
CREATE TYPE deadline_status AS ENUM ('not_started', 'in_progress', 'submitted');

-- ============================================================================
-- 2. USERS & AUTHENTICATION TABLE (Maps from login.html)
-- ============================================================================
CREATE TABLE users (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    email VARCHAR(255) UNIQUE NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    role user_role NOT NULL DEFAULT 'student',
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    last_login_at TIMESTAMPTZ
);

CREATE INDEX idx_users_email ON users(email);

-- ============================================================================
-- 3. STUDENT PROFILES TABLE (Maps header, pills, grade, board, target)
-- ============================================================================
CREATE TABLE student_profiles (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID UNIQUE NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    full_name VARCHAR(150) NOT NULL,
    board edu_board NOT NULL DEFAULT 'CBSE',
    grade SMALLINT NOT NULL CHECK (grade BETWEEN 8 AND 12),
    school_name VARCHAR(255) NOT NULL,
    school_city VARCHAR(100),
    school_state VARCHAR(100),
    target_institution VARCHAR(200) DEFAULT 'IIT Delhi',
    theme_preference VARCHAR(10) DEFAULT 'dark' CHECK (theme_preference IN ('dark', 'light')),
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_student_profiles_cohort ON student_profiles(school_name, board, grade);


-- ============================================================================
-- 4. ACADEMIC RECORDS & WEAK TOPICS (Maps Academic Tab)
-- ============================================================================
CREATE TABLE academic_records (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    student_id UUID NOT NULL REFERENCES student_profiles(id) ON DELETE CASCADE,
    subject_name VARCHAR(100) NOT NULL,
    score_obtained NUMERIC(5,2) NOT NULL CHECK (score_obtained >= 0),
    max_score NUMERIC(5,2) DEFAULT 100.00,
    percentage NUMERIC(5,2) GENERATED ALWAYS AS ((score_obtained / max_score) * 100) STORED,
    exam_type VARCHAR(50) DEFAULT 'Term Final',
    exam_date DATE NOT NULL,
    cbse_grade VARCHAR(5) DEFAULT 'A1',
    weak_topics JSONB DEFAULT '[]'::jsonb,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_academic_student ON academic_records(student_id);

-- ============================================================================
-- 5. EXTRACURRICULAR ACTIVITIES (Maps Extracurricular Tab & Timeline)
-- ============================================================================
CREATE TABLE extracurricular_activities (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    student_id UUID NOT NULL REFERENCES student_profiles(id) ON DELETE CASCADE,
    title VARCHAR(255) NOT NULL,
    category activity_cat NOT NULL,
    level activity_level NOT NULL DEFAULT 'school',
    icon_emoji VARCHAR(10) DEFAULT '🏆',
    start_date DATE NOT NULL,
    end_date DATE,
    points_awarded INTEGER DEFAULT 0 CHECK (points_awarded BETWEEN 0 AND 100),
    verification_status verify_status DEFAULT 'pending',
    verified_by UUID REFERENCES users(id) ON DELETE SET NULL,
    verified_at TIMESTAMPTZ,
    certificate_url TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_activities_student ON extracurricular_activities(student_id);
CREATE INDEX idx_activities_status ON extracurricular_activities(verification_status);

-- ============================================================================
-- 6. COMMUNITY SERVICE HOURS (Maps Service Tab)
-- ============================================================================
CREATE TABLE community_service_hours (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    student_id UUID NOT NULL REFERENCES student_profiles(id) ON DELETE CASCADE,
    organization_name VARCHAR(255) NOT NULL,
    activity_description TEXT NOT NULL,
    hours NUMERIC(5,2) NOT NULL CHECK (hours > 0),
    service_date DATE NOT NULL,
    verification_status verify_status DEFAULT 'pending',
    verified_by UUID REFERENCES users(id) ON DELETE SET NULL,
    verified_at TIMESTAMPTZ,
    certificate_url TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW()
);


-- ============================================================================
-- 7. LEADERSHIP ROLES (Maps Leadership Section)
-- ============================================================================
CREATE TABLE leadership_roles (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    student_id UUID NOT NULL REFERENCES student_profiles(id) ON DELETE CASCADE,
    role_title VARCHAR(150) NOT NULL,
    role_type leadership_type NOT NULL,
    start_date DATE NOT NULL,
    end_date DATE,
    points INTEGER NOT NULL DEFAULT 100,
    verification_status verify_status DEFAULT 'pending',
    verified_by UUID REFERENCES users(id) ON DELETE SET NULL,
    recommendation_letter_url TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_leadership_student ON leadership_roles(student_id);

-- ============================================================================
-- 8. INTERVIEW PREPARATION SESSIONS (Maps Interview Readiness Tab)
-- ============================================================================
CREATE TABLE interview_sessions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    student_id UUID NOT NULL REFERENCES student_profiles(id) ON DELETE CASCADE,
    session_date DATE NOT NULL,
    interviewer_name VARCHAR(150),
    questions_practiced INTEGER DEFAULT 15,
    confidence_score SMALLINT CHECK (confidence_score BETWEEN 1 AND 10),
    mentor_feedback_score SMALLINT CHECK (mentor_feedback_score BETWEEN 0 AND 20),
    notes TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_interview_student ON interview_sessions(student_id);

-- ============================================================================
-- 9. APPLICATION DEADLINES & CALENDAR (Maps Deadlines & .ics Sync)
-- ============================================================================
CREATE TABLE application_deadlines (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    student_id UUID NOT NULL REFERENCES student_profiles(id) ON DELETE CASCADE,
    title VARCHAR(200) NOT NULL,
    description TEXT,
    deadline_date DATE NOT NULL,
    status deadline_status DEFAULT 'not_started',
    is_synced_to_calendar BOOLEAN DEFAULT FALSE,
    reminder_days_before INTEGER[] DEFAULT '{7, 3, 1}',
    created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_deadlines_student ON application_deadlines(student_id, deadline_date);

-- ============================================================================
-- 10. DPDP CONSENTS & PRIVACY (India DPDP Act Compliance)
-- ============================================================================
CREATE TABLE data_consents (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    consent_purpose VARCHAR(100) NOT NULL,
    is_granted BOOLEAN NOT NULL DEFAULT TRUE,
    granted_at TIMESTAMPTZ DEFAULT NOW(),
    revoked_at TIMESTAMPTZ,
    ip_address INET
);


-- ============================================================================
-- 11. HOLISTIC SCORE MATERIALIZED / COMPUTED VIEW
-- Implements the formula:
-- Total = (Academic*0.35) + (Extra*0.25) + (Service*0.15) + (Leadership*0.15) + (Diversity*0.10)
-- ============================================================================
CREATE TABLE holistic_scores (
    student_id UUID PRIMARY KEY REFERENCES student_profiles(id) ON DELETE CASCADE,
    academic_score NUMERIC(5,2) DEFAULT 0,
    extracurricular_score NUMERIC(5,2) DEFAULT 0,
    service_score NUMERIC(5,2) DEFAULT 0,
    leadership_score NUMERIC(5,2) DEFAULT 0,
    diversity_score NUMERIC(5,2) DEFAULT 0,
    total_score NUMERIC(5,2) GENERATED ALWAYS AS (
        (academic_score * 0.35) +
        (extracurricular_score * 0.25) +
        (service_score * 0.15) +
        (leadership_score * 0.15) +
        (diversity_score * 0.10)
    ) STORED,
    score_band VARCHAR(30) GENERATED ALWAYS AS (
        CASE
            WHEN (academic_score * 0.35 + extracurricular_score * 0.25 + service_score * 0.15 + leadership_score * 0.15 + diversity_score * 0.10) >= 85 THEN 'EXCEPTIONAL'
            WHEN (academic_score * 0.35 + extracurricular_score * 0.25 + service_score * 0.15 + leadership_score * 0.15 + diversity_score * 0.10) >= 70 THEN 'STRONG PROFILE'
            WHEN (academic_score * 0.35 + extracurricular_score * 0.25 + service_score * 0.15 + leadership_score * 0.15 + diversity_score * 0.10) >= 55 THEN 'GOOD FOUNDATION'
            ELSE 'DEVELOPING'
        END
    ) STORED,
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- ============================================================================
-- 12. SEED DATA FOR DEMO USER (ARJUN SHARMA)
-- ============================================================================
INSERT INTO users (id, email, password_hash, role)
VALUES ('a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11', 'arjun.sharma@school.edu', '$2b$12$KIXxLZQ8x0UdlFZvM8aGJOzVHq8C9B1nN5HfKzWx2vW5Y3JZfZqKC', 'student')
ON CONFLICT (email) DO NOTHING;

INSERT INTO student_profiles (id, user_id, full_name, board, grade, school_name, school_city, target_institution)
VALUES (
    'b0eebc99-9c0b-4ef8-bb6d-6bb9bd380a22',
    'a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11',
    'Arjun Sharma',
    'CBSE',
    12,
    'Delhi Public School',
    'New Delhi',
    'IIT Delhi'
)
ON CONFLICT (user_id) DO NOTHING;

INSERT INTO holistic_scores (student_id, academic_score, extracurricular_score, service_score, leadership_score, diversity_score)
VALUES ('b0eebc99-9c0b-4ef8-bb6d-6bb9bd380a22', 87.5, 78.3, 62.0, 100.0, 68.0)
ON CONFLICT (student_id) DO UPDATE SET
    academic_score = EXCLUDED.academic_score,
    extracurricular_score = EXCLUDED.extracurricular_score,
    service_score = EXCLUDED.service_score,
    leadership_score = EXCLUDED.leadership_score,
    diversity_score = EXCLUDED.diversity_score;

-- ============================================================================
-- 13. USEFUL QUERIES & API ENDPOINTS MAPPING
-- ============================================================================

-- Query: Get student profile with holistic score
-- Endpoint: GET /api/students/{id}/profile
/*
SELECT 
    sp.full_name, sp.board, sp.grade, sp.school_name, sp.target_institution,
    hs.academic_score, hs.extracurricular_score, hs.service_score, 
    hs.leadership_score, hs.diversity_score, hs.total_score, hs.score_band
FROM student_profiles sp
LEFT JOIN holistic_scores hs ON sp.id = hs.student_id
WHERE sp.user_id = $1;
*/

-- Query: Get all verified extracurricular activities
-- Endpoint: GET /api/students/{id}/activities
/*
SELECT title, category, level, icon_emoji, start_date, end_date, points_awarded
FROM extracurricular_activities
WHERE student_id = $1 AND verification_status = 'verified'
ORDER BY start_date DESC;
*/

-- Query: Calculate peer benchmarking (min cohort of 5 for DPDP compliance)
-- Endpoint: GET /api/students/{id}/benchmark
/*
WITH cohort AS (
    SELECT sp.id, sp.full_name, hs.total_score
    FROM student_profiles sp
    JOIN holistic_scores hs ON sp.id = hs.student_id
    WHERE sp.school_name = (SELECT school_name FROM student_profiles WHERE id = $1)
      AND sp.board = (SELECT board FROM student_profiles WHERE id = $1)
      AND sp.grade = (SELECT grade FROM student_profiles WHERE id = $1)
)
SELECT 
    COUNT(*) as cohort_size,
    AVG(total_score) as avg_score,
    PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY total_score) as median_score
FROM cohort
HAVING COUNT(*) >= 5;
*/

-- Query: Get upcoming deadlines
-- Endpoint: GET /api/students/{id}/deadlines
/*
SELECT title, description, deadline_date, status, is_synced_to_calendar
FROM application_deadlines
WHERE student_id = $1 AND deadline_date >= CURRENT_DATE
ORDER BY deadline_date ASC
LIMIT 10;
*/

CREATE INDEX idx_service_student ON community_service_hours(student_id);
