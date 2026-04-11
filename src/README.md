# AgentCon Workshop Workspace

This directory is the attendee workspace copied into the Web IDE image.

## Stage Order

1. Run `notebooks/01_os_level_rescue.ipynb`.
2. If you want Stage 02 to show direct host execution without kernel blocking, delete the `block-service-account-token` policy created in Stage 01 before continuing.
3. Run `notebooks/02_secure_compute.ipynb`.
4. Run `notebooks/03_mtls_authz.ipynb`.
5. Wait for the trainer to delete the shared `istio-system/workshop-open-egress` entry.
6. Run `notebooks/04_network_dlp.ipynb`.

## Notes

- The Web IDE pod is also the agent runtime.
- The notebooks now create their own stage-specific policies and service entries directly from notebook cells.
- LLM access goes through the shared `llm-gateway` service, not direct tenant egress to Vertex.
- The shared `llm-gateway` uses GKE Workload Identity to call Vertex on behalf of all attendees.
- The workspace uses the system Python runtime with packages preinstalled from `requirements.txt`.
- The terminal defaults to `zsh` with completion, autosuggestions, syntax highlighting, and a simple prompt.
- The trainer manages the shared early-demo egress entry in `istio-system`.
- Attendees add their own namespaced `ServiceEntry` later in the workshop.
