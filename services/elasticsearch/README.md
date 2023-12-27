# [Elasticsearch](# [Elasticsearch]https://www.elastic.co/)

Elasticsearch is a distributed, open-source search and analytics engine designed for horizontal scalability and real-time data indexing, retrieval, and analysis.

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
