-- ============================================================
-- NEXUS PLATFORM — Supabase SQL Schema
-- Run this in your Supabase SQL Editor to set up the database
-- ============================================================

-- Enable required extensions
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- ────────────────────────────────────────────────────────────
-- PROFILES TABLE
-- Extends Supabase auth.users with additional user data
-- ────────────────────────────────────────────────────────────
CREATE TABLE public.profiles (
  id          UUID REFERENCES auth.users(id) ON DELETE CASCADE PRIMARY KEY,
  created_at  TIMESTAMPTZ DEFAULT NOW() NOT NULL,
  updated_at  TIMESTAMPTZ DEFAULT NOW() NOT NULL,
  email       TEXT NOT NULL,
  full_name   TEXT,
  avatar_url  TEXT,
  username    TEXT UNIQUE,
  bio         TEXT,
  role        TEXT DEFAULT 'user' CHECK (role IN ('user', 'admin', 'pro')),
  plan        TEXT DEFAULT 'free' CHECK (plan IN ('free', 'pro', 'enterprise')),
  onboarded   BOOLEAN DEFAULT FALSE
);

-- ────────────────────────────────────────────────────────────
-- PROJECTS TABLE
-- ────────────────────────────────────────────────────────────
CREATE TABLE public.projects (
  id          UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
  created_at  TIMESTAMPTZ DEFAULT NOW() NOT NULL,
  updated_at  TIMESTAMPTZ DEFAULT NOW() NOT NULL,
  user_id     UUID REFERENCES public.profiles(id) ON DELETE CASCADE NOT NULL,
  name        TEXT NOT NULL,
  description TEXT,
  status      TEXT DEFAULT 'active' CHECK (status IN ('active', 'paused', 'completed', 'archived')),
  progress    INTEGER DEFAULT 0 CHECK (progress BETWEEN 0 AND 100),
  color       TEXT DEFAULT '#5a63f3',
  due_date    DATE,
  tags        TEXT[] DEFAULT '{}'
);

-- ────────────────────────────────────────────────────────────
-- TASKS TABLE
-- ────────────────────────────────────────────────────────────
CREATE TABLE public.tasks (
  id           UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
  created_at   TIMESTAMPTZ DEFAULT NOW() NOT NULL,
  updated_at   TIMESTAMPTZ DEFAULT NOW() NOT NULL,
  project_id   UUID REFERENCES public.projects(id) ON DELETE CASCADE NOT NULL,
  user_id      UUID REFERENCES public.profiles(id) ON DELETE CASCADE NOT NULL,
  title        TEXT NOT NULL,
  description  TEXT,
  status       TEXT DEFAULT 'todo' CHECK (status IN ('todo', 'in_progress', 'review', 'done')),
  priority     TEXT DEFAULT 'medium' CHECK (priority IN ('low', 'medium', 'high', 'urgent')),
  due_date     DATE,
  assigned_to  UUID REFERENCES public.profiles(id),
  completed_at TIMESTAMPTZ
);

-- ────────────────────────────────────────────────────────────
-- ACTIVITY LOGS TABLE
-- ────────────────────────────────────────────────────────────
CREATE TABLE public.activity_logs (
  id          UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
  created_at  TIMESTAMPTZ DEFAULT NOW() NOT NULL,
  user_id     UUID REFERENCES public.profiles(id) ON DELETE CASCADE NOT NULL,
  action      TEXT NOT NULL,
  entity_type TEXT NOT NULL,
  entity_id   TEXT NOT NULL,
  metadata    JSONB DEFAULT '{}'
);

-- ────────────────────────────────────────────────────────────
-- NOTIFICATIONS TABLE
-- ────────────────────────────────────────────────────────────
CREATE TABLE public.notifications (
  id         UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
  created_at TIMESTAMPTZ DEFAULT NOW() NOT NULL,
  user_id    UUID REFERENCES public.profiles(id) ON DELETE CASCADE NOT NULL,
  title      TEXT NOT NULL,
  message    TEXT NOT NULL,
  type       TEXT DEFAULT 'info' CHECK (type IN ('info', 'success', 'warning', 'error')),
  read       BOOLEAN DEFAULT FALSE,
  link       TEXT
);

-- ────────────────────────────────────────────────────────────
-- ROW LEVEL SECURITY (RLS) POLICIES
-- ────────────────────────────────────────────────────────────

-- Enable RLS on all tables
ALTER TABLE public.profiles       ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.projects       ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.tasks          ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.activity_logs  ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.notifications  ENABLE ROW LEVEL SECURITY;

-- Profiles: users can only read/update their own profile
CREATE POLICY "Users can view own profile"
  ON public.profiles FOR SELECT USING (auth.uid() = id);

CREATE POLICY "Users can update own profile"
  ON public.profiles FOR UPDATE USING (auth.uid() = id);

CREATE POLICY "Users can insert own profile"
  ON public.profiles FOR INSERT WITH CHECK (auth.uid() = id);

-- Projects: full CRUD for own projects
CREATE POLICY "Users can CRUD own projects"
  ON public.projects FOR ALL USING (auth.uid() = user_id);

-- Tasks: full CRUD for own tasks
CREATE POLICY "Users can CRUD own tasks"
  ON public.tasks FOR ALL USING (auth.uid() = user_id);

-- Activity logs: users can only view/create their own
CREATE POLICY "Users can view own activity"
  ON public.activity_logs FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own activity"
  ON public.activity_logs FOR INSERT WITH CHECK (auth.uid() = user_id);

-- Notifications: users can view/update their own
CREATE POLICY "Users can view own notifications"
  ON public.notifications FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can update own notifications"
  ON public.notifications FOR UPDATE USING (auth.uid() = user_id);

-- ────────────────────────────────────────────────────────────
-- TRIGGERS
-- ────────────────────────────────────────────────────────────

-- Auto-update updated_at timestamp
CREATE OR REPLACE FUNCTION update_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER update_profiles_updated_at
  BEFORE UPDATE ON public.profiles
  FOR EACH ROW EXECUTE FUNCTION update_updated_at();

CREATE TRIGGER update_projects_updated_at
  BEFORE UPDATE ON public.projects
  FOR EACH ROW EXECUTE FUNCTION update_updated_at();

CREATE TRIGGER update_tasks_updated_at
  BEFORE UPDATE ON public.tasks
  FOR EACH ROW EXECUTE FUNCTION update_updated_at();

-- Auto-create profile when user signs up
CREATE OR REPLACE FUNCTION handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO public.profiles (id, email, full_name, avatar_url)
  VALUES (
    NEW.id,
    NEW.email,
    NEW.raw_user_meta_data->>'full_name',
    NEW.raw_user_meta_data->>'avatar_url'
  );
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION handle_new_user();

-- ────────────────────────────────────────────────────────────
-- SEED DATA (Demo projects for testing)
-- Only run after creating a user account
-- ────────────────────────────────────────────────────────────

-- Replace 'YOUR_USER_ID' with an actual user ID from auth.users
/*
INSERT INTO public.projects (user_id, name, description, status, progress, color, tags) VALUES
  ('YOUR_USER_ID', 'Website Redesign', 'Complete overhaul of company website', 'active', 65, '#5a63f3', ARRAY['design', 'frontend']),
  ('YOUR_USER_ID', 'API Integration', 'Connect third-party payment provider', 'active', 30, '#10b981', ARRAY['backend', 'api']),
  ('YOUR_USER_ID', 'Mobile App MVP', 'First release of the mobile application', 'paused', 85, '#f59e0b', ARRAY['mobile', 'react-native']),
  ('YOUR_USER_ID', 'Q4 Marketing', 'End of year marketing campaign', 'completed', 100, '#ef4444', ARRAY['marketing']);
*/
