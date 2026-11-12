# Contributing to VELCORA Linux

Thank you for your interest in contributing to VELCORA Linux.

VELCORA is a Debian-based Linux operating system focused on Cloud Administration.

The project welcomes contributions from developers, Linux users, students, administrators, security researchers, testers, documentation writers and designers.

This document explains how to contribute safely and effectively.

## 1. Before Contributing

Before making changes:

1. Read the project README.md.
2. Review the repository architecture.
3. Read the CODE_OF_CONDUCT.md.
4. Read the SECURITY.md.
5. Check existing GitHub Issues and Discussions.
6. Confirm that your proposed contribution fits the purpose of VELCORA.

For major changes, discuss the proposal with the maintainers before implementation.

## 2. Ways to Contribute

You can contribute through:

### Software Development

- Fixing bugs.
- Improving existing functionality.
- Developing new features.
- Improving system configuration.
- Writing scripts.
- Improving automation.
- Adding tests.

### Cloud Administration

- Improving administration workflows.
- Developing relevant utilities.
- Improving configuration procedures.
- Writing administration documentation.
- Testing supported functionality.

### Security

- Reviewing system configurations.
- Identifying security weaknesses.
- Improving defensive controls.
- Reviewing dependencies.
- Improving security documentation.

Security vulnerabilities must be reported privately according to SECURITY.md.

### Documentation

- Writing installation instructions.
- Improving administrator guides.
- Correcting errors.
- Adding troubleshooting procedures.
- Improving technical explanations.
- Updating outdated information.

### Testing

- Testing installation images.
- Testing system updates.
- Checking hardware compatibility.
- Reporting bugs.
- Testing system recovery.
- Verifying new features.

### Branding and Design

- Improving logos and icons.
- Creating wallpapers.
- Improving interface layouts.
- Creating visual assets.
- Improving boot presentation.

Design submissions must follow the project's branding and asset requirements.

## 3. Repository Setup

Fork the official VELCORA repository to your GitHub account.

Clone your fork:

```bash
git clone YOUR_FORK_URL
```

Enter the repository:

```bash
cd "Velcora Linux"
```

Configure the original repository as the upstream remote:

```bash
git remote add upstream OFFICIAL_REPOSITORY_URL
```

Replace the example URLs with the actual repository addresses.

## 4. Branching Standards

Create a separate branch for each contribution.

Recommended naming conventions:

```text
feature/description
fix/description
docs/description
security/description
test/description
branding/description
```

Examples:

```text
feature/cloud-admin-dashboard
fix/boot-configuration
docs/update-installation-guide
test/hardware-compatibility
```

Do not develop unrelated changes in the same branch.

## 5. Commit Message Standards

Commit messages should clearly explain the purpose of a change.

Recommended format:

```text
type: short description
```

Examples:

```text
feat: add cloud administration utility
fix: correct boot configuration
docs: update installation instructions
test: add package validation checks
security: improve service permissions
```

Avoid vague messages such as:

```text
updates
changes
fixed stuff
new files
```

## 6. Coding Standards

Contributors must:

- Follow the existing project architecture.
- Write readable and maintainable code.
- Use meaningful file and variable names.
- Avoid unnecessary dependencies.
- Validate user input.
- Handle errors appropriately.
- Avoid unnecessary root permissions.
- Document important functionality.
- Avoid introducing unrelated changes.

Code must be suitable for long-term maintenance.

## 7. Security Requirements

Security is a core VELCORA development requirement.

Contributors must:

- Never commit passwords or credentials.
- Never commit private keys or authentication tokens.
- Avoid unsafe command execution.
- Validate external input.
- Use appropriate file permissions.
- Avoid unnecessary administrative privileges.
- Review dependencies before introducing them.
- Follow the project's security reporting procedures.

Changes affecting authentication, permissions, networking, boot, package management or system services require additional technical review.

## 8. Testing Requirements

Before submitting a contribution, perform the relevant tests.

Depending on the change, this may include:

- Installation testing.
- Boot testing.
- Functional testing.
- Package validation.
- Security testing.
- Hardware compatibility testing.
- Regression testing.

Document the tests performed and their results.

Do not claim that a feature has been tested if it has not been tested.

## 9. Documentation Requirements

Documentation must be updated whenever a contribution changes:

- User functionality.
- Installation procedures.
- Configuration.
- System administration.
- Dependencies.
- Security behaviour.
- Development procedures.

Documentation should be clear and understandable.

## 10. Pull Request Procedure

When your contribution is ready:

1. Push your branch to your fork.
2. Open a pull request against the appropriate official repository branch.
3. Explain the purpose of the change.
4. Reference the related issue where applicable.
5. Describe the implementation.
6. List the tests performed.
7. Identify known limitations.
8. Include screenshots or logs where useful.

Maintainers may request changes before approving the contribution.

## 11. Review and Approval

Submitting a pull request does not guarantee that it will be merged.

Maintainers will review contributions for:

- Technical correctness.
- Security.
- Compatibility.
- Project architecture.
- Code quality.
- Documentation.
- Testing results.
- Licensing requirements.

Only authorised maintainers may merge changes into protected branches.

## 12. Licensing

By submitting a contribution, you confirm that:

- You have the right to submit the material.
- You have identified applicable third-party licences.
- Your contribution does not knowingly violate another person's rights.
- You agree to the project's contribution licensing terms.

Original VELCORA project code is intended to use the MIT License unless a component has a separately documented licence.

Third-party materials retain their own licensing requirements.

## 13. Reporting Problems

Use GitHub Issues for normal bugs, feature requests and documentation problems.

Do not publish sensitive security vulnerabilities in public issues.

Follow SECURITY.md for security reporting.

## 14. Recognition

VELCORA values community contributions.

Meaningful contributions may be recognised in:

- Release notes.
- Contributor lists.
- Project documentation.
- Community announcements.

## 15. Final Requirements

Every contribution must support the purpose of VELCORA Linux.

The project prioritises security, reliability, maintainability, clear documentation and responsible development.

Thank you for helping build VELCORA Linux.