# ADR-003: Argo CD Over Flux For GitOps Reconciliation

## Status
Accepted

## Context
GitOps has two leading tools in 2026: Argo CD and Flux. Both are CNCF graduated, both production-ready, both reconcile manifests from Git into Kubernetes.

## Decision
Use Argo CD with the app-of-apps + ApplicationSet pattern, monorepo (`homelab-gitops`), Kustomize for own apps and Helm for third-party charts.

## Consequences
- ✅ Argo CD's UI is a live demo asset. Opening it during an interview to show 18 synced apps in topology view is more impactful than text logs.
- ✅ ApplicationSet `git` directory generator eliminates manual app registration: dropping a folder under `apps/` causes Argo to detect and deploy automatically. No direct Flux equivalent.
- ✅ Argo CD appears in roughly 3x more 2026 job listings than Flux (anecdotal but consistent across boards I've checked).
- ⚠️ The Argo CD control plane is heavier than Flux's controllers (~5 pods vs ~3).
- ⚠️ Lock-in: app manifests use the `Application` and `ApplicationSet` CRDs, not portable to Flux without rewrite.

## Alternatives considered
- **Flux v2**: lighter, simpler model, but UI is third-party (Capacitor, Weave GitOps) and feels less polished. The job-listings gap is the deciding factor.
- **Komodo or Portainer + Compose**: would mean staying on Compose, which is the thing I'm migrating away from.

## References
- [Argo CD ApplicationSet docs](https://argo-cd.readthedocs.io/en/stable/operator-manual/applicationset/)
- [Flux v2 vs Argo CD comparison (CNCF)](https://www.cncf.io/blog/2023/04/05/argo-cd-vs-flux/)
