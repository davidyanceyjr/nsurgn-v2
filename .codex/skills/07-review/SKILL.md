---

name: 07-review
description: Use when the user wants to review, inspect, lint, format, clean up, prepare a PR, manage Git workflows, branch, commit, handle pull requests, run static analysis, improve code hygiene, or get code ready for review. Do not use for main feature code, test design, deployment, runtime troubleshooting, or refactoring-centered work unless source control or review readiness is the main task.
---

# Source Control and Code Quality

## Purpose

Use this skill to keep code changes organized, safe, reviewable, and ready for established quality gates. It covers Git workflow, branch hygiene, commit quality, pull request preparation, code review, formatting, linting, static analysis, and narrow cleanup that reduces review friction.

This skill owns review readiness. It does not take over feature implementation, test strategy, deployment, runtime troubleshooting, formal security review, or broad refactoring.

## Use when

* Creating, reviewing, improving, splitting, or preparing branches, commits, diffs, pull requests, or merge plans.
* Checking code hygiene through formatting, linting, static analysis, dependency checks, accidental-file inspection, or cleanup.
* Reviewing code changes, triaging review comments, drafting review feedback, or deciding whether a change is ready to merge.
* Handling merge conflicts, rebases, cherry-picks, reverts, or release-branch hygiene.
* Cleanup is narrowly scoped to making an active change easier to review or pass established quality gates.

## Route elsewhere when

* Main feature or bug-fix implementation is required: use `04-build/SKILL.md`.
* Test design, test creation, regression coverage, or bug verification is primary: use `05-test/SKILL.md`.
* Deployment, CI/CD platform setup, containers, rollout, or rollback is primary: use `11-release/SKILL.md`.
* Production diagnostics, logs, metrics, or incident response is primary: use `09-operate/SKILL.md`.
* Formal security review, authentication, authorization, secrets, permissions, vulnerabilities, or threat modeling is primary: use `08-secure/SKILL.md`.
* Refactoring, technical debt, maintainability, performance, or scalability improvement is primary: use `10-improve/SKILL.md`.
* Durable docs such as contribution guides, review policies, changelogs, or decision records are primary: use `06-document/SKILL.md`.

## Inputs to inspect

* Repository status, branch name, target branch, staged changes, untracked files, conflicts, and remote divergence.
* The user's goal: review, clean up, commit, branch, rebase, merge, revert, push, or prepare a pull request.
* Relevant diffs, changed files, commit history, review comments, failing checks, static-analysis output, and traceability notes.
* Project conventions for branch names, commit messages, formatting, linting, code owners, PR templates, generated files, migrations, dependencies, and lockfiles.
* Risk level of affected modules, public interfaces, generated artifacts, configuration, dependencies, migrations, and user-facing behavior.
* Validation already performed and the exact output the user wants: commands, review findings, PR text, workflow guidance, or readiness assessment.

## Procedure

1. **Inspect workflow state.** Identify branch, target, status, staged and unstaged files, untracked files, conflicts, and remote divergence. Preserve user work. Avoid destructive commands unless explicitly requested and clearly explained.

2. **Classify and scope the change.** Determine whether the work is a feature, bug fix, refactor, dependency update, configuration change, documentation update, generated output, or review-only cleanup. Keep commit and PR boundaries focused.

3. **Review diff and repository hygiene.** Look for unrelated edits, noisy formatting, accidental files, secrets, debug code, dead code, unclear names, excessive complexity, generated-file drift, mismatched lockfiles, missing migration intent, or unsupported completion claims. Use traceability notes when present to catch omitted requirements or unrelated work.

4. **Run applicable quality gates.** Prefer existing project commands for formatting, linting, type checking, static analysis, dependency validation, and pre-commit hooks. Infer cautiously from manifests, Makefiles, CI configs, and tool configs when commands are unknown.

5. **Prepare review artifacts.** Recommend staging related files together, splitting unrelated work, and using concise commit messages that explain what changed and why. For PRs, summarize intent, key changes, risks, validation, linked issues, migration notes, rollout concerns, and reviewer focus areas without claiming unperformed checks.

6. **Handle review and integration safely.** When reviewing, lead with correctness, maintainability, clarity, security-sensitive mistakes, test impact, and compatibility. When responding to review, address the substance with concrete changes. For merges, rebases, cherry-picks, conflicts, and reverts, explain side effects and verification steps, especially for history rewriting.

7. **Finalize with evidence.** Report working-tree state, checks run, unresolved risks, and the next action. When merge readiness is requested, conclude exactly one of `MERGE READY`, `NOT MERGE READY`, or `BLOCKED`, with concise evidence. Treat implementation status and functional validation as inputs, not automatic proof of readiness.

## Subagent delegation

Subagents are optional. Use them only when a bounded, independent task has a clear speed or coverage advantage, such as disjoint diff review, repository-hygiene inspection, static-analysis triage, or objective formatting checks.

Prefer read-only delegation. Any edit authority must name a disjoint file scope and must exclude Git history changes, commits, pushes, merges, rebases, destructive operations, and overlapping work. Each delegation must invoke `07-review/SKILL.md`, prohibit recursive delegation, define expected output, and include a clear stop condition.

The parent integrates results, resolves contradictions, confirms evidence, and owns the final review findings and merge-readiness assessment.

## Expected outputs

* Safe Git workflow plans with commands when useful.
* Branch, commit, rebase, merge, cherry-pick, or revert guidance.
* Specific, actionable review comments ordered by risk.
* Concise pull request titles and descriptions.
* Code-quality checklists tailored to the actual change.
* Identification of accidental files, unrelated changes, style issues, unsupported claims, or review blockers.
* Static-analysis, formatting, linting, pre-commit, generated-file, dependency, or lockfile recommendations based on project conventions.
* `MERGE READY`, `NOT MERGE READY`, or `BLOCKED` assessments with evidence, remaining risks, and validation status when readiness is requested.

## Quality standard

* Preserve user work and avoid unnecessary destructive operations.
* Warn clearly before history-rewriting or data-loss-prone commands such as rebase, reset, force-push, broad cleanups, and destructive conflict resolution.
* Ground review feedback in the diff, project conventions, and observed evidence, not generic preference.
* Keep formatting, dependency updates, generated files, feature work, refactors, and unrelated cleanup separate unless intentionally scoped together.
* Use linting and formatting as quality inputs, not substitutes for correctness review.
* Do not exaggerate scope or validation in commit messages, PR descriptions, review responses, or readiness conclusions.
* Distinguish code-complete status from tested, merge-ready, releasable, or production-ready status.
* Avoid expanding review-focused cleanup into implementation, testing, release, security, observability, or broad refactoring ownership.

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
