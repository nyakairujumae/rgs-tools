# RGS Tools – Web

Next.js web app for RGS Tools: dashboard, tool inventory, assignments, shared tools, technicians, and reports.

## Setup

```bash
npm install
cp .env.example .env
# Edit .env with your Supabase URL and anon key
npm run dev
```

## Deploy

- **Vercel**: Connect this repo; deploy workflow is in `.github/workflows/deploy-web.yml` if using GitHub Actions.
- Ensure Supabase env vars are set in your hosting provider.
