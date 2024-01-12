# [Wazuh](https://wazuh.com/)

![image](https://github.com/drogerschariot/gitops-playground/assets/1655964/411efbc7-48f6-4f92-8d8c-86af1020add4)

Wazuh is an open-source security information and event management (SIEM) tool that provides intrusion detection, vulnerability detection, and log analysis. It is designed to help organizations enhance their security posture by monitoring and responding to security events in real-time.

## Install
- `cd services/wazuh`
- `./wazuh-up.sh`

## DaemonSet Wazuh Agents
The `wazuh-up.sh` script will install Wazuh Agents to the cluster nodes automatically. You can see the agents when logging into the dashboard

## Access
- Wazuh Dashboard:
```bash
kubectl port-forward svc/dashboard 5601:dashboard --namespace wazuh
```
The dashboard will be available at https://localhost:5601/ with username: `kibanaserver` and password: `kibanaserver`

<img width="1507" alt="image" src="https://github.com/drogerschariot/gitops-playground/assets/1655964/3c3ed8ba-0186-4afa-88e9-0db64ce2de36">
