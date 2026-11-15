# VELCORA Linux

VELCORA is a Debian-based Linux operating system focused on Cloud Administration.

## Project Objectives

- Provide a dedicated Cloud Administration Linux environment.
- Build on a Debian foundation.
- Provide an Xfce desktop experience.
- Develop a consistent VELCORA boot experience.
- Include appropriate system administration tools.
- Prioritise security, reliability and maintainability.
- Support transparent community development.

## Project Status

Development: 0.1.0-dev

VELCORA is currently under development and is not yet a stable release.

## Download and try it

Prebuilt live ISOs are published on the
[releases page](https://github.com/R3N3MM/Velcora-Linux/releases).

GitHub caps a release asset at 2 GiB, so each ISO is split into two parts.
Download the parts, join them, and verify the checksum:

```sh
cat velcora-0.1.0-dev-amd64.iso.part* > velcora-0.1.0-dev-amd64.iso
sha256sum -c velcora-0.1.0-dev-amd64.iso.sha256
```

Boot the resulting ISO in a virtual machine or write it to a USB drive.
VirtualBox instructions are in
[build/README.md](build/README.md#running-in-oracle-virtualbox).

## Repository Structure

- branding/: Official visual identity and assets.
- build/: Operating system build configuration and scripts.
- debian/: Debian system integration.
- desktop/: Xfce desktop configuration.
- boot/: Bootloader, initramfs and Plymouth configuration.
- packages/: Selected VELCORA software packages.
- cloud/: Cloud Administration functionality.
- infrastructure/: Core system infrastructure.
- repository/: Architecture and governance.
- testing/: Quality assurance and testing.
- documentation/: User and developer documentation.
- scripts/: Development and maintenance scripts.

## Contributions

See CONTRIBUTING.md for contribution requirements.

## Licence

The project licence is pending approval.
