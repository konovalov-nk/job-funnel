Этапы. Что я хочу сделать.



M0. Минимальный трекер локально. Подразумевается что source уже содержит dedupe записи, и мы просто итерируем по новым вакансиям от компаний и добавляем их в трекер, чтобы дальше уже апплаиться.



# Data Models



Не все модели пока что используются, но сразу сделаем весь шейп чтобы минимизировать миграции.



Модели описывать по спецификациям в формате.



spec { id, slug, title, level, status, description }

-> ac { id, spec_id, slug, title, review, risk, concerns, intent }



example spec:

level = system

slug = model/source

title = Source

description = Job tracker requires seed data for jobs and companies, which we refer to as "Source". This entity contains `base_url` for source provider, `type` of seed data defined by enum ..., `adapter` name defined by enum ... that knows how to fetch data/interact with the endpoint defined at `base_url`, `auth_mode` details whether source provider requires adapter to pass authentication credentials, `enabled` is a flag indicating whether `fetch_run` records can be created.



example ac:

slug = can-create-and-persist-valid-record

title = System can persist new added source into selected DB

review = automatic

risk = medium

concerns = 

intent = Given valid Source attributes, we want to see a new record persisted in selected DB engine



00. source (id, name, type { job, company, both }, base_url, adapter, auth_mode, enabled) + fetch_run (id, source id, adapter, retry { 0 -> 3 max }, status { new -> in_progress -> completed / failed }, content { json with evidence what was done, or captured errors })

01. company (id, source id, company name, website, careers page URL, created_at, updated_at)

02. resume (id, json, pdf_location / or _blob, created_at/updated_at)

03. experience (id, company name, title, description, start_date, end_date)

04. resume_experience (id, resume_id, experience_id)

05. skill (id, name, type { programming_language, framework, library, technology (cloud), concern (IAM / AuthN / AuthZ), service (Stripe, MailChimp) ... })

06. experience_skill (id, experience id, skill id)

07. experience_story (id, experience id, situation, task, action, result)

08. question (id, concern { skill, organizational, ... }, text, response_type { text_single_line, text_multiline, file, ... })

09. question_response (id, question id, type { text, file, url }, response { string }, status { draft, approved })

10. job (id, canonical_id, source id, company id, job name, description, apply_url, apply_adapter, skip_reason, created_at, status { new -> applied / skip })

11. job_skill (id, job id, skill id, required { bool })

12. job_question (id, job id, question id, required { bool })

13. application (id, job id, resume id, status { new -> draft_ready -> approved_for_submit -> submitted -> rejected / in_progress / completed })

14. application_question_response (id, application id, question response id)

15. job_interview_stage (id, job id, order { integer }, type { recruiter, technical, system_design, manager, executive })

16. interview (id, job interview stage id, date, status { new, in_progress, completed }, result { awaiting, success, reject })

17. interview_artifact (id, interview id, type { audio, transcript, feedback, screen_recording, source_code_repository, interview_url, ... }

18. person (id, name, email, linkedin, website, phone, telegram, discord, notes)

19. interview_person (id, interview id, person id)

20. company_employee (id, company id, person id, role)

21. company_recruiter (id, company id, person id)

22. application_artifact (id, application id, type { outreach_message, contact, email_inbox }, content { json }, status { for outreach_message: draft -> draft_accepted/draft_rejected -> processing -> message_sent -> waiting_response -> success/no_response  ..., depends on type })

23. company_research (id, company id, type { employees, problem_statement, products, blog }, status { draft -> in_progress -> review -> completed/rejected }, content { json })

24. company_insight (id, company id, insight_type { ... }, content { json })

25. event (id, type { fetch, application, application_submit, job, interview }, source { string }, payload { json }, timestamp { iso 8601 / eg 2026-05-31T01:17:29Z UTC })



ALL models must be a separate spec with ACs. The reason is that we might update models / ACs to add semantics on what should happen with the models on technical level, and maybe later product / technical specs will be linked.



# Processes



Описывать по спецификациям в формате.

spec { id, slug, title, level, status, description }

-> ac { id, spec_id, slug, title, review, risk, concerns, intent }



1 процесс = 1 spec, x ACs (happy / edge cases)

spec.slug example: process/add-new-source

spec.level example: system

spec.description example: We define a process to add a new source for fetching recent jobs/companies. It is assumed that source contains deduped job/company data with high enough confidence. We do not solve de-duplication between multiple sources, and this means at most there should be only one active source, or it should be somehow guaranteed two different sources reference same source of truth for deduping.



ac.slug example: create-and-store-new-valid-source

ac.title example: System can persist new added source into selected DB

ac.review example: automated

ac.risk example: medium

ac.intent example: To provision system with valid job/company records, we have to allow adding new sources with selected attributes. Required fields are: type, base_url, adapter, enabled. Correct types and adapter are enums defined in the code.



1. add new job/company source -> +1 source row

2. create fetch run for source -> +1 fetch_run row (status: new), +1 event row (type: fetch)

3. run fetch_run until completion -> five cases: happy { +x company/job rows, update fetch_run row on every workflow step, +1 event row (type: fetch) } / adapter_not_found / invalid_source / retry_exhausted / server_error ({ +1 event row with error message } in all edge cases)

4. add skill from seed JSON -> +x skill rows

5. add resume (in JSON format) -> +1 resume row, + x experience rows (parse json, extract it, shape is fixed/known), + x resume_experience rows (to connect parsed experience records back to resume id) + x experience_skill rows (per parsed experience row)



6. research job -> +x question rows (during apply there might be questions for applicants we have to extract and save), +x job_question rows (immediately link extracted questions to track which job created which questions) +x job_skill rows (to track existing skills it mentions) +1 event row (type: job) when research started and +1 event row (type: job) when research succeeded/failed



7. start application for job -> +1 application row, +x question_response rows (status: draft) +x application_question_response rows (to connect draft questions to application immediately) +1 event row (type: application) when application record created, +1 event row when draft started and +1 event when draft is succeeded/failed, +1 event (type: application) when ready for human review before submitting



8. submit application -> transition application row to `approved_for_submit`, then use job.apply_adapter to apply to the job at job.apply_url using application context (resume json / pdf / question responses, then emit +1 event (type: application_submit) when we start the adapter, and +1 on finish/failure; event.payload contains evidence that application succeded or failed.



9. ... to be continued



# Tech decisions



Also can be a set of specs/decisions.



## 1. Stack:

- https://github.com/yatish27/shore



Spec: why this template, etc

(hint: we don't have time invent our own perfect boilerplate for this, and this is first thing I found)



ACs:

1. Not sure how do we even ensure that we used specifically this Rails template and not something else... maybe we just ensure that commit with specific sha exists (e.g. https://github.com/yatish27/shore/commit/0211486b9b350cca0a25ce608601e960d61f985e)? or maybe just implement ACs 2-11 and that's pretty much the template 🤷

2. Ruby: 4.0.1

3. Rails: 8.1

4. Code quality: RuboCop with Standardrb config

5. Testing: RSpec + FactoryBot -> Shore uses minitest, so we need to update it and replace all references for minitest to RSpec as default.

6. DB: postgresql

7. FE framework: React + Inertia.js

8. Asset bundling: vite_rails

9. JS package management: Bun

10. Solid Queue — Solid Queue for background jobs

11. Solid Cache — Solid Cache for caching

12. Solid Cable — Solid Cable for WebSockets

13. GitHub Actions — CI/CD with security scanning, linting, and tests



## 2. Deployment strategy



Localhost deployment via Caddy network reverse-proxy.

Docker compose file with:



```

name: job-tracker # for proper namespacing

...

service:

  web:

    build: ...



+ caddy labels

    labels:

      caddy: "job-tracker"

      caddy.reverse_proxy: "{{upstreams RAILS-PORT-FROM-SHORE-BOILERPLATE}}"



networks:

  proxy:

    external: true

```



Caddy is already working.



ACs:

1. Docker containers must be healthy

2. Containers must not be reachable from outside by port numbers, only by *.home.br11k.dev hostnames.

3. Test connectivity to job-tracker.home.br11k.dev (resolves to local IP)

4. Must NOT be accessible from outside (not sure how to test this)



## 3. Development workflow



Spec 1: coherence DB/project must be provisioned and available from host



ACs:

1. coherence-core-db version -> coherence-core-db 0.2.0

2. coherence-core-db project catalog-preflight -> catalog-preflight: ok

3. coherence-core-db db-ping -> db-ping: ok (socket)



Spec 2: Testing strategy

Since we want to use RSpec/factorybot, it makes sense to use coherence specs to define what does "valid business object" means via model Spec/ACs. I remember I had this problem in Django when I was trying to explain that fixtures doesn't scale well with huge monolith app with hundreds of tables. So when I wanted to implement FactoryBot in Python I realized there is a domain/business problem. When you write a trait for FactoryBot-style factory to instance an object, this trait can create associations, objects and other things that mean something semantically for product. The problem is then trait must follow same process for creating objects like the application does. If this contract doesn't exist/broken, then test objects might be invalid from product semantics.

Example: 

- We have created a trait for `Application`, `:ready_for_review`, which means (see, we're doing semantics already) Process 7 was executed on existing job record.
- How can we replicate process 7 state?
  - Option 1: reproduce state from scratch using same service objects / model code / controllers starting from primitives / clean system state
  - Option 2: simply capture system "state" (DB records, files, whatever) after running successful minimal e2e test on process 7, and recreate it using Rails primitives (e.g. Model#create)
  - Option 3: we define explicit state transitions and what needs to happen for an object to end up in this specific state, and disallow creating objects via `Model#create`, only from known "checkpoints" that we define, lets say, inside Coherence Specs!

So whenever we create something in FactoryBot using traits, they should be
1. Composable
2. 

For example:

- 



ACs:

1. For simple unit tests use minitest



Spec 2: Workflow steps

(e.g. beads, planning, accept/reject plan, coding, present work, address feedback, commit, close task, etc)

... to be added later ...



Spec 3: 
