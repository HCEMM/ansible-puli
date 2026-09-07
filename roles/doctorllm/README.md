# Useful Commands:

During the current live-production development phase, prefer commands such as:

```bash
ansible-playbook -i inventory/hosts puli.yml --syntax-check
```

and:

```bash
ansible-playbook \
  -i inventory/hosts \
  puli.yml \
  --check \
  --diff \
  --tags doctorllm
```

## Manual submission of the DoctorLLM vLLM job

Login to the cluster as doctorllm user:

```bash
sbatch ~/serve-qwen3-14b.sbatch
```

## Useful commands on `doctorllm1`:

```bash
cd /etc/doctorllm
docker compose ps
docker compose logs --tail=100 open-webui
```

Restart Open WebUI only:

```bash
cd /etc/doctorllm
docker compose restart open-webui
```

This does not restart vLLM.

----

# DoctorLLM Ansible Role

This role contains the reproducible deployment definition for the DoctorLLM service on the PULI infrastructure.

> **Production safety:** DoctorLLM is currently live. While the role is being aligned with the running system, use Ansible only for read-only validation such as `--check`, `--diff`, syntax checks, and task listing. Do not apply isolated DoctorLLM tasks to production merely to remove drift.

## Current Architecture

```text
Users
  |
  | HTTPS
  v
doctorllm.hcemm.eu
  |
  | Nginx / TLS
  | (managed outside this role)
  v
doctorllm1
10.0.150.214
Open WebUI :3000
  |
  | OpenAI-compatible API
  v
scc-gpu01-10G
10.0.150.140
vLLM :8000
  |
  v
Qwen3-14B
```

Authentication is provided through FreeIPA/LDAP.

The model, Python/vLLM runtime, caches, job data, configuration, and logs are stored on the shared DoctorLLM NFS dataset mounted as `/doctorllm` on the compute/GPU environment.

## Responsibility Boundaries

The current design deliberately separates operating-system provisioning from DoctorLLM application configuration.

| Responsibility | Current owner |
|---|---|
| Open WebUI VM configuration | `roles/doctorllm` on `doctorllm_server` |
| FreeIPA LDAP bind object and `grp_doctorllm` access group | `roles/doctorllm` on `ldap_server` |
| POSIX user `doctorllm` | normal FreeIPA/user-management workflow |


The `doctorllm_gpu` inventory group may still be used as inventory data for resolving the current backend address. It is not intended to make GPU nodes direct DoctorLLM play targets.

## Shared Storage

Storage source:

```text
10.0.150.147:/mnt/MirrorHDD/doctorllm
```

Compute/GPU mount point:

```text
/doctorllm
```

Expected layout:

```text
/doctorllm/
├── apps/
├── cache/
├── config/
├── jobs/
├── logs/
├── models/
└── tmp/
```


### NFS and `root_squash`

Do not interpret `Permission denied` as root on an NFS client as proof that the dataset is broken. Root may be squashed by the NFS server.

On nodes that do not resolve the FreeIPA `doctorllm` account through NSS/SSSD, validate access using the numeric identity instead of `runuser`:

```bash
setpriv --reuid=1001 --regid=200000 --clear-groups \
  test -r /doctorllm/models/Qwen3-14B/config.json
```

Example write test:

```bash
setpriv --reuid=1001 --regid=200000 --clear-groups \
  sh -c 'touch /doctorllm/tmp/.doctorllm-write-test && rm -f /doctorllm/tmp/.doctorllm-write-test'
```

Do not weaken NFS permissions to work around `root_squash`.

## Runtime Versions

The runtime is intentionally pinned.

Current reference versions:

```text
uv                  0.12.1
Python              3.12.13
vLLM                0.26.0
torch               2.11.0+cu130
transformers        5.14.1
tokenizers          0.22.2
flashinfer-python   0.6.14
triton              3.6.0
numpy               2.3.5
safetensors         0.8.0
huggingface-hub     1.26.0
```

The complete Python environment is frozen in:

```text
roles/doctorllm/files/vllm-requirements.txt
```

Treat the pinned Python/CUDA/PyTorch/vLLM dependency set as one tested runtime unit. Do not update individual packages in production without a compatibility test.

## Model

```text
Repository: Qwen/Qwen3-14B
Local path: /doctorllm/models/Qwen3-14B
Served model name: qwen3-14b
```

Model presence can be checked with:

```text
/doctorllm/models/Qwen3-14B/config.json
```

## Slurm Job Templates

The role currently contains the following templates:

```text
templates/bootstrap-doctorllm-runtime.sbatch.j2
templates/download-qwen3-14b.sbatch.j2
templates/serve-qwen3-14b.sbatch.j2
```

These templates are currently **reference/rebuild definitions only**.

At this stage Ansible does **not**:

- render these templates onto the login node;
- submit them to Slurm;
- wait for them to finish/start;
- restart vLLM automatically;
- manage a persistent Slurm service-job lifecycle.

This is intentional. Job submission remains manual while the GPU allocation architecture is still being evaluated.

### Runtime bootstrap template

The bootstrap job is intended to run on the CPU partition and prepare application-owned runtime data under `/doctorllm`, including:

- pinned `uv`;
- pinned Python;
- vLLM virtual environment;
- pinned requirements;
- the `apps/vllm/current` symlink.

It does not install operating-system RPMs, create users, or mount NFS.

### Model download template

The model download job is intended to run on the CPU partition. It does not require a GPU.

### vLLM service template

The current vLLM service definition uses:

```text
Account:    grp_hcemm
QoS:        normal
Partition:  gpu
Node:       scc-gpu01-10g
GRES:       gpu:1
Max time:   10 days
```

GPU1 is currently pinned because the Open WebUI backend is configured to reach the vLLM endpoint on GPU1. This is a node preference/pin only; it is **not** a reservation and does not make the GPU exclusive to DoctorLLM.

### Manual model download

The repository contains a model-download template for rebuild/recovery. Because templates are not yet automatically rendered to a submit host, prepare a submit-ready script manually before using it.

The intended Slurm policy is:

```text
Account:    grp_hcemm
QoS:        normal
Partition:  cpu
```

After a download, verify model presence from a host where `/doctorllm` is mounted:

```bash
setpriv --reuid=1001 --regid=200000 --clear-groups \
  test -r /doctorllm/models/Qwen3-14B/config.json
```

## Open WebUI

The role currently manages the DoctorLLM application VM, including:

- base packages;
- Docker repository/packages;
- Docker service;
- `/etc/doctorllm` configuration;
- persistent Open WebUI data directory;
- FreeIPA CA certificate;
- Open WebUI environment file;
- Docker Compose definition.

## FreeIPA / LDAP

The DoctorLLM role manages the application LDAP bind object:

```text
uid=doctorllm-bind,cn=sysaccounts,cn=etc,<LDAP base DN>
```

and the non-POSIX Open WebUI access group:

```text
grp_doctorllm
```

These are separate from the POSIX operational user `doctorllm`.

The POSIX user belongs in the normal FreeIPA/users configuration, not in a GPU-local DoctorLLM task.

The FreeIPA CA certificate is copied to:

```text
/opt/doctorllm/certs/freeipa-ca.crt
```

and mounted into the Open WebUI container.

Open WebUI persists administrator configuration in its database. Environment variables are therefore not guaranteed to override an already-persisted OpenAI-compatible connection. See `MANUALCONFIGURATION.md` for post-deployment checks.

## Backend Validation

The vLLM lifecycle is manual, so Open WebUI deployment should not inherently depend on vLLM already being running.

`doctorllm_validate_backend` is intended to control optional validation of the backend/model after the service is available:

```yaml
doctorllm_validate_backend: false
```

When validation is enabled, the expected endpoint is:

```text
http://10.0.150.140:8000/v1/models
```

and the expected model ID is:

```text
qwen3-14b
```

## Future Automation

The current manual split is temporary. A future implementation should automate the workflow only after the GPU/service-lifecycle design is finalized.

A reasonable future sequence is:

1. **Render job files on a real submit host.** Use Ansible to render the `.sbatch.j2` templates into `/home/doctorllm/` on a login/submit node instead of assuming `/doctorllm` is mounted there.
2. **Stage runtime inputs on shared storage.** Ensure `vllm-requirements.txt` and required configuration are present under `/doctorllm/config` using a host that legitimately mounts the dataset.
3. **Bootstrap idempotently.** Query whether the pinned uv/Python/vLLM runtime already exists before submitting the bootstrap job.
4. **Download the model idempotently.** Check `config.json` and active download jobs before submitting a new download job.
5. **Manage the vLLM lifecycle explicitly.** Before submission, query Slurm for an existing `doctorllm-qwen3` job and avoid duplicates. If automation is enabled, wait for the backend health endpoint rather than assuming job submission means service readiness.
6. **Synchronize backend discovery.** If the service is allowed to run on either GPU node, Open WebUI must discover/update the actual vLLM endpoint automatically. Until then, GPU1 remains pinned.
7. **Re-evaluate Slurm for a dedicated GPU.** If DoctorLLM later receives a dedicated GPU, a long-running Slurm service job may no longer be the best lifecycle mechanism. In that architecture the service could move to image/system service management instead.

Automatic job submission must not be introduced while the current policy says submission is manual.

## Troubleshooting

### vLLM job is pending

```bash
squeue -u doctorllm \
  -o "%.18i %.18j %.10T %.20R"
```

Common causes include:

- GPU1 is already allocated;
- the node is drained/down;
- resource constraints;
- Slurm association/QoS problems.

Waiting for GPU1 can be normal because DoctorLLM currently has no reservation.

### Verify Slurm identity/accounting

On the Slurm controller:

```bash
sacctmgr -nP show assoc where user=doctorllm \
  format=Cluster,Account,User,Partition,QOS,DefaultQOS
```

The operational identity should resolve to UID `1001` in Slurm's association manager:

```bash
scontrol show assoc_mgr users=doctorllm | grep 'UserName=doctorllm'
```

### Verify runtime without a GPU

On a host where `/doctorllm` is mounted, the Python/package installation can be validated using the numeric identity:

```bash
setpriv --reuid=1001 --regid=200000 --clear-groups \
  /doctorllm/apps/vllm/current/bin/python --version
```

Check the installed vLLM package version without triggering GPU device detection:

```bash
setpriv --reuid=1001 --regid=200000 --clear-groups \
  /doctorllm/apps/vllm/current/bin/python -c \
  'import importlib.metadata as m; print(m.version("vllm"))'
```

Do not use `vllm --version` on a CPU-only node as a runtime-health test because vLLM may attempt device detection.

### Open WebUI points to an old backend

Changing:

```text
/etc/doctorllm/open-webui.env
```

may not change an already-persisted Open WebUI connection.

Verify the effective connection under Open WebUI Admin Settings → Connections. Do not manipulate `webui.db` directly from Ansible.
