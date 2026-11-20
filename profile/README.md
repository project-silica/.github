# Project Silica

![A fused silica prism refracting a narrow beam of light on graphite.](https://raw.githubusercontent.com/project-silica/.github/main/profile/silica-prism.png)

Silica is a clean-sheet operating system project built around a small Rust microkernel. Its design uses capabilities to control access to resources and runs drivers and core services in userspace.

The project is preparing its first milestone: a reproducible build and test harness and a bootable kernel stub.

## Repositories

- [workshop](https://github.com/project-silica/workshop) — the project root: specification (architecture, milestones, test strategy), workspace checkout and build instructions
- [idl](https://github.com/project-silica/idl) — interface definitions and language bindings
- [kernel](https://github.com/project-silica/kernel) — microkernel and boot code
- [os](https://github.com/project-silica/os) — system images, integration, and verification tools
