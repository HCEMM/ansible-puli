# DoctorLLM Open WebUI Post-Deployment Configuration

## Purpose

This document contains the **manual Open WebUI configuration and validation steps** that must be performed after the DoctorLLM infrastructure has been deployed by Ansible.

# 1. Log In as Administrator

Open the DoctorLLM site and log in with the intended administrator account.

---

# 2. Configure / Verify the vLLM Connection

This is the most important post-deployment step.

Open:

```text
Admin Panel
→ Settings
→ Connections
```

Configure or verify the OpenAI-compatible connection.

Expected API Base URL:

```text
http://10.0.150.140:8000/v1
```

Expected backend:

```text
scc-gpu01-10G
```

Expected served model:

```text
qwen3-14b
```

The API key must be the same value used by vLLM:

```text
doctorllm_vllm_api_key
```

Do not write the real API key into this README.

After saving the connection, verify that:

```text
qwen3-14b
```

appears in the Open WebUI model list.

---

# 3. Important: Open WebUI Database Can Override Environment Variables

Open WebUI persists many administrator settings in its database.

Therefore:

```text
/etc/doctorllm/open-webui.env
```

must **not** be assumed to represent the effective configuration of an existing Open WebUI instance.

The effective behavior can be:

```text
Ansible-managed environment variables
        ↓
initial/default configuration
        ↓
Open WebUI persisted database configuration
        ↓
effective runtime configuration
```

This was observed during the GPU migration:

- the environment file still referenced the old GPU backend;
- Open WebUI continued to use the new GPU1 backend;
- the active connection had been persisted in `webui.db`.

Therefore, after every rebuild or restore:

> Always verify the effective backend under Admin → Settings → Connections.

Do not directly manipulate `webui.db` from Ansible.

---

# 4. Verify the Backend Before Troubleshooting Open WebUI

If the model does not appear in Open WebUI, first make sure vLLM itself is healthy.

On GPU1:

```bash
API_KEY="$(
  runuser -u doctorllm -- \
  cat /doctorllm/config/vllm-api-key
)"

curl -sS \
  -H "Authorization: Bearer ${API_KEY}" \
  http://127.0.0.1:8000/v1/models
```

Expected model ID:

```text
qwen3-14b
```

From `doctorllm1`, verify network connectivity to:

```text
http://10.0.150.140:8000/v1/models
```

If vLLM is healthy but Open WebUI does not show the model, inspect the persisted Open WebUI connection.

---

# 5. Configure / Verify LDAP Authentication

Open the Authentication / LDAP section of the Admin settings.

Expected configuration:

```text
Provider / Label:       FreeIPA
LDAP:                   Enabled
Protocol:               LDAPS
Port:                   636
TLS:                    Enabled
Certificate validation: Enabled
Username attribute:     uid
Mail attribute:         mail
```

Bind account:

```text
doctorllm-bind
```

Bind DN format:

```text
uid=doctorllm-bind,cn=sysaccounts,cn=etc,<LDAP base DN>
```

The exact LDAP base DN and user search base are defined in the Ansible variables.

Verify that the FreeIPA CA is available inside the container:

```text
/etc/ssl/certs/freeipa-ca.crt
```

---

# 6. Test LDAP with a Normal User

Do not consider LDAP configuration complete after only testing the administrator account.

Test with at least one normal FreeIPA user.

Verify:

- username maps to FreeIPA `uid`;
- email maps to FreeIPA `mail`;
- authentication succeeds;
- the user receives the intended Open WebUI role;
- the user is not accidentally mapped to the administrator account;
- the user can access only the intended functionality.

---

# 7. Check for Duplicate Identity / Email Mapping

A previous DoctorLLM issue showed that reusing the same email address between accounts can cause unexpected identity mapping.

After rebuild, verify:

```text
Administrator email
Normal-user email
LDAP mail values
Existing Open WebUI user records
```

The administrator and a normal user must not accidentally resolve to the same Open WebUI identity.

If a login unexpectedly opens another user's account, inspect persisted user data and LDAP email mapping before creating new accounts.

---

# 8. Configure User Access Policy

Open:

```text
Admin Panel
→ Settings
→ Authentication / User Access
```

Recommended baseline:

```text
Default User Role: pending
```

Verify the `New Sign Ups` policy.

If users are expected to authenticate only through the controlled organization authentication flow, unrestricted local signup should normally not be enabled.

Also verify:

```text
API Keys
JWT Expiration
Pending Accounts
Admin Details
Default Group
```

according to the current operational policy.

Never set the default role to:

```text
admin
```

---

# 9. Verify `grp_doctorllm`

The FreeIPA access group is:

```text
grp_doctorllm
```

Users intended to access DoctorLLM should be members of this group.

Important distinction:

> A FreeIPA group and an Open WebUI internal group are not automatically the same object.

Therefore, after a rebuild verify how access is actually enforced.

If group mapping is configured, verify that:

```text
FreeIPA grp_doctorllm
        ↓
expected Open WebUI access
```

works for a test user.

If Open WebUI internal groups are used separately, create/verify those groups and memberships independently.

---

# 10. RAG / Document Retrieval Baseline

The current DoctorLLM baseline configuration is:

```text
Full Context Mode:     OFF
Chunk Size:            700
Chunk Overlap:         100
Top K:                 3
Top K Reranker:        3
Hybrid Search:         ON
Relevance Threshold:   0.2
```

After a completely fresh Open WebUI database, verify these values under the document/retrieval settings.

These values are the current DoctorLLM operational baseline, not a universal optimum.

---

# 11. Re-index Documents After Changing Chunking

If you change:

```text
Chunk Size
Chunk Overlap
Embedding configuration
```

documents that were already indexed can still retain the previous indexing behavior.

After significant indexing changes, re-index the affected knowledge/document collections.

---

# 12. Troubleshooting `No sources found` / `Querying`

If Open WebUI displays:

```text
No sources found
Querying
```

do not immediately change RAG parameters.

Check in this order:

1. Was a file attached to the chat?
2. Did the file finish loading?
3. Did indexing complete successfully?
4. Is the file still attached/available?
5. Is the correct Knowledge collection selected?
6. Does the document contain retrievable text?
7. Only then review retrieval/chunking parameters.

A previous DoctorLLM incident showing repeated:

```text
No sources found
```

was caused by an attached file that had not loaded correctly.

The RAG configuration itself was not the root cause.

---

# 13. DoctorLLM Context Monitor Function

A custom Open WebUI function was previously configured:

```text
doctorllm_context_monitor
```

This function is stored in Open WebUI application state.

It is currently **not recreated by the Ansible role**.

For a completely fresh database:

1. recreate/import the function;
2. enable it;
3. verify its permissions;
4. test it with `qwen3-14b`.

For a restored database:

1. verify whether the function already exists;
2. do not create a duplicate;
3. verify that it remains enabled and functional.

---

# 14. Web Search

Web Search is an Open WebUI application-level feature and is not currently enforced by the DoctorLLM Ansible role.

Review:

```text
Web Search
Web Search Confirmation
Web Search Engine
Bypass Embedding and Retrieval
Bypass Web Loader
Trust Proxy Environment
Web Loader Engine
Timeout
Verify SSL Certificate
Concurrent Requests
```

Only enable Web Search after the provider, outbound-access policy, privacy requirements, and user permissions have been decided.

---

# 15. Code Execution

Review:

```text
Enable Code Execution
Code Execution Engine
```

Do not enable it automatically on a shared system without reviewing the execution-isolation model.

---

# 16. Code Interpreter

Review:

```text
Enable Code Interpreter
Code Interpreter Engine
Code Interpreter Prompt Template
```

Available engines depend on the installed Open WebUI version and integrations.

Previously observed options included:

```text
pyodide
jupyter (Legacy)
```

Treat this feature as security-sensitive.

---

# 17. Branding

DoctorLLM branding/logo changes were tested previously and later reverted.

No custom branding is required for the core rebuild.

If branding is changed again, document it separately from infrastructure deployment.

---
