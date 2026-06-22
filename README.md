# ansible-puli
Ansible management of the PULI cluster

To setup
```bash
git clone https://github.com/HCEMM/ansible-puli
cd ansible-puli
ansible-galaxy install -r requirements.yml
# add the password for the vault to .vault_pass.txt, and then
ansible-playbook puli.yml     # showtime
```

## Some nice tips

### Print facts

```yaml
- name: Print facts
  ansible.builtin.debug:
    var: ansible_facts
```
