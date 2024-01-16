# [GitLab](https://about.gitlab.com/)

GitLab is a web-based platform that provides a complete set of tools for software development, including version control, continuous integration, code review, and issue tracking. It offers a unified and collaborative environment for teams to efficiently manage their software development lifecycle.

## Install
- `cd services/gitlab`
- `./gitlab-up.sh`

## Access
In the `test-lab.yml` manifest, you will need to replace the domain to something you own. The operator will create an ingress to the webservices and use cert-manager to create certificates.
```yaml
apiVersion: apps.gitlab.com/v1beta1
kind: GitLab
metadata:
  name: gitlab
  namespace: gitlab
spec:
  chart:
    version: "7.7.2" # https://gitlab.com/gitlab-org/cloud-native/gitlab-operator/-/blob/0.8.1/CHART_VERSIONS
    values:
      global:
        hosts:
          domain: yourdomain.com # use a real domain here
        ingress:
          configureCertmanager: false
      certmanager-issuer:
        email: you@yourdomain.com # use your real email address here
```

## Monitoring
The `gitlab.up.sh` script will install a service monitor for Prometheus. You can find available metrics [Here](https://docs.gitlab.com/ee/administration/monitoring/prometheus/gitlab_metrics.html)