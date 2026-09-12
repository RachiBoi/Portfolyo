# Student Portfolio Tracker

A dashboard for CBSE/ICSE/State Board secondary school students that tracks academic performance, extracurricular activities, community service hours, leadership roles, mock-interview readiness, and college application deadlines, and rolls them into a single holistic score.

Currently a static, single-user HTML demo (`demo_dashboard_v4.html`, sample profile "Arjun Sharma"). No backend is wired up — `schema.sql` lays out the planned database structure.

## Files

| File | Purpose |
|---|---|
| `demo_dashboard_v4.html` | Main dashboard — six tabs: Overview, Academic, Extracurricular, Service, Interview Prep, Timeline |
| `login.html` | Sign-in / register screen, stores the session in `localStorage` |
| `404.html` | Not-found page |
| `tutorial.js` | First-visit onboarding walkthrough, 10 steps |
| `schema.sql` | PostgreSQL schema for the planned backend (users, profiles, academics, activities, service hours, leadership, interviews, deadlines, consents, holistic scores) |

## Holistic score

```
Total = (Academic × 0.35) + (Extracurricular × 0.25) +
        (Service × 0.15) + (Leadership × 0.15) + (Diversity × 0.10)
```

| Band | Range | Color |
|---|---|---|
| Exceptional | 85-100 | Green `#00e676` |
| Strong Profile | 70-84 | Peach `#ffe8db` |
| Good Foundation | 55-69 | Blue `#739ec9` |
| Developing | 0-54 | Red `#ff5252` |

Interview readiness: `(mock_interviews × 20) + (questions_practiced / 10) + confidence_score + mentor_feedback`, capped at 100.

Privacy rules baked into the scoring: topics below 40% flag as weak areas, peer benchmarking needs a cohort of at least 5 students, service hours cap at 40 per organization, and only 2 leadership roles count toward the score.

## Running the demo

No build step. Open `login.html` (or `demo_dashboard_v4.html` directly) in a browser, or serve the folder with any static file server:

```bash
python3 -m http.server 8000
```

Demo credentials on the login screen: `arjun.sharma@school.edu`.

## Current limitations

- Single hardcoded user, no real authentication.
- No database wired up — all data is static and resets on reload.
- No file upload for certificates.
- Not mobile-responsive.
- Activities show as "verified" with no actual review workflow.

## Planned stack (full-stack version)

- Frontend: React, Vite, Tailwind CSS
- Backend: Node.js, Express
- Database: PostgreSQL (schema in `schema.sql`)
- Auth: JWT + bcrypt
- File storage: AWS S3 or Cloudinary
- Deployment: Vercel (frontend), Railway or Supabase (backend/DB)
