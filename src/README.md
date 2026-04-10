# AgentCon Workshop Workspace

This directory is the attendee workspace copied into the Web IDE image.

## Stage Order

1. Run `notebooks/01_01_vulnerable.ipynb`.
2. Apply `manifests/02_01_block_sa_token.yaml`.
3. Run `notebooks/02_02_secure_compute.ipynb`.
4. Apply `manifests/03_01_allow_internal_db.yaml`.
5. Run `notebooks/03_02_internal_db_authz.ipynb`.
6. Wait for the trainer to delete the shared `istio-system/workshop-open-egress` entry.
7. Apply `manifests/04_01_allow_agentcon_api.yaml`.
8. Run `notebooks/04_02_test_egress.ipynb`.

Example apply commands:

- `kubectl apply -f manifests/02_01_block_sa_token.yaml`
- `kubectl apply -f manifests/03_01_allow_internal_db.yaml`
- `kubectl apply -f manifests/04_01_allow_agentcon_api.yaml`

## Notes

- The Web IDE pod is also the agent runtime.
- LLM access goes through the shared `llm-gateway` service, not direct tenant egress to Vertex.
- The shared `llm-gateway` uses GKE Workload Identity to call Vertex on behalf of all attendees.
- The workspace uses the system Python runtime with packages preinstalled from `requirements.txt`.
- The terminal defaults to `zsh` with completion, autosuggestions, syntax highlighting, and a simple prompt.
- The trainer manages the shared early-demo egress entry in `istio-system`.
- Attendees add their own namespaced `ServiceEntry` later in the workshop.
