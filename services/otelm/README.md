# [OpenTelemetry](https://opentelemetry.io/)
![opentelemetry-horizontal-color](https://github.com/drogerschariot/gitops-playground/assets/1655964/9b5ccded-e99b-420e-b77d-7aaee85f83d7)


OpenTelemetry is an open-source observability framework designed to facilitate the instrumentation, collection, and analysis of distributed traces and metrics in software applications. It provides a standardized set of APIs, libraries, agents, and instrumentation to enable developers to gain insights into the performance and behavior of their applications across various services and components.

By offering a consistent approach to instrumenting code and capturing telemetry data, OpenTelemetry supports interoperability and seamless integration with various observability tools and platforms. This framework is essential for organizations seeking comprehensive visibility into their systems, helping them identify and troubleshoot performance bottlenecks, latency issues, and other challenges in distributed environments.

## Features

- **Distributed Tracing:** Capture and analyze traces to gain insights into the flow of requests across various services in a distributed system.
- **Metrics Collection:** Standardized instrumentation for collecting and exporting application metrics to monitor and analyze the performance of your software.
- **Context Propagation:** Seamless context propagation across service boundaries, enabling the correlation of traces and metrics throughout the entire request lifecycle.
- **Pluggable Instrumentation:** Easily instrument your code using a variety of language-specific libraries and frameworks, supporting multiple programming languages.
- **Vendor-Agnostic:** Interoperability with a wide range of observability backends, allowing users to choose and switch between monitoring solutions.
- **Auto-Instrumentation:** Automatic instrumentation of common libraries and frameworks to reduce the manual effort required for adding observability to your applications.

## Otelm Operator
The OpenTelemetry operator is a Kubernetes-native solution that simplifies the deployment, configuration, and management of OpenTelemetry components, facilitating efficient observability instrumentation within containerized environments.

### Otelm Install
- `cd services/otelm/`
- `./otelm-up.sh`

### Otelm [Opentelemetrycollectors](https://github.com/open-telemetry/opentelemetry-operator/blob/main/bundle/manifests/opentelemetry-operator.clusterserviceversion.yaml) CRD
Once the operator is installed, you can start creating Collectors using the `Opentelemetrycollectors` CRD, here is an example:
```yaml
apiVersion: opentelemetry.io/v1alpha1
kind: OpenTelemetryCollector
metadata:
  name: test-collector
spec:
  config: |
    receivers:
      otlp:
        protocols:
          http:
    processors:
      memory_limiter:
        check_interval: 5s
      batch:
        send_batch_size: 10000
        timeout: 10s

    exporters:
      logging:

    service:
      pipelines:
        traces:
          receivers: [otlp]
          processors: [memory_limiter,batch]
          exporters: [logging]
```

## Otelm Demo
The Otelm project comes with a full fledged demo to showoff the features of OpenTelemetry.

### Otelm Demo
- `cd services/otelm/`
- `./otelm-demo-up.sh`

### Otelm Demo Access
`kubectl port-forward svc/opentelemetry-demo-frontendproxy 8080:tcp-service -n otelm-demo`
- Web store:	http://localhost:8080
- Grafana:	http://localhost:8080/grafana
- Feature Flags UI:	http://localhost:8080/feature
- Load Generator UI:	http://localhost:8080/loadgen
- Jaeger UI:	http://localhost:8080/jaeger/ui

Monitoring:
![Screenshot at 2023-11-12 18-56-14](https://github.com/drogerschariot/gitops-playground/assets/1655964/84eef5fe-b6eb-4309-8321-15b696e278f5)

Jaeger:
![Screenshot at 2023-11-12 18-57-02](https://github.com/drogerschariot/gitops-playground/assets/1655964/a4be7668-9c3c-4179-959d-c7e868607ef3)


