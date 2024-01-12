# [Jenkins Operator](https://www.jenkins.io/projects/jenkins-operator/)
![image](https://github.com/drogerschariot/gitops-playground/assets/1655964/2165c6d2-7ba1-4ed1-a165-8eef6fc53ebf)

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
<img width="1498" alt="Screenshot 2024-01-12 at 1 36 05 PM" src="https://github.com/drogerschariot/gitops-playground/assets/1655964/24297ed7-740a-434e-aaff-cf5ae29a6941">

When jobs are triggered, the Jenkins operator will create new pods as agents to run the workload:
<img width="348" alt="Screenshot 2024-01-12 at 1 41 41 PM" src="https://github.com/drogerschariot/gitops-playground/assets/1655964/8fd90e26-f9c2-43b8-bb26-d7501164a553">
<img width="837" alt="Screenshot 2024-01-12 at 1 41 56 PM" src="https://github.com/drogerschariot/gitops-playground/assets/1655964/872e9780-d46b-42cd-8b41-e4ad95d18d84">

## Prometheus
The `jenkins-up.sh` script will install the service monitor and Grafana dashboard so Prometheus can scrape Jenkins metrics. The dashboard can be accessed after logging into Grafana: http://localhost:3000/d/haryan-jenkinss/jenkins3a-performance-and-health-overview?orgId=1
<img width="1504" alt="Screenshot 2024-01-12 at 1 29 29 PM" src="https://github.com/drogerschariot/gitops-playground/assets/1655964/66a76133-caf5-4946-a4ec-6546d848b993">

