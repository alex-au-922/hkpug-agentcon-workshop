# Workshop Infrastructure Plan

## Summary

The current `opentofu/` stack is already a strong base. It is not a greenfield rebuild from the older MCP workshop pattern.

What already exists:

- GCP project services, VPC, subnet, and GKE Standard cluster.
- Artifact Registry and custom VS Code image build/push.
- Wildcard DNS, certificate manager, global HTTPS load balancer, and Gateway API ingress.
- Per-tenant namespaces and per-tenant VS Code Deployments.
- GKE Workload Identity wiring for the shared `llm-gateway` service account.
- Istio ambient mesh installation.
- KubeArmor installation.

What is still missing is mostly workshop-specific Kubernetes content, not major new cloud infrastructure.

Important design choice: the VS Code pod is also the agent runtime. Attendees run the vulnerable script, the WASM sandboxed script, and any notebooks directly inside the Web IDE pod. That keeps each tenant to two main identities:

- the VS Code or agent pod identity
- the internal protected service identity

## Current Repo Architecture

```text
Internet
  |
  v
GCP Global HTTPS Load Balancer
  |
  v
Gateway API Gateway
  |
  +--> user-00.agentcon-workshop.python.hk --> user-00/vscode Service --> vscode Deployment
  +--> user-01.agentcon-workshop.python.hk --> user-01/vscode Service --> vscode Deployment
  +--> ... active tenants only

GKE Standard Cluster
  |
  +--> istio-system
  |     +--> istiod
  |     +--> ztunnel
  |
  +--> kubearmor
  |     +--> KubeArmor controllers / agents
  |
  +--> user-00 .. user-79 namespaces
        +--> active tenants have `istio.io/dataplane-mode=ambient`
        +--> all tenants have VS Code workspace pods
        +--> workshop workloads are not deployed yet
```

## Target Workshop Architecture

```text
Internet
  |
  v
GCP Global HTTPS Load Balancer
  |
  v
Gateway API Gateway
  |
  v
Per-tenant VS Code Web IDE and agent runtime

GKE Standard Cluster
  |
  +--> KubeArmor
  |     +--> blocks dangerous file/process/network actions at kernel layer
  |
  +--> Istio ambient mesh
  |     +--> ztunnel for workload identity and L4 policy
  |     +--> waypoint proxy if we need deterministic L7 authz/egress behavior
  |
  +--> user-00 namespace
        +--> vscode pod
        |     +--> attendees run scripts and notebooks here
        |     +--> this pod is also the agent runtime and mesh identity
        +--> internal-db pod
        +--> namespaced KubeArmorPolicy examples
        +--> namespaced Istio AuthorizationPolicy examples
        +--> namespaced Istio ServiceEntry examples

Shared or external to the tenant namespace:

- poisoned-news source
- optional attacker-sink
```

## Recommended Diagram For The Workshop

```text
                  +--------------------------------+
                  |  GCP HTTPS Load Balancer       |
                  |  wildcard DNS + TLS            |
                  +----------------+---------------+
                                   |
                                   v
                  +--------------------------------+
                  |  Gateway API Gateway           |
                  +----------------+---------------+
                                   |
             +---------------------+---------------------+
             |                                           |
             v                                           v
   +--------------------+                     +--------------------+
   | user-00 namespace  |                     | user-01..79        |
   | active workshop    |                     | placeholder or      |
   | tenant             |                     | future scale-out    |
   +--------------------+                     +--------------------+
             |
             +--> vscode pod
              |     - kubectl
              |     - workshop files
              |     - Monty / Python deps
              |     - Jupyter support
              |     - Vertex client support
              |     - also acts as the agent runtime
              |
              +--> internal-db pod
              |     - only vscode pod identity allowed
              |
              +--> shared poisoned-news source
              |
              +--> shared optional attacker sink
              |
              +--> KubeArmor
              |     - deny SA token reads
              |
              +--> Istio AuthorizationPolicy
              |     - allow user-xx-vscode-sa to internal-db
              |
              +--> Istio ServiceEntry
                    - allow only approved external host(s)
```

## Delta From The Older MCP Workshop Base

The older Terraform layout is still the right substrate. The important delta is not more raw cloud resources; it is security and exercise wiring inside the cluster.

Keep from the previous pattern:

- GKE Standard.
- Per-tenant namespaces.
- Per-tenant VS Code over HTTPS.
- Artifact Registry image build.
- Wildcard DNS and certificate flow.

Add or change for this workshop:

- Istio ambient mesh for identity and containment.
- KubeArmor for kernel enforcement.
- Namespaced RBAC so tenant `kubectl` is usable.
- Workshop workloads and exercise manifests.
- Treat the VS Code pod as the agent runtime instead of adding a separate agent pod.
- Egress default-deny and allowlisted external hosts.
- Optional waypoint if ambient L7 behavior needs to be explicit and repeatable.

## Missing Infrastructure

### 1. Tenant Kubernetes RBAC

Current blocker: the tenant VS Code service account has no Kubernetes RoleBinding, so `kubectl get pods` and `kubectl apply -f` fail from inside the workspace.

Recommended scope:

- Allow namespaced read access to pods, services, logs, and events.
- Allow namespaced create/update/delete for `KubeArmorPolicy`, `AuthorizationPolicy`, and `ServiceEntry`.
- Keep cluster-scope access denied by default.

Note: `kubectl get ns` can remain forbidden on purpose unless attendee ergonomics matter more than least privilege.

### 2. Workshop Workloads

Still needed for `user-00`:

- Internal protected service.
- Exercise files that run inside the existing VS Code pod.
- Poisoned content source, ideally shared outside the tenant namespace.
- Optional attacker sink for visualizing exfiltration attempts, also preferably shared.

These are the most important missing pieces.

### 3. Egress Story For Ambient

This is the main design decision still open.

Options:

1. Stay on ambient and validate that `ServiceEntry` plus the desired outbound policy gives a clean enough demo.
2. Add a waypoint for `user-00` if you need stronger L7 semantics in ambient.
3. Use sidecar mode only for workshop namespaces if that makes egress behavior simpler to teach.

Recommendation: keep ambient as the platform default, but validate Principle 4 in `user-00` before scaling. If the allowlist demo is not crisp enough, add a waypoint only for the active tenant path.

Recommended egress setup:

- Set mesh egress to `REGISTRY_ONLY`.
- Do not expose direct Vertex AI egress to tenant namespaces.
- Put one shared `llm-gateway` service in `workshop-system` and let that service use Workload Identity to call Vertex.
- Keep one temporary shared `ServiceEntry` in `istio-system` for the early workshop demo hosts.
- At Principle 4, the trainer deletes only the temporary shared entry.
- Attendees then apply their own namespaced `ServiceEntry` for the legitimate host.

### 4. External Host Strategy

You do not need much more cloud infrastructure here.

Simplest options:

1. Host `news.agentcon.local` and `evil.agentcon.local` as in-cluster services exposed through a controlled path.
2. Use one in-cluster poisoned content service and one in-cluster attacker sink, but present them as external domains from the agent's point of view.

This keeps the demo deterministic and avoids depending on real public internet behavior.

Suggested split:

- shared persistent internal service: `llm-gateway.workshop-system.svc.cluster.local`
- shared temporary hosts: `api.agentcon.local` and `evil.com`
- attendee-added host later: `api.agentcon.local` in their own namespace after the shared entry is removed

### 5. Workshop Files In The VS Code Image

The VS Code image is now the main agent runtime, so it should be treated as the workshop host app. It needs:

- the actual exercise files in the workspace under top-level `src/`
- build the workspace virtual environment from `requirements.txt` during image build so the workspace is ready on first login
- Python runtime dependencies for the scripts
- notebook support for the preloaded observation notebook
- a lightweight OpenAI-compatible client path to the shared `llm-gateway`
- YAML and TOML extensions, plus the curated workshop IDE extension set for Python, Jupyter, templates, and agent tools

### 6. Operator UX

Still needed:

- Trainer runbook.
- Attendee instructions.
- Health-check commands for KubeArmor and Istio.
- Scale-up steps from `curr_tenant_num = 1` to the workshop size.

## How Much More Infrastructure Is Needed?

Not much more GCP infrastructure.

This is a moderate Kubernetes delta, not a major platform rebuild:

- No new VPC design is needed.
- No new cluster is needed.
- No new public ingress stack is needed.
- No separate secret system is needed for the workshop path.

What is needed is roughly:

- 1 RBAC file for tenant `kubectl` access.
- 1 internal service workload definition per active tenant.
- 1 shared poisoned-content source and optionally 1 shared attacker sink.
- 3 workshop policy examples.
- 1 decision on ambient-only versus ambient-plus-waypoint for L7 behavior.
- 1 update to the VS Code image or startup flow to include workshop files.
- Trainer and attendee docs.

That means the repo is already close on platform infrastructure. The remaining work is concentrated in the tenant namespace experience and the security demo path.

## Recommended Implementation Order

1. Add tenant namespaced RBAC so `kubectl` works from VS Code.
2. Put the vulnerable script, secure script, and notebook assets into the VS Code workspace image.
3. Deploy `internal-db` into `user-00`.
4. Add one shared poisoned-news source.
5. Add the KubeArmor example and verify the token-read block from the VS Code pod.
6. Add the Istio AuthorizationPolicy example and verify keyless access from the VS Code pod to `internal-db`.
7. Keep persistent shared Vertex egress and temporary shared workshop-open egress in `istio-system`.
8. Validate the Principle 4 flow by deleting the temporary shared entry and having attendees apply their namespaced `ServiceEntry`.
9. If Principle 4 needs cleaner L7 behavior, add a waypoint only for `user-00`.
10. Write the trainer runbook and attendee instructions.
