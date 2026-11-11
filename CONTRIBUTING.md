# Contributing to PALISADE Linux

Thank you for your interest in contributing to PALISADE Linux.

PALISADE is an independent Debian-based operating system focused exclusively on cloud administration and infrastructure management.

Contributions should improve the reliability, usability, security, maintainability and functionality of the distribution.

This document establishes the contribution standards and development expectations for the project.

---

## 1. Project Philosophy

All contributions must align with the primary purpose of PALISADE Linux.

The project focuses on:

- Cloud administration.
- Infrastructure management.
- Infrastructure as Code.
- Cloud automation.
- Container management.
- Infrastructure monitoring.
- Networking and system administration.
- Cloud storage and database management.
- Infrastructure security.

Contributions unrelated to these areas may be rejected.

## 2. Repository Structure

Contributors must place files in the appropriate project directories.

| Directory | Contribution Area |
|---|---|
| branding/ | Visual identity and artwork |
| build/ | ISO building and automation |
| debian/ | Debian integration |
| desktop/ | Xfce and desktop configuration |
| boot/ | GRUB and Plymouth |
| packages/ | Debian package development |
| cloud/ | Cloud administration |
| infrastructure/ | Infrastructure management |
| repository/ | Package repository management |
| testing/ | Testing and validation |
| documentation/ | Technical documentation |
| scripts/ | Development automation |

Do not place unrelated files in the project root.

## 3. Code Quality

All contributions must follow these requirements:

1. Use clear and descriptive names.
2. Keep code modular and maintainable.
3. Avoid unnecessary dependencies.
4. Include comments where functionality is not immediately obvious.
5. Handle errors appropriately.
6. Avoid hardcoded credentials and sensitive information.
7. Follow established project conventions.
8. Test changes before submitting them.

Do not introduce unnecessary complexity.

## 4. Debian Compatibility

PALISADE is built on the Debian ecosystem.

Contributions involving packages or system configuration must:

- Respect Debian packaging standards.
- Maintain compatibility with the selected Debian Testing foundation.
- Avoid unnecessary modifications to core Debian components.
- Document additional dependencies.
- Verify package installation and removal.
- Test upgrade behaviour where applicable.

Changes to the Debian foundation must be reviewed before implementation.

## 5. Cloud Tool Contributions

New cloud administration tools must have a clear purpose.

Contributors should provide:

- Tool name.
- Official project website.
- Intended functionality.
- Installation method.
- Dependencies.
- Licence information.
- Maintenance status.
- Compatibility information.
- Security considerations.

Tools should be evaluated before inclusion in the default installation.

## 6. Security Requirements

Security is a mandatory consideration.

Contributors must never:

- Commit API keys or passwords.
- Include private authentication credentials.
- Introduce undocumented remote access.
- Disable security protections without justification.
- Introduce unverified third-party installation scripts.
- Include software with known unresolved critical vulnerabilities without explicit review.

Security-related changes must include appropriate testing and documentation.

## 7. Documentation

New functionality must be documented.

Documentation should explain:

- What the component does.
- Why it is included.
- How it works.
- How to install or configure it.
- Dependencies and requirements.
- Known limitations.
- Troubleshooting procedures.

Documentation should be understandable to administrators with different experience levels.

## 8. Testing

Contributors must test their changes before submitting them.

Depending on the contribution, testing may include:

- Package installation.
- Package removal.
- Dependency validation.
- ISO build validation.
- Boot testing.
- Desktop functionality.
- Cloud CLI functionality.
- Network connectivity.
- Security configuration.
- Upgrade compatibility.

Do not describe untested functionality as verified.

## 9. Submitting Contributions

Before submitting a contribution:

1. Review the existing repository structure.
2. Check whether the functionality already exists.
3. Create a separate development branch.
4. Implement the changes in the appropriate directory.
5. Test the implementation.
6. Update relevant documentation.
7. Review your changes for credentials and sensitive information.
8. Submit a pull request for review.

## 10. Pull Request Requirements

Pull requests should include:

- A clear title.
- A description of the changes.
- The reason for the contribution.
- Affected components.
- Testing performed.
- Known limitations.
- Relevant documentation updates.

Large architectural changes should be discussed before implementation.

## 11. Third-Party Software

Third-party projects must retain their original copyright notices and licensing information.

Contributors must not copy proprietary software or artwork without permission.

Any third-party software included in PALISADE must be reviewed for compatibility and redistribution requirements.

## 12. Branding

PALISADE has an independent visual identity.

Contributions involving logos, artwork, wallpapers, themes or boot animations must follow the official PALISADE branding guidelines.

Do not replace official branding without project approval.

## 13. Code of Conduct

Contributors are expected to communicate professionally and respectfully.

Harassment, discrimination, deliberate disruption and malicious contributions are not acceptable.

## 14. Final Review

All contributions are subject to project review.

Acceptance depends on:

- Technical quality.
- Debian compatibility.
- Security.
- Maintainability.
- Project relevance.
- Documentation quality.

Submitting a contribution does not guarantee acceptance.

---

**PALISADE Linux**  
Cloud Administration & Infrastructure

*Building a dedicated operating system for modern cloud infrastructure.*