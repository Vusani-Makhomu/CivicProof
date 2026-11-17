-- Trusted workflow operations. These SECURITY DEFINER functions are the only
-- ordinary-user write path for review, responses, and investigations.

create or replace function public.submit_community_report(
  p_submission_type public.submission_type,
  p_title text,
  p_description text,
  p_category text,
  p_location_name text,
  p_suburb text,
  p_latitude double precision default null,
  p_longitude double precision default null,
  p_project_ids uuid[] default '{}'
) returns jsonb
language plpgsql security definer set search_path = ''
as $$
declare
  v_user uuid := (select auth.uid());
  v_submission uuid;
  v_need uuid;
  v_investigation uuid;
  v_project uuid;
  v_match_ids uuid[] := '{}';
begin
  if v_user is null then raise exception 'Authentication required'; end if;
  if length(trim(coalesce(p_title,''))) not between 3 and 160 then raise exception 'Title must be 3–160 characters'; end if;
  if length(trim(coalesce(p_description,''))) not between 10 and 10000 then raise exception 'Description must be 10–10000 characters'; end if;
  if length(trim(coalesce(p_category,''))) = 0 or length(trim(coalesce(p_location_name,''))) = 0 or length(trim(coalesce(p_suburb,''))) = 0 then
    raise exception 'Category and location are required';
  end if;
  if (p_latitude is null) <> (p_longitude is null) then raise exception 'Provide both coordinates or neither'; end if;
  if cardinality(coalesce(p_project_ids,'{}'::uuid[])) > 10 then raise exception 'Too many candidate projects'; end if;

  -- Persist the resident report first. Matching is a suggestion, never a gate.
  insert into public.community_submissions (submitter_id,submission_type,title,description,category,reported_location_name,suburb,latitude,longitude)
  values (v_user,p_submission_type,trim(p_title),trim(p_description),p_category,trim(p_location_name),trim(p_suburb),p_latitude,p_longitude)
  returning id into v_submission;

  if p_submission_type = 'COMMUNITY_NEED' then
    insert into public.community_needs (title,description,category,location_name,suburb,latitude,longitude)
    values (trim(p_title),trim(p_description),p_category,trim(p_location_name),trim(p_suburb),p_latitude,p_longitude)
    returning id into v_need;
    insert into public.community_need_submissions (community_need_id,submission_id,association_reason)
    values (v_need,v_submission,'Initial submission for this community need');
  end if;

  foreach v_project in array coalesce(p_project_ids,'{}'::uuid[]) loop
    if not exists (select 1 from public.government_projects where id=v_project) then raise exception 'Unknown project candidate'; end if;
    insert into public.potential_project_matches (submission_id,community_need_id,project_id,status,match_reasons)
    values (v_submission,v_need,v_project,'SUGGESTED','["Candidate supplied for human review"]'::jsonb)
    on conflict (submission_id,project_id) do nothing;
    v_match_ids := array_append(v_match_ids,v_project);
  end loop;

  if p_submission_type = 'COMMUNITY_NEED' and cardinality(v_match_ids)=0 then
    insert into public.investigations (investigation_type,community_need_id,submission_id,status)
    values ('COMMUNITY_NEED',v_need,v_submission,'OPEN') returning id into v_investigation;
  end if;

  insert into public.audit_events (actor_id,entity_type,entity_id,action,after_state)
  values (v_user,'community_submission',v_submission,'SUBMITTED',jsonb_build_object('type',p_submission_type,'community_need_id',v_need,'suggested_project_ids',v_match_ids));
  return jsonb_build_object('submission_id',v_submission,'community_need_id',v_need,'investigation_id',v_investigation,'suggested_project_ids',v_match_ids);
end;
$$;

create or replace function public.review_project_match(
  p_match_id uuid,
  p_decision public.match_status,
  p_reason text
) returns uuid
language plpgsql security definer set search_path = ''
as $$
declare
  v_user uuid := (select auth.uid());
  v_role public.app_role;
  v_match public.potential_project_matches%rowtype;
  v_investigation uuid;
begin
  select role into v_role from public.profiles where id=v_user;
  if v_role not in ('ADMIN','GOVERNMENT_REVIEWER') then raise exception 'Match reviewer role required'; end if;
  if p_decision not in ('CONFIRMED','REJECTED','MORE_INFORMATION_REQUIRED','REFERRED') then raise exception 'Invalid review decision'; end if;
  if p_decision='REJECTED' and length(trim(coalesce(p_reason,'')))=0 then raise exception 'Rejection reason required'; end if;
  if length(trim(coalesce(p_reason,'')))=0 then raise exception 'Review reason required'; end if;
  select * into v_match from public.potential_project_matches where id=p_match_id for update;
  if not found or v_match.status <> 'SUGGESTED' then raise exception 'Suggested match not found or already reviewed'; end if;

  update public.potential_project_matches set status=p_decision,updated_at=now() where id=p_match_id;
  insert into public.match_reviews (potential_match_id,reviewer_id,decision,reason) values (p_match_id,v_user,p_decision,trim(p_reason));
  insert into public.audit_events (actor_id,entity_type,entity_id,action,before_state,after_state,reason)
  values (v_user,'potential_project_match',p_match_id,'REVIEWED',jsonb_build_object('status',v_match.status),jsonb_build_object('status',p_decision),trim(p_reason));

  if p_decision='CONFIRMED' then
    insert into public.investigations (investigation_type,community_need_id,submission_id,project_id,status)
    values ('PROJECT_ACCOUNTABILITY',v_match.community_need_id,v_match.submission_id,v_match.project_id,'OPEN') returning id into v_investigation;
    insert into public.audit_events (actor_id,entity_type,entity_id,action,after_state,reason)
    values (v_user,'investigation',v_investigation,'OPENED_AFTER_CONFIRMED_MATCH',jsonb_build_object('project_id',v_match.project_id,'match_id',p_match_id),trim(p_reason));
  end if;
  return v_investigation;
end;
$$;

create or replace function public.record_department_response(
  p_community_need_id uuid,
  p_investigation_id uuid,
  p_department_id uuid,
  p_response_type text,
  p_response_text text,
  p_reason text default null
) returns uuid
language plpgsql security definer set search_path = ''
as $$
declare
  v_user uuid := (select auth.uid());
  v_role public.app_role;
  v_department uuid;
  v_response uuid;
begin
  select role,department_id into v_role,v_department from public.profiles where id=v_user;
  if v_role not in ('ADMIN','DEPARTMENT_OFFICIAL') then raise exception 'Department official role required'; end if;
  if v_role <> 'ADMIN' and v_department is distinct from p_department_id then raise exception 'Department scope mismatch'; end if;
  if p_community_need_id is null and p_investigation_id is null then raise exception 'Response must reference a need or investigation'; end if;
  if length(trim(coalesce(p_response_text,'')))=0 then raise exception 'Response text required'; end if;
  if p_community_need_id is not null and not exists (select 1 from public.community_needs where id=p_community_need_id and (assigned_department_id=p_department_id or assigned_department_id is null)) then raise exception 'Need is outside department scope'; end if;
  if p_investigation_id is not null and not exists (select 1 from public.investigations where id=p_investigation_id and (assigned_department_id=p_department_id or assigned_department_id is null)) then raise exception 'Investigation is outside department scope'; end if;

  insert into public.department_responses (community_need_id,investigation_id,department_id,official_id,response_type,response_text,reason)
  values (p_community_need_id,p_investigation_id,p_department_id, v_user,trim(p_response_type),trim(p_response_text),nullif(trim(coalesce(p_reason,'')),''))
  returning id into v_response;
  insert into public.audit_events (actor_id,entity_type,entity_id,action,after_state)
  values (v_user,'department_response',v_response,'RECORDED',jsonb_build_object('community_need_id',p_community_need_id,'investigation_id',p_investigation_id,'response_type',p_response_type));
  return v_response;
end;
$$;

revoke all on function public.submit_community_report(public.submission_type,text,text,text,text,text,double precision,double precision,uuid[]) from public;
revoke all on function public.review_project_match(uuid,public.match_status,text) from public;
revoke all on function public.record_department_response(uuid,uuid,uuid,text,text,text) from public;
grant execute on function public.submit_community_report(public.submission_type,text,text,text,text,text,double precision,double precision,uuid[]) to authenticated;
grant execute on function public.review_project_match(uuid,public.match_status,text) to authenticated;
grant execute on function public.record_department_response(uuid,uuid,uuid,text,text,text) to authenticated;

-- Private evidence files are scoped under {submitter auth uid}/{submission uuid}/.
insert into storage.buckets (id,name,public,file_size_limit,allowed_mime_types)
values ('submission-evidence','submission-evidence',false,20971520,array['image/jpeg','image/png','image/webp','video/mp4','video/quicktime'])
on conflict (id) do update set public=false,file_size_limit=20971520,allowed_mime_types=excluded.allowed_mime_types;

create policy "submitter uploads evidence for own submission" on storage.objects for insert to authenticated
with check (bucket_id='submission-evidence' and (storage.foldername(name))[1]=(select auth.uid())::text and exists (
  select 1 from public.community_submissions s where s.id::text=(storage.foldername(name))[2] and s.submitter_id=(select auth.uid())
));
create policy "submitter or authorised staff reads evidence" on storage.objects for select to authenticated
using (bucket_id='submission-evidence' and (
  (storage.foldername(name))[1]=(select auth.uid())::text or public.current_app_role() in ('ADMIN','AUDITOR','INVESTIGATOR','GOVERNMENT_REVIEWER')
));
-- No UPDATE or DELETE policy: original evidence is retained and cannot be silently replaced.
