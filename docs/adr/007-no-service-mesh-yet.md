# ADR-007: No Service Mesh On Single-Node Cluster

## Status
Accepted (revisit when adding a second node)

## Context
Service meshes (Linkerd, Istio Ambient, Cilium Service Mesh) provide mTLS between pods, traffic policies, and observability. They're a clear win at scale. The question is whether they earn their keep on a single-node, single-tenant homelab.

## Decision
Skip service mesh installation. Achieve the underlying goals through other layers: WireGuard (Cilium native, will encrypt inter-node when a second node joins), Authentik forward-auth at ingress for L7 authz, Hubble for L7 flow observability, Kyverno admission for policy.

## Consequences
- ✅ Less complexity, smaller blast radius, easier troubleshooting.
- ✅ The capabilities a mesh would add are already covered by other layers, with the exception of pod-to-pod mTLS (which is moot on a single node).
- ⚠️ When a second node joins, this decision needs revisiting. Pod-to-pod traffic across nodes will travel over WireGuard (encrypted), but identity-based east-west authz still needs something.
- ⚠️ The interview answer "I haven't deployed a mesh" sounds like a gap unless framed correctly. Frame: "I evaluated Linkerd and Istio Ambient. On one node with WireGuard already encrypting inter-node traffic and Authentik enforcing L7 authz at ingress, a mesh adds blast radius without adding capability. I'd revisit at multi-node and pick Linkerd for simplicity or Cilium Service Mesh to stay in one dataplane."

## Alternatives considered
- **Linkerd**: lightest mesh, Rust-based proxy, excellent UX. Best mesh choice when one is needed.
- **Istio Ambient**: ztunnel architecture is compelling, no per-pod sidecar overhead. Heaviest control plane.
- **Cilium Service Mesh (sidecarless)**: stays in eBPF, no separate dataplane. Best fit if the project ever needs a mesh.

## References
- [Linkerd vs Istio Ambient (CNCF blog)](https://www.cncf.io/blog/2024/12/03/service-mesh-comparison-2024/)
- [Cilium Service Mesh](https://docs.cilium.io/en/stable/network/servicemesh/)
