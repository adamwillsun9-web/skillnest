-- Skillnest Supabase schema
create extension if not exists pgcrypto;
create table if not exists public.profiles (
 id uuid primary key references auth.users(id) on delete cascade,
 full_name text,
 role text not null default 'student' check (role in ('student','admin')),
 created_at timestamptz not null default now()
);
create table if not exists public.courses (
 id text primary key,
 title text not null,
 category text not null default 'General',
 description text,
 price numeric(10,2) not null default 0 check (price >= 0),
 published boolean not null default false,
 created_at timestamptz not null default now()
);
create table if not exists public.enrollments (
 id uuid primary key default gen_random_uuid(),
 user_id uuid not null references public.profiles(id) on delete cascade,
 course_id text not null references public.courses(id) on delete cascade,
 status text not null default 'active' check (status in ('active','completed')),
 progress_percent integer not null default 0 check (progress_percent between 0 and 100),
 created_at timestamptz not null default now(),
 unique(user_id,course_id)
);
create table if not exists public.lesson_progress (
 id uuid primary key default gen_random_uuid(),
 user_id uuid not null references public.profiles(id) on delete cascade,
 course_id text not null references public.courses(id) on delete cascade,
 lesson_key text not null,
 completed boolean not null default false,
 updated_at timestamptz not null default now(),
 unique(user_id,course_id,lesson_key)
);
create or replace function public.handle_new_user()
returns trigger language plpgsql security definer set search_path=public as $$
begin
 insert into public.profiles(id,full_name) values(new.id,coalesce(new.raw_user_meta_data->>'full_name',''));
 return new;
end; $$;
drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created after insert on auth.users for each row execute procedure public.handle_new_user();
create or replace function public.is_admin()
returns boolean language sql stable security definer set search_path=public as $$
 select exists(select 1 from public.profiles where id=auth.uid() and role='admin');
$$;
alter table public.profiles enable row level security;
alter table public.courses enable row level security;
alter table public.enrollments enable row level security;
alter table public.lesson_progress enable row level security;
drop policy if exists "profiles read self or admin" on public.profiles;
create policy "profiles read self or admin" on public.profiles for select using (id=auth.uid() or public.is_admin());
drop policy if exists "profiles update self" on public.profiles;
create policy "profiles update self" on public.profiles for update using (id=auth.uid()) with check (id=auth.uid());
drop policy if exists "published courses visible" on public.courses;
create policy "published courses visible" on public.courses for select using (published=true or public.is_admin());
drop policy if exists "admins manage courses" on public.courses;
create policy "admins manage courses" on public.courses for all using (public.is_admin()) with check (public.is_admin());
drop policy if exists "students read own enrollments" on public.enrollments;
create policy "students read own enrollments" on public.enrollments for select using (user_id=auth.uid() or public.is_admin());
drop policy if exists "students enroll themselves" on public.enrollments;
create policy "students enroll themselves" on public.enrollments for insert with check (user_id=auth.uid() and exists(select 1 from public.courses c where c.id=course_id and c.published=true and c.price=0));
drop policy if exists "students update own enrollments" on public.enrollments;
create policy "students update own enrollments" on public.enrollments for update using (user_id=auth.uid() or public.is_admin()) with check (user_id=auth.uid() or public.is_admin());
drop policy if exists "students manage own progress" on public.lesson_progress;
create policy "students manage own progress" on public.lesson_progress for all using (user_id=auth.uid() or public.is_admin()) with check (user_id=auth.uid() or public.is_admin());
insert into public.courses(id,title,category,description,price,published) values
('web-development-bootcamp','Complete Web Development Bootcamp','Development','Build modern websites from the ground up.',49,true),
('seo-content-growth','SEO & Content Growth Masterclass','Marketing','Learn search optimization and content strategy.',0,true),
('ui-ux-design','UI/UX Design: From Idea to Prototype','Design','Turn product ideas into clear user experiences.',39,true),
('python-programming','Python Programming for Everyone','Development','Learn Python fundamentals and practical coding.',59,true),
('social-media-marketing','Social Media Marketing Essentials','Marketing','Plan and grow social media campaigns.',0,true),
('graphic-design','Graphic Design with Adobe Tools','Design','Create polished graphics and visual assets.',45,true)
on conflict(id) do update set title=excluded.title,category=excluded.category,description=excluded.description,price=excluded.price,published=true;
-- Run this manually after signing up, replacing the email with your own admin email:
-- update public.profiles set role='admin' where id=(select id from auth.users where email='YOUR_ADMIN_EMAIL');