ArgoCd study
===

# Dependencies
- K3d
- helm
- argocd
- kubectl

```shell
kubectl get svc -A
```

# how to work with this repo
```shell
make kd3-init
```

```shell
make argo-install
```

In a separeted terminal, run port forward for argo
```shell
make argo-forward
```

```shell
make argo-login
```

```shell
make argo-create-nginx-service
make argo-create-guestbook-with-ingress
make argo-create-web-app-umbrella
# It will run a wiremock, you can check it out on: http://localhost:8081/umbrella/__admin/mappings
```
<!-- 
# Helm
helm install hello web-app --dry-run -->