# Nexus Platform

A production-ready full-stack web application built with Next.js 14, Supabase, and Tailwind CSS.

## Tech Stack

| Layer | Technology |
|-------|-----------|
| Frontend | Next.js 14 (App Router) |
| Styling | Tailwind CSS + Custom Design System |
| State | Zustand (client) + Server Components |
| Auth | Supabase Auth (email + OAuth) |
| Database | Supabase (PostgreSQL + RLS) |
| Real-time | Supabase Realtime subscriptions |
| Forms | React Hook Form + Zod |
| Charts | Recharts |
| Toasts | React Hot Toast |
| Deployment | Vercel |
| Version Control | GitHub |

## Architecture

```
nexus/
├── src/
│   ├── app/                     # Next.js App Router
│   │   ├── (auth)/              # Auth route group (login, register)
│   │   ├── (dashboard)/         # Protected route group
│   │   │   └── dashboard/       # Dashboard pages
│   │   ├── auth/callback/       # OAuth callback handler
│   │   ├── layout.tsx           # Root layout
│   │   ├── page.tsx             # Landing page
│   │   └── globals.css          # Design system CSS
│   ├── components/
│   │   └── dashboard/           # Dashboard UI components
│   ├── hooks/                   # Custom React hooks
│   │   ├── useAuth.ts           # Auth logic
│   │   └── useProjects.ts       # Projects CRUD + realtime
│   ├── lib/
│   │   └── supabase/            # Supabase clients + types
│   ├── middleware.ts             # Route protection
│   └── store/                   # Zustand state stores
├── supabase-schema.sql          # Database schema + RLS
├── vercel.json                  # Deployment config
└── .env.example                 # Environment template
```

## Quick Start

### 1. Clone & install
```bash
git clone https://github.com/YOUR_USERNAME/nexus-platform
cd nexus-platform
npm install
```

### 2. Set up Supabase
1. Create a project at [supabase.com](https://supabase.com)
2. Run `supabase-schema.sql` in the SQL Editor
3. Enable Google & GitHub OAuth providers in **Auth → Providers**
4. Set callback URL: `https://your-app.vercel.app/auth/callback`

### 3. Configure environment
```bash
cp .env.example .env.local
```
Fill in:
```env
NEXT_PUBLIC_SUPABASE_URL=https://your-project.supabase.co
NEXT_PUBLIC_SUPABASE_ANON_KEY=your-anon-key
NEXT_PUBLIC_APP_URL=http://localhost:3000
```

### 4. Run locally
```bash
npm run dev
# Open http://localhost:3000
```

## Deploy to Vercel

### One-click deploy
[![Deploy with Vercel](https://vercel.com/button)](https://vercel.com/new/clone?repository-url=https://github.com/YOUR_USERNAME/nexus-platform)

### Manual deploy
```bash
# Install Vercel CLI
npm i -g vercel

# Deploy
vercel

# Set environment variables
vercel env add NEXT_PUBLIC_SUPABASE_URL
vercel env add NEXT_PUBLIC_SUPABASE_ANON_KEY
```

## GitHub Setup
```bash
git init
git add .
git commit -m "Initial commit: Nexus Platform"
git remote add origin https://github.com/YOUR_USERNAME/nexus-platform.git
git branch -M main
git push -u origin main
```

## Features

### Authentication
- Email/password with validation
- OAuth (Google + GitHub)
- Password reset via email
- Protected routes via middleware
- Session auto-refresh

### Dashboard
- Real-time project and task updates (Supabase subscriptions)
- Interactive analytics charts (Recharts)
- Notification center with real-time push
- Responsive sidebar with collapse
- Dark mode support

### Projects
- Full CRUD with optimistic updates
- Color-coded project cards
- Status management (Active/Paused/Completed/Archived)
- Progress tracking
- Tags and due dates
- Grid and list views
- Search and filter

### Settings
- Profile editing with avatar
- Notification preferences
- Password change
- Billing overview
- Account deletion

### Security
- Row Level Security (RLS) on all tables
- Middleware-based route protection
- Input validation (Zod schemas)
- Security headers via vercel.json
- No sensitive data in client state

## Database Schema

| Table | Description |
|-------|-------------|
| `profiles` | Extended user data (linked to auth.users) |
| `projects` | User projects with status and progress |
| `tasks` | Tasks linked to projects |
| `activity_logs` | Audit trail of user actions |
| `notifications` | In-app notification system |

All tables have Row Level Security enabled — users can only access their own data.

## Design System

- **Font**: Bricolage Grotesque (display) + Plus Jakarta Sans (body)
- **Color**: Brand blue (#5a63f3) with surface scale
- **Components**: `.btn`, `.input`, `.card`, `.badge`, `.skeleton`, `.glass`
- **Animations**: CSS keyframes with staggered delays
- **Dark mode**: CSS custom properties that invert on `[data-theme="dark"]`

## Extending

### Add a new page
1. Create `src/app/(dashboard)/dashboard/YOUR_PAGE/page.tsx`
2. Add to `navigation` array in `DashboardShell.tsx`

### Add a new table
1. Add SQL to `supabase-schema.sql`
2. Add type to `src/lib/supabase/types.ts`
3. Create hook in `src/hooks/`
4. Add to Zustand store

### Add real-time to a hook
```ts
supabase.channel('my-channel')
  .on('postgres_changes', {
    event: '*',
    schema: 'public',
    table: 'my_table',
    filter: `user_id=eq.${user.id}`,
  }, handleChange)
  .subscribe()
```

## License
MIT
