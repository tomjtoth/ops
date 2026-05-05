# Ops

Scripts I use to automate management of my hosts.

## Kickstarting Arch & Alpine

These steps are to be run as root on a fresh install:

```sh
curl -L ttj.hu/clonefig.sh -o clonefig.sh

# inspect, then launch
bash clonefig.sh
```

After booting the new environment, finish its configuration via Ansible.

## Playbook

Use these to automate configuring new hosts.

### Install deps

```sh
ansible-galaxy collection install -r ansible/requirements.yml
```

### Usage

The playbook presumes your user can become root.

```sh
ansible-playbook -i ansible/hosts.ini ansible/playbook.yml
```
