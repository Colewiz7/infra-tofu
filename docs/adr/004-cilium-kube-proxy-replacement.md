# ADR-004: Cilium With kube-proxy Replacement

## Status
Accepted

## Context
k3s ships with Flannel as the default CNI plus kube-proxy for service routing. Both work fine. Cilium is an alternative CNI based on eBPF that can replace not just Flannel but also kube-proxy, kube-router, and ServiceLB in one install.

## Decision
Disable Flannel, kube-proxy, network-policy, and ServiceLB at k3s install time. Install Cilium 1.17+ with `kubeProxyReplacement=true`, `l2announcements=true`, and Hubble enabled. Disable network policies in k3s itself; Cilium handles them.

## Consequences
- ✅ One install replaces four components. The interview answer "I run a single eBPF dataplane for CNI, kube-proxy replacement, L2 announcements, and observability" is one sentence with deep substance.
- ✅ Hubble UI gives free L3-L7 flow observability for the cluster, deployable as a demo.
- ✅ Network policies are enforced in eBPF, faster than iptables rules.
- ⚠️ Cilium operator is heavier than Flannel. With a single node, set `operator.replicas: 1` or the second pod pends forever on anti-affinity.
- ⚠️ With `--disable-kube-proxy`, the Cilium Helm value `k8sServiceHost` must point at the node's real IP, not the in-cluster service VIP. Easy to miss.

## Alternatives considered
- **Flannel + kube-proxy (default)**: simplest, smallest interview answer.
- **Calico**: mature alternative, good NetworkPolicy story, but doesn't include kube-proxy replacement and Hubble-like observability is a separate install.

## References
- [Cilium kube-proxy replacement](https://docs.cilium.io/en/stable/network/kubernetes/kubeproxy-free/)
- [Cilium Hubble](https://docs.cilium.io/en/stable/observability/hubble/)
