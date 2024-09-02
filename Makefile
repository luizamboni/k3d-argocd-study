LOADBALANCER_PORT=8080
ARGOCD_PORT=8082
APP_PORT=8083

k3d-remove:
	k3d cluster delete argocd-test

# k3d uses Traefik as ingress
k3d-init:
	k3d cluster create argocd-test --api-port 6443 -p ${LOADBALANCER_PORT}:80@loadbalancer --agents 2
	k3d kubeconfig merge argocd-test

argo-install:
	kubectl create namespace argocd	
	helm repo add argo https://argoproj.github.io/argo-helm
	helm install argocd argo/argo-cd --namespace argocd
	sleep 5
	kubectl port-forward svc/argocd-server -n argocd ${ARGOCD_PORT}:443


argo-login:
	argocd admin initial-password -n argocd
	argocd login localhost:${ARGOCD_PORT}


argo-create-service:
	argocd app create guestbook \
		--repo https://github.com/luizamboni/k3d-argocd-study.git \
		--path guestbook \
		--dest-server https://kubernetes.default.svc \
		--dest-namespace default

argo-sync-service:
	argocd app sync guestbook

argo-expose-service:
	kubectl port-forward svc/guestbook-ui -n default ${APP_PORT}:80


argo-create-nginx-service:
	argocd app create nginx \
		--repo https://github.com/luizamboni/k3d-argocd-study.git \
		--path nginx \
		--dest-server https://kubernetes.default.svc \
		--dest-namespace default
	argocd app sync nginx

# argo-expose-service:
# 	kubectl port-forward svc/guestbook-ui -n default ${APP_PORT}:80