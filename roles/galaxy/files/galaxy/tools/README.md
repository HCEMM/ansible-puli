### Tools in this folder are used by `galaxy_local_tools`

Because of the galaxy role, the info must be contained in the `files/galaxy/tools` folder, and the tools must be listed in the `galaxy_local_tools` variable in `roles/galaxy/vars/main.yml`.

On `roles/galaxy/vars/main.yml`:
```yaml
galaxy_local_tools:
  - testing.xml
```
The tools will be installed in the Galaxy instance during the Ansible run.
