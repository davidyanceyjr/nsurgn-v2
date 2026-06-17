---

name: 06-document
description: Use when the user wants to document, explain, write docs, edit docs, organize, publish, or review technical documentation, including requirements docs, architecture notes, API docs, runbooks, test docs, maintenance notes, and decision records. Do not use to invent runbook procedures or other technical decisions.
---

# Technical Documentation

## Purpose

Produce maintainable technical documentation across the software development lifecycle. Turn technical context into useful written artifacts for readers: requirements summaries, architecture notes, API references, runbooks, testing notes, maintenance docs, changelogs, onboarding docs, and decision records.

Own documentation quality, structure, organization, editing, audience fit, and durable publication. Document established facts and procedures; do not invent or change requirements, architecture, APIs, implementation behavior, test evidence, deployment behavior, troubleshooting commands, diagnostics, mitigations, escalation paths, rollback actions, verification steps, or operational guarantees.

## When to use

* Use when the task is to write, revise, summarize, organize, edit, publish, or review technical documentation.
* Use when documenting requirements, workflows, architecture, APIs, interfaces, tests, releases, maintenance procedures, decisions, onboarding material, README content, changelogs, troubleshooting guides, or established runbook procedures.
* Use when converting technical discussion, code behavior, tickets, logs, design notes, release changes, or established handoff facts into durable written documentation.
* Use when reviewing documentation for clarity, completeness, accuracy, audience fit, stale information, or maintainability.

## When not to use

* Do not use when the main task is deciding architecture, designing contracts, changing production code, creating or validating tests, deploying or releasing, troubleshooting operations, creating runbook procedures, or packaging active-work continuity.
* Use the owning skill for those primary objectives: `02-design`, `03-contract`, `04-build`, `05-test`, `09-operate`, `11-release`, or `12-handoff`.

## Inputs to look for

* Documentation type, target audience, requested artifact, and expected format.
* Source material such as requirements, tickets, code, comments, architecture notes, schemas, API examples, logs, test results, release changes, prior docs, or source-of-truth links.
* Scope and boundaries: system, feature, component, workflow, environment, version, decision, or established procedure covered.
* Repository structure, style guide, naming conventions, confidentiality or compliance constraints, and expected length.
* Freshness signals, ownership, dates, versions, deprecated behavior, known gaps, TODOs, and established traceability facts when durable publication is requested.

## Procedure

1. Identify the documentation goal, audience, artifact type, and scope. If unclear, infer the most useful format from the task and state assumptions only when they help the reader.

2. Separate documentation from technical decision-making. Record existing decisions accurately; do not invent requirements, architecture, APIs, test results, deployment behavior, operational procedures, or guarantees.

3. Extract source facts. Prefer user-provided context, repository files, tickets, code behavior, commands, interfaces, logs, existing docs, and source-of-truth links over assumptions. When publishing traceability, preserve established requirement IDs, decisions, changed areas, evidence, statuses, and gaps without changing them.

4. Choose a structure that matches the artifact. Use setup and usage sections for README-style docs; status, context, decision, and consequences for ADRs; provided symptoms, impact, checks, mitigation, rollback/escalation, and verification content for runbooks; and concise scope, examples, commands, gaps, ownership, and risks for API, test, release, maintenance, or onboarding docs.

5. Write for actionability and compactness. Prefer concrete commands, paths, examples, expected outcomes, and verification steps over vague prose. Include what readers need to do the job safely and refer to source material instead of duplicating entire systems.

6. Mark uncertainty explicitly. Use labels such as `Assumption`, `Open question`, `TODO`, or `Needs verification` when source material is incomplete, stale, deprecated, or contradictory.

7. Review for consistency with existing terminology, component names, API names, environment names, version identifiers, links, and maintenance signals such as owner, last updated date, review trigger, deprecation note, or next review condition.

## Subagent delegation

Subagents are optional. Use them only for disjoint sections, fact extraction, consistency checks, reference checks, or audience review where parallel work has a concrete advantage. Prompts must define sources, scope, audience, and output; subagents must not invent decisions, procedures, evidence, statuses, or ownership. The parent owns final terminology, structure, integration, and publication.

## Expected outputs

* Complete or revised technical documentation in the requested or inferred format.
* Documentation outline, template, README section, ADR, API reference, test documentation, maintenance note, changelog, release note, onboarding guide, troubleshooting guide, or runbook based on established facts.
* Gap list showing missing facts, stale sections, contradictions, assumptions, or required follow-up checks.
* Durably published compact traceability record when explicitly requested and supported by established source facts.

## Quality checks

* The document has a clear audience, purpose, and scope.
* Technical claims are grounded in source material or clearly marked as assumptions.
* Published traceability preserves the owning skills' established facts and does not create engineering decisions, statuses, or evidence.
* Steps are actionable, ordered, and verifiable when the artifact calls for procedures.
* Commands, paths, names, versions, endpoints, links, and environment labels are consistent.
* The document does not duplicate responsibilities owned by architecture, contract, implementation, testing, deployment, security, observability, performance, or handoff skills.
* Stale, deprecated, uncertain, contradictory, or missing information is clearly identified.
* The result is concise enough to be useful and durable enough to maintain.

## Anti-patterns

* Avoid inventing technical behavior to make the document feel complete.
* Avoid turning documentation into a broad tutorial when the task needs a focused artifact.
* Avoid copying large code blocks, schemas, logs, or config files unless they are essential examples.
* Avoid mixing unresolved design debate into final documentation without labeling it as open.
* Avoid vague phrases like “handle errors appropriately” without explaining expected behavior or escalation.
* Avoid documenting aspirational behavior as if it already exists.
* Avoid hiding risks, assumptions, deprecated behavior, contradictions, or known gaps.
* Avoid spreading the same source-of-truth content across many documents without a maintenance plan.

## Related skills

* `01-understand`, `02-design`, `03-contract` — use when requirements, workflows, architecture, schemas, APIs, or contracts need to be defined or evaluated before documenting them.
* `04-build`, `05-test` — use when production code, test strategy, test cases, regression checks, or bug verification must be created before documentation.
* `08-secure`, `09-operate`, `11-release` — use when documentation depends on security design, threat modeling, permissions, operational diagnostics, mitigations, escalation paths, rollback actions, deployment, CI/CD, environments, or release behavior.
* `10-improve`, `07-review` — use when documentation depends on profiling, tuning, scalability validation, refactoring, technical debt analysis, review workflow, repository hygiene, or static-analysis policy.
* `12-handoff` — use when active-work continuity or resume context is the main task.

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
