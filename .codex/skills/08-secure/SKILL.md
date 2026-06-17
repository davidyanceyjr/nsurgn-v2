---

name: 08-secure
description: Use when the user wants to secure, threat model, harden, review auth, review permissions, handle secrets, assess vulnerabilities, remediate security issues, evaluate dependency risk, create security tests, or patch security risks. Do not use for general implementation, testing, or deployment unless security controls or risks are the main focus.
---

# Security Engineering

## Purpose

Use this skill to identify, reduce, patch, and validate software security risks across design, code, configuration, dependencies, and operations. It makes security reasoning explicit, prioritizes realistic threats, and produces practical remediation without turning every engineering task into a full security review.

This skill owns security-driven vulnerability remediation, including patches and validation when remediation is the central task. It may use implementation support without surrendering ownership of the security-centered patch.

## Use when

* Designing or reviewing authentication, authorization, access control, session handling, permissions, identity flows, or privilege boundaries.
* Analyzing threats, abuse cases, trust boundaries, sensitive data handling, secrets, encryption, validation, or exposure risk.
* Reviewing code, configuration, dependencies, infrastructure, APIs, or workflows for vulnerabilities.
* Patching a known vulnerability or evaluating whether a reported issue is exploitable.
* Creating security tests, hardening guidance, security acceptance criteria, or dependency-risk assessments.

## Route elsewhere when

* General feature implementation is primary and security is not the main concern: use `04-build/SKILL.md`.
* Ordinary test planning is primary and tests are not security-specific: use `05-test/SKILL.md`.
* Deployment automation is primary and security controls, permissions, secrets, or environment hardening are not central: use `11-release/SKILL.md`.
* Performance, reliability, observability, or maintainability is primary and does not create or expose security risk: use `09-operate/SKILL.md` or `10-improve/SKILL.md`.
* Security requirements, roles, constraints, or acceptance criteria are unclear: use `01-understand/SKILL.md`.
* Security concerns require system-boundary or component-responsibility decisions: use `02-design/SKILL.md`.
* Security depends on API contracts, schemas, data models, or integration boundaries: use `03-contract/SKILL.md`.
* Formal security notes, runbooks, decision records, or user-facing security documentation are primary: use `06-document/SKILL.md`.
* The user needs legal, compliance, privacy, or formal audit advice: state that this skill cannot provide that substitute.

## Inputs to inspect

* System purpose, assets, actors, user roles, privilege levels, sensitive data, and business impact.
* Architecture, data flows, trust boundaries, external integrations, APIs, storage, deployment environment, and exposure paths.
* Authentication, authorization, session, token, secret, key, certificate, and permission models.
* Relevant code, configuration, dependency manifests, infrastructure definitions, logs, vulnerability reports, existing controls, monitoring, and tests.
* Threat assumptions, attacker capabilities, known constraints, acceptable risk, required standards, incident history, patch constraints, and rollback constraints.

## Procedure

1. **Define scope.** Identify the asset, operation, user role, data type, environment, and boundary under review. State what is in scope and intentionally out of scope.

2. **Map the trust model.** Identify callers, services, storage systems, external dependencies, privileged paths, unauthenticated paths, and every place data crosses a trust boundary.

3. **Identify realistic threats.** Consider broken access control, injection, unsafe deserialization, insecure direct object references, credential leakage, weak session handling, insufficient validation, dependency compromise, insecure defaults, and privilege escalation. Focus on threats that match the actual system.

4. **Evaluate controls.** Check whether the system authenticates the right actor, authorizes every sensitive action, validates untrusted input, protects secrets, limits exposure, logs security-relevant events, and fails safely.

5. **Prioritize findings.** Estimate likelihood, impact, exploitability, affected users or data, exposure, and compensating controls. Separate confirmed vulnerabilities from hypotheses and hardening opportunities.

6. **Remediate the risk.** Prefer narrow, actionable changes such as stricter authorization checks, safer APIs, parameterized queries, schema validation, secret rotation, dependency upgrades, least-privilege permissions, secure defaults, rate limits, audit logging, or defense-in-depth controls. Apply the patch when requested and security remediation is central.

7. **Define validation.** Provide or run security tests, regression checks, abuse cases, review steps, or manual verification that prove the issue is fixed and resistant to recurrence.

8. **Document residual risk.** State unresolved assumptions, tradeoffs, monitoring needs, follow-up work, and any risk that remains after mitigation.

## Subagent delegation

Subagents are optional. Use them only when independent threat perspectives, disjoint attack surfaces, bounded evidence collection, or second review of high-risk findings has a clear advantage.

Prefer read-only delegation. Any edit authority must name a narrow, disjoint write scope. Do not expose secrets or unnecessary sensitive data, and do not delegate live operations, destructive actions, risk acceptance, severity ownership, or remediation-complete claims.

Each delegation must invoke `08-secure/SKILL.md`, use sanitized inputs, define scope and expected output, prohibit recursive delegation, and include a clear stop condition. The parent integrates results, validates exploitability and severity, resolves contradictions, and owns final security conclusions.

## Expected outputs

* Threat models, abuse-case lists, or security review summaries.
* Prioritized vulnerability findings with severity, evidence, impact, exploitability, and remediation.
* Secure design recommendations for authentication, authorization, access control, data protection, secrets, permissions, or trust boundaries.
* Patch plans with implementation guidance and validation steps.
* Applied security patches or remediation with validation evidence when requested.
* Security test cases, regression checks, abuse cases, or acceptance criteria.
* Risk notes distinguishing confirmed issues, assumptions, hardening opportunities, and residual risk.

## Quality standard

* Identify assets, actors, trust boundaries, and sensitive operations before listing fixes.
* Ground findings in specific evidence and plausible exploit paths.
* Keep recommendations actionable and scoped to the actual system, not generic security advice.
* Treat authentication and authorization as separate controls.
* Do not expose, repeat, or unnecessarily transform secrets, tokens, credentials, keys, certificates, or sensitive environment values.
* Set severity from actual impact, likelihood, exploitability, exposure, and compensating controls, not theoretical weakness alone.
* Validate controls with positive and negative checks, including abuse-case testing where appropriate.
* Make assumptions and residual risks explicit.
* Avoid vague catch-all fixes such as encryption, rate limiting, or zero trust without a concrete threat path.
* Avoid overloading general implementation or deployment work with security review unless security is central.
* Do not claim compliance, audit readiness, complete safety, or full risk elimination from a limited review.

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
