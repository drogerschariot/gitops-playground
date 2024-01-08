# [Wazuh](https://wazuh.com/)

Wazuh is an open-source security information and event management (SIEM) tool that provides intrusion detection, vulnerability detection, and log analysis. It is designed to help organizations enhance their security posture by monitoring and responding to security events in real-time.

## Install
- `cd services/wazuh`
- `./wazuh-up.sh`

## DaemonSet Wazuh Agents
The `wazuh-up.sh` script will install Wazuh Agents to the cluster nodes automatically. You can see the agents when loggin into the dashboard

## Access
- Wazuh Dashboard:
```bash
kubectl port-forward svc/dashboard 5601:dashboard --namespace wazuh
```
The dashboard will be available at https://localhost:5601/ with username: `kibanaserver` and password: `kibanaserver`