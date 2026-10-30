# Skillnest
React + Vite online learning platform.

## Frontend
`npm install` then `npm run dev`.

## Supabase backend setup
1. Create a Supabase project.
2. In Supabase SQL Editor, run all SQL in `supabase/schema.sql`.
3. Copy `.env.example` to `.env.local` and set your project URL and anon/publishable key.
4. In Supabase Authentication settings, configure your site URL and allowed redirect URLs.
5. Create your account through the site. To grant admin access, run the final commented SQL statement in the SQL editor with your admin email.

Included: email/password signup and login, student enrollment dashboard, free-course enrollment, course completion status, admin course publishing and enrollment overview. Row Level Security protects student data.

## Payments
Paid-course checkout is intentionally not enabled until the owner selects a payment provider and supplies merchant credentials. Never put secret keys in frontend environment variables.

## Production
Set environment variables in your hosting provider. Enable email confirmation and configure SMTP before launch.