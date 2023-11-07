# [Redis](https://redis.io/)

![Redis_Logo svg](https://github.com/drogerschariot/gitops-playground/assets/1655964/30c29520-c6d1-4c6b-a7dc-875a34a5ec85)


Redis is an open-source, in-memory data structure store that can be used as a database, cache, and message broker. It supports various data structures such as strings, hashes, lists, sets, sorted sets with range queries, bitmaps, hyperloglogs, and geospatial indexes with radius queries. Redis has built-in replication, Lua scripting, LRU eviction, transactions, and different levels of on-disk persistence, and provides high availability and automatic partitioning with Redis Cluster.

## Features

- **Data Structures:** Redis supports various data structures such as strings, lists, sets, sorted sets, hashes, bitmaps, hyperloglogs, and geospatial indexes.
- **In-Memory Store:** It operates as an in-memory data store, making it very fast for read and write operations.
- **Persistence:** Redis supports different levels of on-disk persistence, allowing data to be saved on disk for durability.
- **Replication:** Built-in support for replication, enabling high availability and scalability.
- **Lua Scripting:** It allows users to extend Redis's functionality using Lua scripts.
- **Transactions:** Redis supports transactions, ensuring atomicity and consistency of operations.
- **Pub/Sub Messaging:** Provides a robust Publish/Subscribe messaging mechanism.
- **High Availability:** Redis can be configured for high availability using features such as Redis Sentinel and Redis Cluster.


## Redis Install
- `cd services/redis/`
- `./redis-up.sh`

## Redis Cluster Install
- `cd services/redis/`
- `./redis-cluster-up.sh`

## Access
```bash
# redis
$ kubectl get secret redis -o jsonpath='{.data.redis-password}' | base64 --decode
$ kubectl port-forward svc/redis-master 6379:tcp-redis:6379

# redis cluster
$ kubectl get secret redis-cluster -o jsonpath='{.data.redis-password}' | base64 --decode
$ kubectl port-forward svc/redis-cluster 6379:tcp-redis:6379
```

```bash
# Example of setting a key-value pair
$ redis-cli -h localhost --pass <pass_from_secret>
127.0.0.1:6379> SET mykey "Hello"
OK
127.0.0.1:6379> GET mykey
"Hello"
```

## Monitoring
You can access the redis dashboard in Grafana
```bash
$ kubectl port-forward deployment/kube-prometheus-stack-grafana 3000:3000 --namespace monitoring
```

![Screenshot at 2023-11-06 22-29-48](https://github.com/drogerschariot/gitops-playground/assets/1655964/ebbf477b-16eb-428b-9678-9aa153871faf)
