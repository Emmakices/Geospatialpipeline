Phase 5 — SQL Server Pipeline Tracking (Run + Stage, Reprocessing, Gantt)
Why this exists

Object storage holds raw data — but you still need a system to track:

what arrived

what was processed

which attempt number (reprocessing)

stage timings (for Gantt and performance analysis)

errors and status

This is what makes pipelines observable and trustworthy.

13. Step 11 (fresh) — created SQL schemas

We created:

etl for pipeline tracking + procedures

stg for staging tables

CREATE SCHEMA etl;
CREATE SCHEMA stg;

14. Created etl.pipeline_run (supports reprocessing)

This table stores one row per pipeline run attempt.

Key fields:

file identity: dataset, country, blob_path, sha256, size, etag

reprocessing: attempt_no (1,2,3…)

timing: run_start_utc, run_end_utc

status: RUNNING/SUCCESS/FAILED

commit flags: is_committed, committed_at_utc

Why this matters:

multiple attempts are allowed

you can measure total pipeline time

you can see history of failures and retries

15. Created etl.pipeline_stage (stage start/end → Gantt-ready)

This table stores one row per stage per run (Receive, Validate, Parse, Commit, Cleanup, etc.)

Why this matters:

you get stage durations for performance tuning

you can build a Gantt chart later:

stage_name, start_time, end_time

16. Stored procedures for orchestration (ADF-friendly)

We created procs so ADF (or any orchestrator) can call SQL consistently:

etl.sp_run_start
Starts a run and auto-increments attempt_no per file hash

etl.sp_stage_start / etl.sp_stage_end
Track stage start/end + status + error

etl.sp_run_end
Ends the run with SUCCESS or FAILED

Why this matters:

ADF doesn’t need complex SQL

pipeline logging becomes standardized

Phase 6 — Universal Staging (because schema is unknown)
The challenge

OSM PBF is semi-structured:

tags differ by country and region

you can’t reliably pre-design all tables without profiling

17. Created a universal staging table: stg.osm_element

This is our safe landing table for parsed outputs.

It stores:

run_id (attempt isolation)

country + dataset

osm_type (N/W/R) and osm_id

lat/lon (for nodes)

tags_json (everything else)

optional geom_wkt later

Why this matters:

we don’t lose data due to unknown schema

we can profile later and decide final tables

supports multi-country without schema drift

Phase 7 — Commit + Cleanup (operational control)
18. Created etl.sp_run_commit

Marks a run as:

committed (approved landing)

sets committed_at_utc

Meaning of “commit” here:
✅ the run’s raw landing is complete and trusted
(we publish final tables later after profiling)

19. Created etl.sp_cleanup_run_staging

Deletes staging rows for a run_id.

Why this matters:

staging can grow huge

after publish is done, you can clean staging

or keep staging temporarily for debugging, then clean later

Phase 8 — Executed Run Attempt 1 (Nigeria) + stage timeline
20. Started run attempt 1

We ran etl.sp_run_start and got:

run_id = 1

Error encountered (SQL variable)

We initially got:

Must declare the scalar variable "@run_id"

Fix:

executed DECLARE + EXEC in the same batch (no GO, highlight whole script)

21. Stage: RECEIVE (SUCCESS)

Created stage row (start/end) for receiving blob.

Result:

receive_stage_id = 1

22. Stage: VALIDATE (SUCCESS)

Recorded validation as a stage.
This represents:

size check

sha256 match against blob metadata

Result:

validate_stage_id = 2

23. Stage: PARSE (placeholder SUCCESS)

Recorded parse stage as placeholder.
In the real pipeline:

ADF will orchestrate parsing using external compute:

Databricks / Synapse Spark, or

a container/Azure Function job
ADF should not parse .pbf itself.

Result:

parse_stage_id = 3

24. Stage: COMMIT (SUCCESS)

Started commit stage

ran etl.sp_run_commit

ended commit stage

Result:

commit_stage_id = 4

Meaning:
✅ run 1 is approved and committed for landing.

25. Ended the run as SUCCESS

We set:

final_status = SUCCESS

run_end_utc populated