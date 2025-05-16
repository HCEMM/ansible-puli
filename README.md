# ansible-puli
Ansible management of the PULI cluster

To run
```bash
git clone https://github.com/HCEMM/ansible-puli
cd ansible-puli
ansible-galaxy collection install community.general:>=10.6.0
ansible-playbook -i inventory/hosts site.yml
```