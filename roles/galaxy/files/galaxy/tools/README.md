# Tools in this folder are used by `galaxy_local_tools`

On `roles/galaxy/vars/main.yml`:
```yaml
galaxy_local_tools:
  - testing.xml
```
The tools will be installed in the Galaxy instance during the Ansible run.
