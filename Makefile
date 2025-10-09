LOADBALANCER_PORT=8081
API_PORT=6550
ARGOCD_PORT=8082
APP_PORT=8083

k3d-remove:
	k3d cluster delete argocd-test

# k3d uses Traefik as ingress
k3d-init:
	k3d cluster create argocd-test --api-port ${API_PORT} -p ${LOADBALANCER_PORT}:80@loadbalancer
	k3d kubeconfig merge argocd-test

argo-install:
	kubectl create namespace argocd	
	helm repo add argo https://argoproj.github.io/argo-helm
	helm install argocd argo/argo-cd --version 4.10.9 --namespace argocd

check-services:
	kubectl get service -n kube-system

argo-forward:
	kubectl port-forward svc/argocd-server -n argocd ${ARGOCD_PORT}:443

# need to expose port with "argo-forward" before
argo-login:
	kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d > /tmp/argocdpass.txt
	yes | argocd login localhost:${ARGOCD_PORT} \
		--username admin \
		--password $(shell cat /tmp/argocdpass.txt)


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

argo-expose-nginx:
	kubectl port-forward svc/nginx-service -n default ${APP_PORT}:80

argo-create-nginx-service:
	argocd app create nginx \
		--repo https://github.com/luizamboni/k3d-argocd-study.git \
		--path nginx \
		--dest-server https://kubernetes.default.svc \
		--dest-namespace default
	argocd app sync nginx

argo-create-web-app-umbrella:
	argocd app create web-app-umbrella \
		--repo https://github.com/luizamboni/k3d-argocd-study.git \
		--path web-app-umbrella \
		--dest-server https://kubernetes.default.svc \
		--dest-namespace default \
		--sync-policy automated
	argocd app sync web-app-umbrella

argo-create-guestbook-with-ingress:
	argocd app create guestbook-with-ingress \
		--repo https://github.com/luizamboni/k3d-argocd-study.git \
		--path guestbook-with-ingress \
		--dest-server https://kubernetes.default.svc \
		--dest-namespace default
	argocd app sync guestbook-with-ingress


k8-nginx-example:
	kubectl apply -f simple-nginx-in-loadbalancer/namespace.yaml
	sleep 2
	kubectl apply -f simple-nginx-in-loadbalancer/nginx-deployment.yaml
	sleep 2
	kubectl apply -f simple-nginx-in-loadbalancer/nginx-svc.yaml
	sleep 2
	kubectl apply -f simple-nginx-in-loadbalancer/nginx-ingress.yaml
	sleep 2
	kubectl apply -f simple-nginx-in-loadbalancer/pod-autoscaler.yaml


remove-k8-nginx-example:
	kubectl delete -f simple-nginx-in-loadbalancer/namespace.yaml --ignore-not-found
	kubectl delete -f simple-nginx-in-loadbalancer/nginx-deployment.yaml --ignore-not-found
	kubectl delete -f simple-nginx-in-loadbalancer/nginx-svc.yaml --ignore-not-found
	kubectl delete -f simple-nginx-in-loadbalancer/nginx-ingress.yaml --ignore-not-found
	kubectl delete -f simple-nginx-in-loadbalancer/pod-autoscaler.yaml --ignore-not-found

watch-nginx-autoscaler:
	kubectl get hpa -n dev -w

inspect-ingress:
	kubectl get pods -n kube-system | grep traefik
	kubectl describe ingress -n dev
	kubectl logs -n kube-system deploy/traefik -f

# debuging traefik

#    kubectl get pods -n kube-system | grep traefik
#    kubectl logs -n kube-system traefik-97b44b794-45t8b
# 	 kubectt get ingress
#    kubectl describe ingress nginx

load-test:
	kubectl run hey \
	--image=docker.io/williamyeh/hey:latest \
	--restart=Never \
	-- -z 5m -c 50 -q 50 http://nginx-service.dev.svc.cluster.local

load-test-logs:
	kubectl logs -f hey
	kubectl logs hey --previous

delete-load-test:
	kubectl delete pod hey --ignore-not-found
