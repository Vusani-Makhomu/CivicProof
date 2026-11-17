-- CivicProof foundational schema. Demo seed data stays separate from live application records.
create extension if not exists pgcrypto;

create type public.app_role as enum ('COMMUNITY_MEMBER','GOVERNMENT_REVIEWER','DEPARTMENT_OFFICIAL','INVESTIGATOR','AUDITOR','ADMIN');
create type public.submission_type as enum ('COMMUNITY_NEED','SERVICE_OBSERVATION');
create type public.project_status as enum ('PLANNED','IN_PROGRESS','COMPLETED','SUSPENDED','CANCELLED');
create type public.investigation_type as enum ('COMMUNITY_NEED','PROJECT_ACCOUNTABILITY');
create type public.match_status as enum ('SUGGESTED','CONFIRMED','REJECTED','MORE_INFORMATION_REQUIRED','REFERRED');

create table public.departments (
  id uuid primary key default gen_random_uuid(),
  name text not null unique,
  description text,
  created_at timestamptz not null default now()
);

create table public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  display_name text not null default '',
  role public.app_role not null default 'COMMUNITY_MEMBER',
  department_id uuid references public.departments(id),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table public.community_submissions (
  id uuid primary key default gen_random_uuid(),
  submitter_id uuid not null references auth.users(id),
  submission_type public.submission_type not null,
  title text not null check (length(trim(title)) between 3 and 160),
  description text not null check (length(trim(description)) between 10 and 10000),
  category text not null,
  reported_location_name text not null,
  suburb text not null,
  ward text,
  latitude double precision check (latitude between -90 and 90),
  longitude double precision check (longitude between -180 and 180),
  status text not null default 'REGISTERED',
  visibility text not null default 'PRIVATE' check (visibility in ('PRIVATE','PUBLIC_STATUS')),
  is_synthetic boolean not null default false,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table public.community_needs (
  id uuid primary key default gen_random_uuid(),
  title text not null,
  description text not null,
  category text not null,
  location_name text not null,
  suburb text not null,
  ward text,
  latitude double precision check (latitude between -90 and 90),
  longitude double precision check (longitude between -180 and 180),
  status text not null default 'REGISTERED',
  assigned_department_id uuid references public.departments(id),
  assigned_to uuid references public.profiles(id),
  response_due_at timestamptz,
  is_synthetic boolean not null default false,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table public.community_need_submissions (
  community_need_id uuid not null references public.community_needs(id),
  submission_id uuid not null references public.community_submissions(id),
  association_reason text not null,
  created_at timestamptz not null default now(),
  primary key (community_need_id, submission_id)
);

create table public.government_projects (
  id uuid primary key default gen_random_uuid(),
  external_reference text,
  name text not null,
  description text not null default '',
  category text not null,
  status public.project_status not null,
  department_id uuid references public.departments(id),
  location_name text not null,
  suburb text not null,
  ward text,
  latitude double precision check (latitude between -90 and 90),
  longitude double precision check (longitude between -180 and 180),
  planned_start_date date,
  planned_end_date date,
  actual_start_date date,
  actual_completion_date date,
  budget_amount numeric(16,2),
  contract_amount numeric(16,2),
  currency text not null default 'ZAR',
  scope_description text not null default '',
  progress_percentage numeric(5,2) check (progress_percentage between 0 and 100),
  contractor_name text,
  source_name text not null,
  source_reference text,
  source_updated_at timestamptz,
  is_synthetic boolean not null default false,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table public.project_milestones (
  id uuid primary key default gen_random_uuid(),
  project_id uuid not null references public.government_projects(id),
  name text not null,
  description text not null default '',
  deliverable_quantity numeric(14,2),
  deliverable_unit text,
  planned_date date,
  actual_date date,
  status text not null default 'PLANNED',
  evidence_note text,
  is_synthetic boolean not null default false,
  created_at timestamptz not null default now()
);

create table public.project_payments (
  id uuid primary key default gen_random_uuid(),
  project_id uuid not null references public.government_projects(id),
  description text not null,
  amount numeric(16,2) not null check (amount >= 0),
  payment_date date,
  payment_status text not null,
  milestone_id uuid references public.project_milestones(id),
  source_name text not null,
  source_reference text,
  is_synthetic boolean not null default false,
  created_at timestamptz not null default now()
);

create table public.potential_project_matches (
  id uuid primary key default gen_random_uuid(),
  submission_id uuid not null references public.community_submissions(id),
  community_need_id uuid references public.community_needs(id),
  project_id uuid not null references public.government_projects(id),
  match_score numeric(5,4) check (match_score between 0 and 1),
  match_label text check (match_label in ('HIGH','POSSIBLE','WEAK')),
  match_reasons jsonb not null default '[]'::jsonb,
  source_snapshot jsonb not null default '{}'::jsonb,
  status public.match_status not null default 'SUGGESTED',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (submission_id, project_id)
);

create table public.match_reviews (
  id uuid primary key default gen_random_uuid(),
  potential_match_id uuid not null references public.potential_project_matches(id),
  reviewer_id uuid not null references public.profiles(id),
  decision public.match_status not null check (decision <> 'SUGGESTED'),
  reason text not null check (length(trim(reason)) > 0),
  created_at timestamptz not null default now()
);

create table public.investigations (
  id uuid primary key default gen_random_uuid(),
  investigation_type public.investigation_type not null,
  community_need_id uuid references public.community_needs(id),
  submission_id uuid references public.community_submissions(id),
  project_id uuid references public.government_projects(id),
  status text not null default 'OPEN',
  assigned_department_id uuid references public.departments(id),
  assigned_to uuid references public.profiles(id),
  opened_at timestamptz not null default now(),
  due_at timestamptz,
  closed_at timestamptz,
  closure_reason text,
  is_synthetic boolean not null default false,
  check ((investigation_type = 'COMMUNITY_NEED' and (community_need_id is not null or submission_id is not null)) or (investigation_type = 'PROJECT_ACCOUNTABILITY' and project_id is not null))
);

create table public.department_responses (
  id uuid primary key default gen_random_uuid(),
  community_need_id uuid references public.community_needs(id),
  investigation_id uuid references public.investigations(id),
  department_id uuid not null references public.departments(id),
  official_id uuid not null references public.profiles(id),
  response_type text not null,
  response_text text not null,
  reason text,
  created_at timestamptz not null default now(),
  check (community_need_id is not null or investigation_id is not null)
);

create table public.investigation_findings (
  id uuid primary key default gen_random_uuid(),
  investigation_id uuid not null references public.investigations(id),
  finding_type text not null,
  description text not null,
  evidence_classification text not null check (evidence_classification in ('COMMUNITY_REPORTED','SYSTEM_IDENTIFIED','OFFICIALLY_RECORDED','HUMAN_REVIEWED','INDEPENDENTLY_VERIFIED','OFFICIALLY_CONFIRMED')),
  source_references jsonb not null default '[]'::jsonb,
  created_by uuid not null references public.profiles(id),
  created_at timestamptz not null default now()
);

create table public.corrective_actions (
  id uuid primary key default gen_random_uuid(),
  investigation_id uuid not null references public.investigations(id),
  title text not null,
  description text not null,
  owner_id uuid references public.profiles(id),
  due_at timestamptz,
  status text not null default 'OPEN',
  completion_evidence text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table public.submission_evidence (
  id uuid primary key default gen_random_uuid(),
  submission_id uuid not null references public.community_submissions(id),
  storage_path text not null,
  file_name text not null,
  mime_type text not null,
  size_bytes bigint not null check (size_bytes between 1 and 20971520),
  evidence_type text not null,
  captured_at timestamptz,
  reported_latitude double precision,
  reported_longitude double precision,
  metadata_status text not null default 'UNVERIFIED',
  uploaded_by uuid not null references public.profiles(id),
  created_at timestamptz not null default now()
);

create table public.audit_events (
  id uuid primary key default gen_random_uuid(),
  actor_id uuid references public.profiles(id),
  entity_type text not null,
  entity_id uuid not null,
  action text not null,
  before_state jsonb,
  after_state jsonb,
  reason text,
  created_at timestamptz not null default now()
);

create index community_submissions_owner_idx on public.community_submissions(submitter_id, created_at desc);
create index community_submissions_category_idx on public.community_submissions(category, created_at desc);
create index community_needs_department_idx on public.community_needs(assigned_department_id, status);
create index projects_status_category_idx on public.government_projects(status, category);
create index projects_location_idx on public.government_projects(suburb, category);
create index matches_status_idx on public.potential_project_matches(status, created_at desc);
create index investigations_assignee_idx on public.investigations(assigned_to, status);
create index audit_entity_idx on public.audit_events(entity_type, entity_id, created_at desc);

create or replace function public.current_app_role()
returns public.app_role language sql stable security definer set search_path = ''
as $$ select role from public.profiles where id = (select auth.uid()) $$;

create or replace function public.handle_new_user()
returns trigger language plpgsql security definer set search_path = ''
as $$
begin
  insert into public.profiles (id, display_name, role)
  values (new.id, coalesce(new.raw_user_meta_data ->> 'display_name', ''), 'COMMUNITY_MEMBER');
  return new;
end;
$$;
create trigger on_auth_user_created after insert on auth.users
for each row execute procedure public.handle_new_user();

create or replace function public.prevent_profile_privilege_escalation()
returns trigger language plpgsql security definer set search_path = ''
as $$
begin
  if auth.uid() = old.id and (new.role is distinct from old.role or new.department_id is distinct from old.department_id) then
    raise exception 'Users cannot change their own role or department';
  end if;
  return new;
end;
$$;
create trigger prevent_profile_privilege_escalation before update on public.profiles
for each row execute procedure public.prevent_profile_privilege_escalation();

alter table public.departments enable row level security;
alter table public.profiles enable row level security;
alter table public.community_submissions enable row level security;
alter table public.community_needs enable row level security;
alter table public.community_need_submissions enable row level security;
alter table public.government_projects enable row level security;
alter table public.project_milestones enable row level security;
alter table public.project_payments enable row level security;
alter table public.potential_project_matches enable row level security;
alter table public.match_reviews enable row level security;
alter table public.investigations enable row level security;
alter table public.department_responses enable row level security;
alter table public.investigation_findings enable row level security;
alter table public.corrective_actions enable row level security;
alter table public.submission_evidence enable row level security;
alter table public.audit_events enable row level security;

create policy "authenticated users read departments" on public.departments for select to authenticated using (true);
create policy "users read own profile and auditors read profiles" on public.profiles for select to authenticated using (id = (select auth.uid()) or public.current_app_role() in ('ADMIN','AUDITOR'));
create policy "users update own display name" on public.profiles for update to authenticated using (id = (select auth.uid())) with check (id = (select auth.uid()));
create policy "community creates own submissions" on public.community_submissions for insert to authenticated with check (submitter_id = (select auth.uid()));
create policy "users read own submissions; staff read scoped records" on public.community_submissions for select to authenticated using (
  submitter_id = (select auth.uid()) or public.current_app_role() in ('ADMIN','AUDITOR','INVESTIGATOR','GOVERNMENT_REVIEWER') or
  (public.current_app_role() = 'DEPARTMENT_OFFICIAL' and exists (select 1 from public.community_needs n join public.community_need_submissions x on x.community_need_id=n.id where x.submission_id=community_submissions.id and n.assigned_department_id=(select department_id from public.profiles where id=(select auth.uid()))))
);
create policy "projects read by authenticated users" on public.government_projects for select to authenticated using (true);
create policy "milestones read by authenticated users" on public.project_milestones for select to authenticated using (true);
create policy "payments staff only" on public.project_payments for select to authenticated using (public.current_app_role() in ('ADMIN','AUDITOR','INVESTIGATOR','GOVERNMENT_REVIEWER'));
create policy "needs visible to linked submitters and authorised staff" on public.community_needs for select to authenticated using (
  public.current_app_role() in ('ADMIN','AUDITOR','INVESTIGATOR','GOVERNMENT_REVIEWER') or
  (public.current_app_role() = 'DEPARTMENT_OFFICIAL' and assigned_department_id=(select department_id from public.profiles where id=(select auth.uid()))) or
  exists (select 1 from public.community_need_submissions x join public.community_submissions s on s.id=x.submission_id where x.community_need_id=community_needs.id and s.submitter_id=(select auth.uid()))
);
create policy "need associations readable to linked users and staff" on public.community_need_submissions for select to authenticated using (
  public.current_app_role() in ('ADMIN','AUDITOR','INVESTIGATOR','GOVERNMENT_REVIEWER','DEPARTMENT_OFFICIAL') or
  exists (select 1 from public.community_submissions s where s.id=submission_id and s.submitter_id=(select auth.uid()))
);
create policy "matches staff only" on public.potential_project_matches for select to authenticated using (public.current_app_role() in ('ADMIN','AUDITOR','INVESTIGATOR','GOVERNMENT_REVIEWER','DEPARTMENT_OFFICIAL'));
create policy "reviews staff only" on public.match_reviews for select to authenticated using (public.current_app_role() in ('ADMIN','AUDITOR','INVESTIGATOR','GOVERNMENT_REVIEWER'));
create policy "investigations staff only" on public.investigations for select to authenticated using (public.current_app_role() in ('ADMIN','AUDITOR','INVESTIGATOR','GOVERNMENT_REVIEWER') or (public.current_app_role()='DEPARTMENT_OFFICIAL' and assigned_department_id=(select department_id from public.profiles where id=(select auth.uid()))));
create policy "responses visible to authorised parties" on public.department_responses for select to authenticated using (
  official_id=(select auth.uid()) or public.current_app_role() in ('ADMIN','AUDITOR','INVESTIGATOR','GOVERNMENT_REVIEWER') or
  (public.current_app_role()='DEPARTMENT_OFFICIAL' and department_id=(select department_id from public.profiles where id=(select auth.uid()))) or
  exists (select 1 from public.community_need_submissions x join public.community_submissions s on s.id=x.submission_id where x.community_need_id=department_responses.community_need_id and s.submitter_id=(select auth.uid()))
);
create policy "findings staff only" on public.investigation_findings for select to authenticated using (public.current_app_role() in ('ADMIN','AUDITOR','INVESTIGATOR','GOVERNMENT_REVIEWER'));
create policy "actions staff only" on public.corrective_actions for select to authenticated using (public.current_app_role() in ('ADMIN','AUDITOR','INVESTIGATOR','GOVERNMENT_REVIEWER','DEPARTMENT_OFFICIAL'));
create policy "evidence visible to submitter and authorised staff" on public.submission_evidence for select to authenticated using (
  uploaded_by=(select auth.uid()) or public.current_app_role() in ('ADMIN','AUDITOR','INVESTIGATOR','GOVERNMENT_REVIEWER') or
  exists (select 1 from public.community_submissions s where s.id=submission_id and s.submitter_id=(select auth.uid()))
);
create policy "audit read by oversight roles" on public.audit_events for select to authenticated using (public.current_app_role() in ('ADMIN','AUDITOR'));

-- Writes other than community submission creation are intentionally not granted by these baseline policies.
-- Add audited, role-scoped RPCs for match review, official response, and investigation transitions before enabling those UI operations.
