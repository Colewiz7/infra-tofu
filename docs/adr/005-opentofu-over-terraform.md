# ADR-005: OpenTofu Over Terraform For Infrastructure-As-Code

## Status
Accepted

## Context
HashiCorp moved Terraform to the Business Source License in August 2023. The community forked it as OpenTofu, which became a Linux Foundation project and graduated CNCF in April 2025. IBM closed the HashiCorp acquisition in February 2025, with Terraform remaining BSL.

## Decision
Use OpenTofu (`tofu` CLI), pinned to `>= 1.9`. The HCL syntax is identical; the only behavioral difference relevant to this project is OpenTofu's native state and plan encryption, which Terraform lacks.

## Consequences
- ✅ State and plan files encrypted at rest via PBKDF2 + AES-GCM, no third-party tooling.
- ✅ MPL-2.0 license, no BSL asterisk for downstream tooling that wraps tofu.
- ✅ CNCF-graduated as of April 2025, signals long-term governance.
- ⚠️ Hiring managers occasionally still say "Terraform" without realizing the fork. Worth proactively explaining "OpenTofu, the BSL-free fork that's CNCF-graduated."
- ⚠️ Some commercial Terraform-only tools (Terraform Cloud, certain Spacelift integrations) work less smoothly with tofu. None used in this project.

## Alternatives considered
- **Terraform 1.x BSL**: still the market leader by usage. The license question doesn't affect personal use, but it does affect whether OSS tooling around it can stay current.
- **Pulumi**: real-language IaC (TypeScript, Go), very different mental model, smaller community in the homelab/k8s niche.

## References
- [OpenTofu state encryption](https://opentofu.org/docs/language/state/encryption/)
- [CNCF announces OpenTofu graduation](https://www.cncf.io/announcements/2025/04/01/cncf-graduates-opentofu/)
