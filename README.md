# Jailbreaking the Ghost: Anatomy of a Secure Agent

This repository contains the slides, attendee workspace, and OpenTofu infrastructure for the Hong Kong Python User Group workshop run by [Alex Au](https://www.linkedin.com/in/alex-au-cloudeng) and [Henry Wong](https://www.linkedin.com/in/wyhwong/) on 11 April 2026.

## Workshop Thesis

**Don't trust the agent. Trust the infrastructure.**

The workshop treats LLM-generated code as untrusted by default. Instead of relying on prompt scanning, it assumes the agent can and will fail, then uses infrastructure controls to contain the blast radius.

## Threat Model

The threat is **Indirect Prompt Injection**, not a user typing an obvious jailbreak prompt.

1. The user asks a benign question such as "Can you summarize the news on this website?"
2. The agent legitimately fetches external content from `api.agentcon.local/news`.
3. The fetched content hides malicious instructions that tell the agent to read the Kubernetes service account token and exfiltrate it.
4. The agent complies, generates Python, and executes it with `exec()`.
5. We do not try to sanitize the internet. We let the agent fail and watch the platform controls catch the fallout.

## Four Principles

1. **Shift Left to Layer 0:** Kernel-level enforcement with KubeArmor and BPF-LSM blocks dangerous file access before Python ever gets a chance to handle it.
2. **Zero Trust Compute:** Generated code runs with default-deny privileges. The workshop demo uses `pydantic-monty`, a custom Rust VM, while the broader principle also applies to WASM and other sandboxing approaches.
3. **Inherence over Possession:** Instead of handing the workload a credential to steal, the platform uses workload identity and mTLS to prove what the workload is.
4. **Exfiltration Prevention:** Outbound access is narrowed to an allow-list. Legitimate dependencies stay reachable while exfiltration paths are dropped at the network layer.

## Workshop Roadmap

1. `src/notebooks/01_os_level_rescue.ipynb`: kernel-level protection with KubeArmor.
2. `src/notebooks/02_secure_compute.ipynb`: default-deny execution with the Rust sandbox demo.
3. `src/notebooks/03_mtls_auth.ipynb`: keyless internal access with Istio Ambient Mesh and `AuthorizationPolicy`.
4. `src/notebooks/04_network_dlp.ipynb`: Layer 7 egress control with a namespaced `ServiceEntry`.

## Repository Layout

- `src/`: the attendee workspace copied into each VS Code pod.
- `opentofu/`: the infrastructure stack for GKE, Gateway API, Istio Ambient, KubeArmor, and the per-user lab environments.

## Kubernetes in This Workshop

Kubernetes is the substrate, not the lesson. It gives the workshop realistic controls to demonstrate:

- per-user namespaces and Web IDEs
- ambient service mesh identity via `ztunnel`
- kernel-level enforcement with KubeArmor
- network-level allow-listing and ingress/egress control

## Implementation Note

Some slide examples still show `/var/run/secrets/kubernetes.io/serviceaccount/token`. The live workshop materials use `/run/secrets/kubernetes.io/serviceaccount/token` for the token-blocking path because `/var/run` is a symlink and KubeArmor path matching is stricter at the real path.
