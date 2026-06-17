---

name: 04-build
description: Use when the user wants to build, implement, fix, code, debug, modify, or explain production code, including ordinary bug fixes and incidental refactoring required to complete implementation work. Do not use when Git workflow, formal test strategy, deployment, incident response, vulnerability remediation, security review, or refactoring is the primary objective.
---

# Implementation Engineering

## Purpose

Guide scoped production code creation and modification from requirements, designs, bug reports, or implementation tasks. Own implementation-level control flow, data structures, module organization, error handling, dependency use, and development-time debugging.

## When to use

* Use when asked to write, modify, debug, or explain application code.
* Use when implementing a feature, bug fix, CLI command, service method, UI behavior, library function, script, parser, adapter, or integration.
* Use when choosing implementation-level patterns, data structures, abstractions, or module boundaries inside an existing design.
* Use when diagnosing development-time errors, compiler failures, runtime exceptions, failing local builds, or incorrect behavior in code.
* Use when making incidental readability, structure, type-safety, dependency, or error-handling improvements needed to complete implementation work.

## When not to use

* Do not use when the main task is requirements clarification, architecture, API/schema contracts, formal test planning, Git/review workflow, deployment, production operations, security-centered work, or refactoring-centered work.
* Use the owning skill for those primary objectives: `01-understand`, `02-design`, `03-contract`, `05-test`, `07-review`, `08-secure`, `09-operate`, `10-improve`, or `11-release`.

## Inputs to look for

* User goal, bug report, feature request, expected behavior, and known requirement or acceptance-criterion IDs.
* Existing code, project language/framework, runtime, package manager, conventions, module boundaries, and established interfaces.
* Constraints such as compatibility, performance needs, style conventions, supported platforms, dependency limits, or security-sensitive inputs.
* Relevant errors, stack traces, failing commands, logs, reproduction steps, and local validation commands.
* For user-facing changes, established interface patterns and applicable input, viewport, browser, platform, accessibility, or compatibility constraints.

## Procedure

1. **Clarify the implementation target.** Identify the concrete behavior to add, change, or fix. Separate required behavior from assumptions. If details are missing, make minimal safe assumptions and state them briefly.

2. **Inspect the project shape.** Determine the language, framework, conventions, module boundaries, naming patterns, dependency style, and error-handling approach. For an empty or minimal repository, establish only the simplest suitable runnable structure unless constraints require more.

3. **Choose the smallest viable change.** Avoid redesigning unrelated areas. Keep public interfaces stable unless change is required. Use abstractions only when they reduce real complexity or match existing conventions.

4. **Implement deliberately.** Write or modify code coherently. Preserve existing behavior outside the task. Handle relevant edge cases such as invalid or missing input, empty collections, concurrency, retries, timeouts, partial failure, cleanup, and backward compatibility.

5. **Address user-facing basics when applicable.** Follow established project patterns and proportionately consider semantic controls, keyboard operation, focus behavior, labels, readable error or status feedback, responsive behavior, and supported browser or platform compatibility. Do not turn backend-only work into a UX exercise.

6. **Debug and validate from evidence.** For broken behavior, trace from observed symptoms to likely causes using stack traces, failing lines, logs, reproduction steps, and invariants. Run the narrowest useful build, run, type check, lint, focused test, or reproduction command that is available. Report actual results without claiming formal functional verification owned by `05-test`.

7. **Report implementation status.** Label the result `IMPLEMENTATION PATCHED`, `IMPLEMENTATION PARTIAL`, or `IMPLEMENTATION BLOCKED` with concise evidence. Claim `IMPLEMENTATION PATCHED` only when every in-scope implementation item is done, the relevant verification commands have been run, and the results have been reported. A plan-only output cannot receive `IMPLEMENTATION PATCHED`; blocked or deferred in-scope work requires `IMPLEMENTATION PARTIAL` or `IMPLEMENTATION BLOCKED`. Do not use `CODE COMPLETE` or equivalent language unless the relevant tests and verification commands have passed.

## Expected outputs

* Production code, patch, diff, or file-level implementation plan.
* Debugging diagnosis with likely root cause and concrete fix.
* Notes on assumptions, edge cases handled, compatibility concerns, checks attempted, and unverified behavior.
* Implementation-owned compact traceability updates when known IDs exist, mapping IDs to changed files or code areas and implementation status.
* `IMPLEMENTATION PATCHED`, `IMPLEMENTATION PARTIAL`, or `IMPLEMENTATION BLOCKED` status with concise evidence and explicit gaps.

## Quality checks

* The change directly addresses the requested behavior or bug.
* The solution fits project conventions and avoids unnecessary abstractions.
* Public interfaces, data formats, and side effects are preserved unless intentionally changed.
* Errors and edge cases match the surrounding application style.
* Dependencies are justified and not added casually.
* Security-sensitive inputs are treated carefully, even when formal security review is out of scope.
* Validation steps are accurate and distinguish facts from assumptions.

## Anti-patterns

* Avoid rewriting large areas of code when a targeted fix is enough.
* Avoid inventing architecture, APIs, schemas, or requirements that belong to other skills.
* Avoid adding dependencies for trivial logic.
* Avoid abstractions that make straightforward code harder to follow.
* Avoid hiding uncertainty about uninspected code or unrun checks.
* Avoid changing behavior outside the task without calling it out.
* Avoid treating secure coding basics, local tests, or implementation status as broader readiness claims.

## Related skills

* `01-understand`, `02-design`, `03-contract` — use when requirements, architecture, schemas, APIs, or integration contracts are the main task.
* `05-test`, `07-review`, `06-document` — use when validation, review workflow, static analysis, PR readiness, or durable documentation is the main task.
* `08-secure`, `11-release`, `09-operate` — use when security, deployment, CI/CD, production diagnostics, or operations are central.
* `10-improve` — use when profiling, tuning, refactoring, scalability validation, technical debt reduction, or maintainability improvement is the main goal.

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
