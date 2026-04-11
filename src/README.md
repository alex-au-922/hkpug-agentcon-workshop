# AgentCon Workshop Workspace

This directory is the attendee workspace copied into each VS Code Web IDE pod.

## Workshop Roadmap

1. Run `notebooks/01_os_level_rescue.ipynb`.
2. Run the cleanup cell at the end of Stage 01 if you want Stage 02 to demonstrate untrusted host execution again.
3. Run `notebooks/02_secure_compute.ipynb`.
4. Run `notebooks/03_mtls_auth.ipynb`.
5. Before Stage 04, wait for the trainer to remove the shared `istio-system/workshop-open-egress` `ServiceEntry`.
6. Run `notebooks/04_network_dlp.ipynb`.

## What Each Stage Demonstrates

- Stage 01: the indirect prompt injection baseline and kernel-level blocking with KubeArmor.
- Stage 02: zero-trust compute with `pydantic-monty`, the custom Rust sandbox demo.
- Stage 03: keyless internal access with Istio Ambient Mesh, mTLS, and `AuthorizationPolicy`.
- Stage 04: Layer 7 egress control with a namespaced `ServiceEntry` that allows `api.agentcon.local` while `evil.com` stays blocked.

## Notes

- The Web IDE pod is also the agent runtime.
- Stage 01, Stage 03, and Stage 04 now include cleanup cells for the namespaced resources they create.
- LLM access goes through the shared `llm-gateway` service, not direct tenant egress to Vertex.
- The shared `llm-gateway` uses GKE Workload Identity to call Vertex on behalf of all attendees.
- The workspace uses the system Python runtime with packages preinstalled from `requirements.txt`.
- The terminal defaults to `zsh` with completion, autosuggestions, syntax highlighting, and a simple prompt.
- The trainer still controls the shared early-demo egress entry in `istio-system` before Stage 04.
- The live token-blocking path is `/run/secrets/kubernetes.io/serviceaccount/token`, even though some slide examples still show `/var/run/...`.
