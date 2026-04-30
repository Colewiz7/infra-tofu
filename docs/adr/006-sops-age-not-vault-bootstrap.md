# ADR-006: SOPS + Age For Bootstrap Secrets, OpenBao For Runtime Secrets

## Status
Accepted

## Context
Secrets need to live somewhere. The chicken-and-egg problem: a runtime secret store like Vault or OpenBao needs to be deployed before workloads can fetch secrets, but the operator deploying it needs *its* secrets (database credentials, unseal key) from somewhere first.

## Decision
Two-tier secret management:
1. **Bootstrap tier**: a single SOPS-age-encrypted file in Git holds the OpenBao unseal key and root token. The age private key is in Bitwarden, never in Git.
2. **Runtime tier**: OpenBao deployed to k3s. All workload secrets flow from OpenBao through External Secrets Operator into Kubernetes Secrets at pod creation time.

## Consequences
- ✅ Plaintext secrets never enter Git or any disk we don't control.
- ✅ Recovery from total laptop loss is straightforward: restore age key from Bitwarden, decrypt the bootstrap file, unseal OpenBao.
- ✅ Workload code references Kubernetes Secrets (idiomatic), not Vault SDK calls (lock-in).
- ⚠️ OpenBao itself is deployed via Helm with hardcoded admin credentials in the bootstrap manifest, then immediately rotated post-bootstrap. This is the brittle window.
- ⚠️ Two tools to teach interviewers (SOPS and OpenBao). Worth it; the split is the point.

## Alternatives considered
- **Sealed Secrets only**: simpler, no runtime secret store, but everything ends up in Git encrypted to one keypair. Rotating the keypair is painful.
- **HashiCorp Vault**: same architecture as OpenBao, but BSL-licensed. OpenBao is the FOSS fork.
- **External Secrets + cloud KMS**: viable but introduces cloud dependency for runtime decryption. Want the platform to survive losing R2.

## References
- [SOPS age key provider](https://github.com/getsops/sops#encrypting-using-age)
- [OpenBao docs](https://openbao.org/docs/)
- [External Secrets Operator](https://external-secrets.io/)
