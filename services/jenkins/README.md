# [Jenkins Operator](https://www.jenkins.io/projects/jenkins-operator/)

The Jenkins Operator is a Kubernetes-native operator that extends the capabilities of Jenkins by leveraging Kubernetes features for automated and scalable Jenkins deployments.

The `jenkins-up.sh` install script will install the Jenkins operator, Jenkins server, demo seeded jobs, and Prometheus metrics with a Grafana dashboard. 

## Install
- `cd services/jenkins`
- `./jenkins-up.sh`

## Access
- Jenkins:
```bash
kubectl port-forward svc/jenkins-operator-http-jenkins 8080:jenkins --namespace jenkins
```
## Demo Jobs
The `jenkins-up.sh` install script will add two test Jobs that is seeded via the Jenkins CRD:
```yaml
seedJobs:
  - additionalClasspath: ""
    bitbucketPushTrigger: false
    buildPeriodically: ""
    description: Test Jenkins Jobs
    failOnMissingPlugin: false
    githubPushTrigger: false
    id: jenkins-operator
    ignoreMissingFiles: false
    pollSCM: ""
    repositoryBranch: service/jenkins
    repositoryUrl: https://github.com/drogerschariot/gitops-playground
    targets: services/jenkins/cicd/jobs/*.jenkins
    unstableOnDeprecation: false
```

Jobs:
- [Jenkins Operator Test 1 - Build NPM](http://localhost:8080/job/k8s-test1/)
- [Jenkins Operator Test 2 - Build Django](http://localhost:8080/job/k8s-test2/)

When jobs are run, the Jenkins operator will create new pods as agents to run the workload:

## Prometheus
The `jenkins-up.sh` script will install the service monitor and Grafana dashboard so Prometheus can scrape Jenkins metrics. The dashboard can be accessed after logging into Grafana: http://localhost:3000/d/haryan-jenkinss/jenkins3a-performance-and-health-overview?orgId=1
