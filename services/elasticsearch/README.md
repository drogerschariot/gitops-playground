# [Elasticsearch](https://www.elastic.co/)

Elasticsearch is a distributed, open-source search and analytics engine designed for horizontal scalability and real-time data indexing, retrieval, and analysis.

![image](https://github.com/drogerschariot/gitops-playground/assets/1655964/5f07d01f-c63b-4343-b0e0-c2d2c56665ee)

## Install
- `cd services/elasticsearch`
- `./es-up.sh`

## Access
- Elasticsearch:
```bash
kubectl port-forward svc/elasticsearch 9200:tcp-rest-api --namespace elasticsearch
```
- Kinaba:
```bash
kubectl port-forward svc/elasticsearch-kibana 5601:http --namespace elasticsearch
```

## Monitoring
The `es-up.sh` will install a [Prometheus Elasticsearch Dashboard](https://grafana.com/grafana/dashboards/14191-elasticsearch-overview/) which can be accessed via Grafana: `kubectl port-forward deployment/kube-prometheus-stack-grafana 3000:3000 --namespace monitoring`

<img width="1504" alt="image" src="https://github.com/drogerschariot/gitops-playground/assets/1655964/b3d880aa-ce14-435f-b651-5195bdc9a80a">
<img width="1500" alt="image" src="https://github.com/drogerschariot/gitops-playground/assets/1655964/346f809f-3d92-4aad-be79-92087a2e01c3">
