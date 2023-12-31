# [CloudNativePG](https://cloudnative-pg.io/)
<p align="center">
  <img src="https://github.com/drogerschariot/gitops-playground/assets/1655964/fea4a793-5f26-4559-881c-572015f01ae0" />
</p>

CloudNativePG is the Kubernetes operator that covers the full lifecycle of a highly available PostgreSQL database cluster with a primary/standby architecture, using native streaming replication.

## Install
- `cd services/cnpg/`
- `./cnpg-up.sh`

## Access
A Sample cluster using the [Cluster CRD](https://github.com/cloudnative-pg/cloudnative-pg/blob/main/config/crd/bases/postgresql.cnpg.io_clusters.yaml) is installed for you with the following manifest

```yaml
apiVersion: postgresql.cnpg.io/v1
kind: Cluster
metadata:
  name: test-db
spec:
  description: "Test CNPG Database"
  instances: 3

  replicationSlots:
    highAvailability:
      enabled: true
    updateInterval: 300
  primaryUpdateStrategy: unsupervised

  postgresql:
    parameters:
      shared_buffers: 256MB
      pg_stat_statements.max: '10000'
      pg_stat_statements.track: all
      auto_explain.log_min_duration: '10s'

  logLevel: debug
  storage:
    size: 10Gi

  monitoring:
    enablePodMonitor: true

  resources:
    requests:
      memory: "512Mi"
      cpu: "1"
    limits:
      memory: "1Gi"
      cpu: "2"
```

You can access the cluster using the rw and ro services: 
- Read Only - `kubectl port-forward svc/test-db-ro 5432:postgres`
- Read/Write - `kubectl port-forward svc/test-db-rw 5432:postgres`

## Monitoring
CloudnativePG metrics and dashboards are automatticly installed. You can access the CloudnativePG Grafana dashboard by running:
```bash
kubectl port-forward deployment/kube-prometheus-stack-grafana 3000:3000 --namespace monitoring
```
![Screenshot-at-2023-10-24-11-42-22](https://github.com/drogerschariot/gitops-playground/assets/1655964/42e2009a-636f-470b-9686-dc259c6593ff)

## [Backup](https://cloudnative-pg.io/documentation/1.16/backup_recovery/)
Included is an example of a [ScheduledBackup CRD](https://github.com/cloudnative-pg/cloudnative-pg/blob/main/config/crd/bases/postgresql.cnpg.io_scheduledbackups.yaml) `kubectl apply -f backup.yml`.

```yaml
apiVersion: postgresql.cnpg.io/v1
kind: ScheduledBackup
metadata:

  name: backup-example
spec:
  schedule: "0 */30 * * * *" # Every 30 minutes
  backupOwnerReference: self
  cluster:
    name: test-db
```

## [PGBouncer](https://cloudnative-pg.io/documentation/1.16/backup_recovery/)
Included is an example of a [Pooler CRD](https://cloudnative-pg.io/documentation/1.15/connection_pooling/) `kubectl apply -f pool.yml`.

```yaml
apiVersion: postgresql.cnpg.io/v1
kind: Pooler
metadata:
  name: pooler-demo
spec:
  cluster:
    name: test-db

  instances: 3
  type: rw
  pgbouncer:
    poolMode: session
    parameters:
      max_client_conn: "1000"
      default_pool_size: "10"
```

## [Benchmarking](https://cloudnative-pg.io/documentation/current/benchmarking/)
You can run pgbench using the cnpg kubectl plugin:

```bash
kubectl cnpg pgbench test-db --job-name bench-test2 --db-name app -- --initialize --scale 300
```

## PGAdmin
If you would like to use [PGAdmin](https://www.pgadmin.org/) run:
```bash
kubectl apply -f pgadmin.yml
kubectl -n test-db port-forward pod/vault-ui 8200:80
```
![scale-out-postgresql-distributed-sql-pgadmin-00](https://github.com/drogerschariot/gitops-playground/assets/1655964/07a746eb-2913-4194-968d-09eb17ce5975)

