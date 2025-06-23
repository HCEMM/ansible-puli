# ansible-puli
Ansible management of the PULI cluster

To setup
```bash
git clone https://github.com/HCEMM/ansible-puli
cd ansible-puli
ansible-galaxy collection install community.general:>=10.6.0
```

Run in testing environment: 
```
ansible-playbook -i inventory/test_hosts site.yml -e "env=test"
```

Run in production environment: 
```
ansible-playbook -i inventory/hosts site.yml -e "env=production"
```
