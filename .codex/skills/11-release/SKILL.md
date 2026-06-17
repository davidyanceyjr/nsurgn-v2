---

name: 11-release
description: Use when the user wants to release, deploy, ship, roll out, roll back, fix CI/CD, create release automation, plan deployment workflows, configure environments, containers, cloud/platform settings, migration rollout, or rollback plans. Do not use for logical system architecture, ordinary application code, incident response, log analysis, or long-term observability design unless release or deployment operations are the main task.
---

# Release and Platform Operations

## Purpose

Use this skill for release, deployment, CI/CD, rollout, rollback, and platform operations work. It helps move software from source control into target environments with traceable artifacts, explicit configuration, useful gates, verification, and recovery paths.

Do not use it for ordinary application code, logical architecture, incident response, log analysis, or long-term observability unless release or deployment operations are the primary task.

## When to use

* Create or modify CI/CD pipelines, build workflows, deployment jobs, release automation, or artifact promotion.
* Define concrete deployment topology, platform resources, environment placement, traffic routing, runtime configuration, containers, images, registries, or infrastructure configuration.
* Plan release readiness, deployment validation, hotfix flow, rollback, environment promotion, or rollout strategy such as blue/green, canary, rolling, feature-flagged, or manual-gated releases.
* Diagnose failed deployments, broken pipelines, bad release artifacts, misconfigured environments, or platform-level rollout issues.
* Write or review scripts whose primary purpose is building, packaging, releasing, deploying, configuring, verifying, or recovering software.

## Route elsewhere

* `04-build/SKILL.md` — normal application feature code, bug fixes, or general-purpose application scripts.
* `07-review/SKILL.md` — Git branching, review hygiene, version tagging, or static analysis unless they are release gates.
* `05-test/SKILL.md` — test strategy or test implementation unless the tests are deployment gates.
* `02-design/SKILL.md` — logical system architecture, component boundaries, or high-level tradeoffs.
* `09-operate/SKILL.md` — production incident response, alert triage, log investigation, monitoring, or runtime diagnostics unless the deployment process itself is the focus.
* `08-secure/SKILL.md` — secrets, permissions, supply-chain risk, authentication, authorization, or deployment security controls when security is central.
* `10-improve/SKILL.md` — deployment work driven mainly by performance validation, scaling limits, or maintainability refactoring.
* `06-document/SKILL.md` — release notes, runbooks, deployment docs, or operational documentation as the main deliverable.

## Inputs to look for

* Target environments and triggers: local, dev, test, staging, production, preview, ephemeral, disaster recovery; push, tag, merge, schedule, manual approval, artifact promotion, or external event.
* Build and artifact model: source repo, runtime, dependency manager, build commands, package format, image build, artifact naming, versioning, storage, and promotion.
* Deployment target and topology: VM, container runtime, Kubernetes, serverless, PaaS, static hosting, package registry, database, hybrid platform, regions, clusters, networks, routing, replicas, and dependencies.
* Configuration model: environment variables, config files, secrets, service accounts, feature flags, region settings, resource limits, and platform assumptions.
* Gates and constraints: tests, scans, approvals, change windows, migrations, backups, smoke checks, health checks, monitoring checks, downtime tolerance, compliance needs, cost limits, team access, and available tooling.
* Rollback risks: artifact retention, migration reversibility, cache/state compatibility, traffic switching, external integrations, and data-loss risk.

## Procedure

1. **Classify the task.** Determine whether the work is pipeline creation, deployment design, environment configuration, artifact packaging, release validation, rollback planning, or troubleshooting.

2. **Map the delivery path.** Identify how code becomes a deployable artifact, where artifacts are stored, how they are promoted, and which environment receives them.

3. **Separate build from deploy.** Prefer reproducible artifacts built once and promoted across environments. Rebuild per environment only with a clear reason.

4. **Define environment boundaries.** Clarify which configuration differs by environment and which settings must remain identical. Keep secrets out of source code, logs, command history, and build output.

5. **Add release gates.** Include the minimum useful checks before deployment: build success, tests, schema checks, dependency or image scans, approvals, or other task-relevant gates.

6. **Define topology and rollout.** Translate constraints into platform resources, placement, routing, runtime configuration, and a rollout method based on risk, downtime tolerance, traffic control, state compatibility, and rollback needs.

7. **Handle stateful changes carefully.** Treat database migrations, queues, caches, object stores, and external integrations as release risks. Prefer backward-compatible migrations and phased rollout when possible.

8. **Define verification.** Specify smoke tests, health checks, endpoint checks, synthetic checks, job status checks, or manual validation needed immediately after deployment.

9. **Define rollback or recovery.** State how to revert traffic, artifact version, configuration, migration, or feature-flag state. Identify cases where rollback is unsafe and roll-forward is preferred.

10. **Automate bounded operational steps.** Use release scripts for repeatable build, package, deploy, verify, and recovery actions. Keep them deterministic, parameterized, failure-aware, and separate from ordinary application behavior.

11. **Make operations repeatable.** Capture commands, scripts, pipeline stages, required approvals, environment variables, and failure handling in reusable form.

12. **Assess readiness when requested.** Conclude `RELEASE READY`, `NOT RELEASE READY`, or `BLOCKED`. Cite the target revision or artifact, gate results, deployment and rollback readiness, risks, and blockers. Release readiness does not claim post-release production health; that requires operational evidence owned by `09-operate/SKILL.md`.

## Expected outputs

* A CI/CD workflow, deployment topology, deployment plan, release checklist, platform configuration, or troubleshooting plan.
* Clear build, package, deploy, verify, and rollback steps.
* Environment-specific configuration guidance without leaking secrets.
* Release gate recommendations with rationale.
* Risk notes for migrations, permissions, secrets, dependencies, stateful services, or external integrations.
* Concrete commands, configuration snippets, or focused release scripts when implementation-level help is requested.
* Tradeoffs among deployment strategies when relevant.
* An evidence-based `RELEASE READY`, `NOT RELEASE READY`, or `BLOCKED` conclusion when readiness is assessed.

## Quality bar

* The deployed version is traceable from source revision to artifact to environment.
* Environment variables, secrets, permissions, platform assumptions, and failure paths are explicit.
* Deployment steps are ordered, repeatable, safe to automate, and free of vague instructions such as "deploy normally."
* Rollback or roll-forward behavior is realistic for both stateless and stateful changes.
* Gates are useful for release risk without bloating the process with unrelated checks.
* Scripts are scoped to delivery tasks, fail clearly, avoid embedded secrets, and do not absorb ordinary application logic.
* Guidance avoids unversioned artifacts, mutable tags without traceability, manually patched servers, and unnecessary release machinery.
* Platform-specific detail is limited to what the task requires.

## Authority

`AGENTS.md` is the repository-wide authority.

This skill applies only to its task area.

If this skill conflicts with `AGENTS.md`, follow `AGENTS.md`.

This skill must not permit:

- placeholder commands
- undocumented behavior
- fake success messages
- untested completion claims
- direct work on `main` unless explicitly instructed
- overwriting user changes
- creating new documentation files outside the documentation policy
