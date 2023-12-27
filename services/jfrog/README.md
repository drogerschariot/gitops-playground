# [JFrog Artifactory](https://jfrog.com/artifactory)
![0_uKzO4D11MaARkJG7](https://github.com/drogerschariot/gitops-playground/assets/1655964/9e5b949f-3ca2-488d-b49a-a0a8261e2be5)


JFrog Artifactory is a universal artifact repository manager that facilitates the storage, organization, and distribution of software artifacts. It provides a central hub for managing and securing artifacts across different development and deployment environments, supporting a wide range of technologies and integrations in the software development lifecycle.

Here we install the open source and full platform version of JFrog Artifactory. 

### OSS Install
```bash
$ services/jfrog
$ ./artifactory-oss-up.sh

```
The helm chart will create a load balancer in the `artifactory-oss-artifactory-nginx` service:
```bash
$ kubectl get svc/artifactory-oss-artifactory-nginx -n artifactory-oss
NAME                                TYPE           CLUSTER-IP       EXTERNAL-IP                                                              PORT(S)                      AGE
artifactory-oss-artifactory-nginx   LoadBalancer   172.20.199.105   a838f1ce1f14441e38c8d922db19fb59-880410881.us-east-1.elb.amazonaws.com   80:30302/TCP,443:31845/TCP   6m48s
```

### Full Platform Install
```bash
$ services/jfrog
$ ./jfrog-platform-up.sh

```
The helm chart will create a load balancer in the `jfrog-platform-artifactory-nginx` service:
```bash
$ kubectl get svc/jfrog-platform-artifactory-nginx -n jfrog-platform
NAME                               TYPE           CLUSTER-IP       EXTERNAL-IP                                                              PORT(S)                      AGE
jfrog-platform-artifactory-nginx   LoadBalancer   172.20.239.164   a1aadb2ec86124bd791502791e2202c7-756000163.us-east-1.elb.amazonaws.com   80:32362/TCP,443:30145/TCP   81m
```
