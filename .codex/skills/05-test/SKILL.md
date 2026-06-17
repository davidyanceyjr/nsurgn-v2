---

name: 05-test
description: Use when the user wants to test, validate, verify, regress, debug tests, create tests, review coverage, improve tests, automate checks, manually validate behavior, or verify bugs. Do not use for deployment, observability, security testing, or performance testing unless general functional validation is the main task.
---

# Testing and Validation

## Purpose

Guide test planning, test creation, test review, and validation work across the software development lifecycle. Use it to verify intended behavior, prevent regressions, reproduce bugs, and confirm fixes.

The goal is practical confidence, not exhaustive theoretical coverage. Focus on the smallest useful test set that validates requirements, important behavior, edge cases, integrations, and known risks.

## When to use

* Use when writing or improving unit, integration, end-to-end, regression, smoke, acceptance, or manual tests.
* Use when creating a test plan, validation checklist, QA checklist, or manual test procedure.
* Use when reproducing, isolating, documenting, or verifying a bug.
* Use when reviewing existing tests for usefulness, coverage, brittleness, or maintainability.
* Use when deciding what should be tested before merging, releasing, or accepting a change.
* Use when converting requirements or acceptance criteria into concrete validation steps.

## When not to use

* Do not use when the main task is production feature code, security testing, performance or scalability validation, deployment, production operations, or documentation-only work.
* Use the owning skill for those primary objectives: `04-build`, `08-secure`, `10-improve`, `11-release`, `09-operate`, or `06-document`.

## Inputs to look for

* Feature, bug, requirement, user story, or acceptance criteria being validated, including stable identifiers when available.
* Expected behavior, invalid behavior, business rules, important paths, edge cases, and known risks.
* Existing tests, framework, fixtures, mocks, test data, test commands, and coverage gaps.
* Changed files, affected modules, dependencies, integrations, data paths, runtime environment, configuration, services, and permissions.
* Failure reports, logs, reproduction steps, screenshots, user impact, constraints, flaky tests, unavailable environments, and relevant user-facing platform or accessibility needs.

## Procedure

1. **Identify the validation target.** Determine what behavior, requirement, bug, or risk needs proof. Separate intended behavior from implementation details. Retain known requirement and acceptance-criterion IDs and identify uncovered items.

2. **Choose the cheapest useful test level.** Prefer unit tests for isolated logic, integration tests for boundaries, end-to-end tests for critical workflows, and manual checks only where automation is impractical or not worth the cost.

3. **Define expected outcomes.** Write clear pass/fail conditions before designing test cases. Include normal paths, edge cases, error paths, functionally relevant authorization or permission boundaries, and regression cases for known bugs.

4. **Inspect and reuse existing coverage.** Extend nearby useful tests when possible. Avoid duplicating assertions through slower or more brittle paths.

5. **Implement or specify focused tests.** Keep each test centered on one behavior or risk. Use realistic fixtures, minimal setup, deterministic data, precise assertions, and the project’s established framework, naming conventions, fixture patterns, and assertion style. For user-facing work, add proportionate checks for keyboard flow, focus, labels, readable status or error feedback, responsive layouts, and supported browser or platform behavior.

6. **Run the relevant scope and analyze failures.** Run the narrowest test command first, then broader suites as needed. Record commands, environment assumptions, failures, skipped tests, and unverified areas. Classify failures as product defects, test defects, data/setup issues, environmental failures, or flakes; do not weaken assertions unless the expected behavior was wrong.

7. **Report verification status.** Map tests and evidence to known requirement or acceptance-criterion IDs. Mark each as `passed`, `failed`, `blocked`, `skipped`, or `unverified`, identify uncovered requirements explicitly, and conclude `FUNCTIONALLY VERIFIED`, `PARTIALLY VERIFIED`, or `BLOCKED` when functional verification is requested. Functional verification does not imply merge readiness or release readiness.

## Subagent delegation

Subagents are optional. Use them only for disjoint validation scenarios, test levels, requirement IDs, components, environments, test-case review, or failure classification where parallel work has a concrete coverage or speed advantage. Subagents may report only evidence from checks they actually performed and must not repair production code unless separately authorized under `04-build`. The parent owns final verification synthesis, resolves contradictions, and closes completed agents promptly.

## Expected outputs

* Test plan, matrix, checklist, validation strategy, or manual QA steps with clear expected results.
* New or revised automated tests, regression tests, or minimized bug reproduction cases.
* Bug report artifact with environment, reproduction steps, expected result, actual result, and supporting evidence.
* Test execution summary with commands, results, failures, coverage gaps, skipped checks, unverified behavior, and remaining risks.
* Validation-owned compact traceability updates when known IDs exist, mapping IDs to tests, evidence, verification status, and uncovered items.
* Overall `FUNCTIONALLY VERIFIED`, `PARTIALLY VERIFIED`, or `BLOCKED` conclusion when functional verification is requested.

## Quality checks

* Tests map back to requirements, acceptance criteria, changed behavior, or known risks.
* Each important behavior has a clear pass/fail signal.
* Test names describe behavior, not implementation mechanics.
* Assertions are specific enough to diagnose failure.
* Tests are deterministic and do not rely on hidden order, real time, random data, or unavailable services unless explicitly controlled.
* Test data is minimal, readable, and isolated.
* Slow or brittle tests are justified by risk.
* Regression tests would fail for the original bug.
* Manual steps are reproducible by another person.
* Reported results distinguish verified facts from assumptions.

## Anti-patterns

* Avoid writing tests only to increase coverage numbers without validating meaningful behavior.
* Avoid duplicating the same assertion across unit, integration, and end-to-end tests without a reason.
* Avoid over-mocking until the test no longer validates real behavior.
* Avoid snapshot-heavy tests that obscure the intended assertion.
* Avoid broad end-to-end tests for logic that can be validated with cheaper tests.
* Avoid changing production behavior to satisfy a poorly designed test.
* Avoid weakening assertions to make a test pass without resolving the underlying issue.
* Avoid ignoring flaky tests; classify and address the source of nondeterminism.
* Avoid claiming full validation when important paths, environments, or integrations were not checked.

## Related skills

* `01-understand` — use when requirements, workflows, or acceptance criteria are unclear.
* `04-build` — use when production code must be created or changed as part of the test work.
* `08-secure`, `10-improve`, `11-release`, `09-operate` — use when validation centers on security, performance, scalability, deployment, environments, release gates, production diagnostics, logs, metrics, or alerts.
* `06-document` — use when producing formal test documentation, QA records, release notes, or long-lived validation guides.

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
