# ansible-puli
Ansible management of the PULI cluster

To setup
```bash
git clone https://github.com/HCEMM/ansible-puli
cd ansible-puli
ansible-galaxy install -r requirements.yml
```
Also need to [get the ThinLinc ZIP file](https://www.cendio.com/thinlinc/download) and place it in `~/ansible-puli`.

Run in testing environment: 
```
ansible-playbook -i inventory/test_hosts site.yml -e "env=test"
```

Run in production environment: 
```
ansible-playbook -i inventory/hosts site.yml -e "env=production"
```

## Some nice tips

### Print facts

```yaml
- name: Print facts
  ansible.builtin.debug:
    var: ansible_facts
```
