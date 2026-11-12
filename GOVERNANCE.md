# VELCORA Linux Project Governance

## 1. Purpose

This document defines how VELCORA Linux is managed, how project decisions are made and how responsibilities are assigned.

VELCORA is a community-supported, Debian-based Linux operating system focused on Cloud Administration.

The governance model is intended to provide transparency, accountability, security and long-term project continuity.

## 2. Governance Principles

VELCORA governance follows these principles:

- Transparent decision-making.
- Documented technical decisions.
- Responsible repository management.
- Community participation.
- Security-focused development.
- Clear responsibilities.
- Fair contribution reviews.
- Protection of project infrastructure.
- Long-term maintainability.

## 3. Project Roles

### 3.1 Project Owner

The Project Owner is responsible for the overall direction and administration of VELCORA.

Responsibilities include:

- Defining the project's objectives.
- Maintaining project direction.
- Approving major architectural changes.
- Managing official project ownership.
- Appointing and removing maintainers.
- Approving major licensing and governance changes.
- Ensuring that the project has appropriate policies.

The Project Owner must follow the project's security and contribution procedures.

### 3.2 Core Maintainers

Core Maintainers are trusted contributors responsible for maintaining the operating system and reviewing contributions.

Responsibilities include:

- Reviewing pull requests.
- Maintaining assigned components.
- Investigating bugs.
- Approving appropriate changes.
- Maintaining technical documentation.
- Supporting development activities.
- Following security procedures.

Maintainer permissions should be limited to the responsibilities assigned to each individual.

### 3.3 Security Maintainers

Security Maintainers coordinate security-related activities.

Responsibilities include:

- Receiving vulnerability reports.
- Assessing security findings.
- Coordinating remediation.
- Reviewing security-sensitive changes.
- Preparing security advisories.
- Monitoring relevant dependency vulnerabilities.

Security reports must be handled through the private reporting process.

### 3.4 Documentation Maintainers

Documentation Maintainers are responsible for the quality and organisation of project documentation.

Responsibilities include:

- Reviewing documentation changes.
- Maintaining technical guides.
- Correcting outdated information.
- Improving installation instructions.
- Maintaining administrator documentation.

### 3.5 Community Moderators

Community Moderators help maintain a professional community.

Responsibilities include:

- Enforcing the Code of Conduct.
- Handling inappropriate behaviour.
- Supporting community discussions.
- Escalating serious incidents.
- Maintaining respectful communication.

### 3.6 Contributors

Contributors are individuals who provide code, documentation, testing, design or other approved project improvements.

Contributors do not automatically receive repository write permissions.

### 3.7 Community Testers

Community Testers help verify development and release builds.

Responsibilities include:

- Testing installation images.
- Checking hardware compatibility.
- Reporting bugs.
- Testing system updates.
- Verifying fixes.
- Documenting testing results.

## 4. Decision-Making

Project decisions should be made according to their importance and potential impact.

### Routine Decisions

Routine decisions may be handled by the relevant component maintainer.

Examples:

- Documentation corrections.
- Minor bug fixes.
- Small code improvements.
- Test updates.

### Significant Technical Decisions

Significant decisions should be discussed with the relevant maintainers.

Examples:

- Changes to system architecture.
- Changes to package selection.
- Changes to boot configuration.
- Major desktop changes.
- Changes to administration tools.

### Major Project Decisions

Major decisions require Project Owner approval.

Examples:

- Changing the project's primary purpose.
- Changing the operating system foundation.
- Changing the official licensing policy.
- Changing the governance model.
- Major changes to release policy.

## 5. Architecture Decision Records

Important technical decisions should be documented using Architecture Decision Records (ADRs).

ADRs should be stored in:

```text
repository/decisions/
```

Each ADR should contain:

1. Decision title.
2. Date.
3. Status.
4. Background and context.
5. Options considered.
6. Selected decision.
7. Reasoning.
8. Consequences.
9. Relevant references.

This ensures that future developers understand why decisions were made.

## 6. Repository Permissions

Repository permissions must follow the principle of least privilege.

The project should use:

- Protected main branches.
- Pull request reviews.
- Required automated checks.
- Restricted release permissions.
- CODEOWNERS.
- Secure account authentication.
- Multi-factor authentication for maintainers where available.

Contributors should not receive unnecessary administrative access.

## 7. Pull Request Approval

All changes must follow the official contribution process.

The required review level should depend on the risk of the change.

Security-sensitive changes should receive additional review.

No contributor should bypass required review procedures simply because they have repository access.

## 8. Project Discussions

Technical discussions should be documented through official project channels.

GitHub Issues should be used for bugs and actionable work.

GitHub Discussions may be used for general technical discussions and proposals.

Major decisions must be recorded in project documentation.

## 9. Conflict Resolution

When disagreements occur:

1. Identify the issue.
2. Allow the involved parties to explain their positions.
3. Review available technical evidence.
4. Consider project requirements.
5. Seek a reasonable resolution.
6. Escalate unresolved major decisions to the appropriate authority.

Personal disagreements should not interfere with technical review.

## 10. Maintainer Appointment

New maintainers should be appointed based on:

- Demonstrated contribution quality.
- Technical knowledge.
- Reliability.
- Security awareness.
- Professional behaviour.
- Understanding of project architecture.

Maintainer responsibilities and permissions should be documented.

## 11. Maintainer Removal

Maintainer access may be suspended or removed when necessary.

Possible reasons include:

- Serious misconduct.
- Repeated security violations.
- Misuse of repository permissions.
- Unauthorised project changes.
- Abandonment of assigned responsibilities.
- Compromise of an account.

Where appropriate, the affected person should be informed of the decision.

Immediate access restrictions may be necessary during security incidents.

## 12. Project Transparency

The project should maintain public records of:

- Releases.
- Major technical decisions.
- Development progress.
- Contribution guidelines.
- Known issues.
- Security advisories where disclosure is appropriate.

Private security reports and confidential information must remain protected.

## 13. Project Continuity

VELCORA should not depend entirely on undocumented knowledge held by one person.

Important project information must be maintained in the official repository.

This includes:

- Build procedures.
- Architecture documentation.
- Release instructions.
- Recovery procedures.
- Security policies.
- Maintainer responsibilities.

## 14. Governance Changes

This governance document may be updated as VELCORA grows.

Proposed changes should be discussed and documented.

Major governance changes require Project Owner approval.

## 15. Final Statement

VELCORA Linux aims to build a transparent and responsible open-source development community.

Its governance structure must support collaboration while protecting the project's architecture, security, infrastructure and long-term direction.