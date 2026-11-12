# VELCORA Linux Security Policy

## 1. Purpose

Security is a core requirement of VELCORA Linux.

VELCORA is a Debian-based Linux operating system focused on Cloud Administration.

This document explains how security vulnerabilities should be reported, investigated and addressed.

It also establishes security expectations for contributors and maintainers.

## 2. Supported Versions

VELCORA is currently under development.

Until official stable releases are published, security support is provided on a best-effort basis for active development branches.

Once stable releases are introduced, the project will publish a version support policy.

The support policy should identify:

- Supported releases.
- Security maintenance periods.
- Update availability.
- End-of-support dates.
- Upgrade recommendations.

The project must not promise security support periods that it cannot maintain.

## 3. Reporting a Vulnerability

Do not publish sensitive security vulnerabilities in public GitHub Issues or Discussions.

Report vulnerabilities through the private reporting mechanism configured for the official VELCORA GitHub repository.

The project should enable GitHub private vulnerability reporting where available.

If private reporting is unavailable, contact an authorised security maintainer through an officially published private contact channel.

Do not send vulnerability reports to unofficial accounts.

## 4. Information to Include

A vulnerability report should include as much of the following information as possible:

- A clear vulnerability description.
- Affected VELCORA version or development branch.
- Affected component.
- Steps required to reproduce the issue.
- Expected behaviour.
- Actual behaviour.
- Potential security impact.
- Relevant logs or screenshots.
- Suggested mitigation, if known.

Do not include real passwords, private keys, authentication tokens or unrelated personal information.

## 5. Responsible Disclosure

Researchers are requested to:

- Report vulnerabilities privately.
- Avoid unnecessary access to other people's systems or data.
- Avoid disrupting services.
- Avoid modifying or deleting data.
- Avoid public disclosure before coordinated remediation.
- Give maintainers a reasonable opportunity to investigate the report.

The project will aim to communicate with researchers during the investigation.

## 6. Vulnerability Assessment

Reported vulnerabilities should be assessed according to:

- Severity.
- Exploitability.
- Potential impact.
- Affected versions.
- Affected components.
- Availability of mitigations.
- Potential impact on users.

Where appropriate, the project may use the Common Vulnerability Scoring System (CVSS) as a reference.

Severity classifications should be based on evidence rather than assumptions.

## 7. Vulnerability Handling Process

The recommended process is:

### Step 1 — Report Received

The security report is received through the private reporting mechanism.

### Step 2 — Initial Assessment

A security maintainer checks whether the report is relevant and reproducible.

### Step 3 — Investigation

The affected component and potential impact are investigated.

### Step 4 — Remediation Planning

The maintainers determine the appropriate correction or mitigation.

### Step 5 — Testing

The proposed fix is tested to confirm that it addresses the vulnerability without introducing unacceptable regressions.

### Step 6 — Release Preparation

An appropriate security update or release is prepared.

### Step 7 — Disclosure

The project publishes relevant security information when it is safe and appropriate to do so.

### Step 8 — Documentation

The vulnerability, affected versions and remediation are documented.

## 8. Security Priorities

The project should prioritise vulnerabilities based on their actual risk.

Critical and high-severity vulnerabilities affecting supported releases should receive urgent attention.

Lower-severity issues should be scheduled according to their impact and available resources.

## 9. Security Development Requirements

Contributors must:

- Avoid hardcoded credentials.
- Validate external input.
- Use appropriate file permissions.
- Avoid unnecessary root privileges.
- Protect sensitive configuration.
- Review third-party dependencies.
- Avoid unsafe command execution.
- Use secure communication protocols where appropriate.
- Document security-sensitive functionality.

Changes affecting authentication, authorisation, package management, boot, networking or administrative permissions require additional review.

## 10. Secret Management

Passwords, private keys, API tokens and other credentials must never be committed to public repositories.

Developers must use appropriate secret-management procedures.

If a secret is accidentally published:

1. Treat it as compromised.
2. Revoke or rotate the credential.
3. Investigate possible misuse.
4. Remove the exposed secret from the repository history where appropriate.
5. Review the incident.
6. Document corrective actions.

Simply deleting the visible file is not sufficient to guarantee that a leaked credential is safe.

## 11. Dependency Security

The project should monitor important dependencies for known vulnerabilities.

Maintainers should:

- Review upstream security advisories.
- Update affected dependencies.
- Remove unnecessary dependencies.
- Verify package sources.
- Check software integrity.
- Document unresolved risks.

## 12. Security Updates

Security updates should be tested before distribution where practical.

Release information should explain:

- The affected component.
- The security issue.
- The affected versions.
- The corrected versions.
- Required user actions.

## 13. Security Advisories

The project may publish security advisories through official GitHub security advisories or another documented project channel.

Sensitive technical information should be handled carefully to avoid exposing users to unnecessary risk.

## 14. Security Research

VELCORA welcomes responsible security research that helps improve the operating system.

Research must remain within lawful and authorised testing boundaries.

Researchers must not use vulnerabilities to access systems or data without permission.

## 15. Security Policy Changes

This policy may be updated as the project develops.

Changes should be documented and approved according to the project governance process.

## 16. Final Statement

VELCORA Linux takes security seriously.

The project aims to maintain a responsible vulnerability reporting process, improve system security continuously and protect the integrity of the operating system and its users.