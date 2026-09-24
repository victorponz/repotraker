-- Ejecuta esto una vez en el SQL editor de tu proyecto Supabase.

create table if not exists repo_tracker_repos (
  key text primary key,            -- "owner/repo"
  url text not null,
  branch text not null,
  last_sha text,
  commit_count integer not null default 0,
  total_added integer not null default 0,
  total_removed integer not null default 0,
  last_checked timestamptz
);

create table if not exists repo_tracker_commits (
  id bigserial primary key,
  repo_key text not null references repo_tracker_repos(key) on delete cascade,
  num integer not null,
  sha text not null,
  commit_date timestamptz not null,
  subject text,
  added integer not null default 0,
  removed integer not null default 0,
  unique (repo_key, sha)
);

create index if not exists repo_tracker_commits_repo_key_idx
  on repo_tracker_commits (repo_key);
