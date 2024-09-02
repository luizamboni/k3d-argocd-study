# kubectl -n argocd patch secret argocd-secret
#   -p '{"stringData":  {
#     "admin.password": "$2y$12$Kg4H0rLL/RVrWUVhj6ykeO3Ei/YqbGaqp.jAtzzUSJdYWT6LUh/n6",
#     "admin.passwordMtime": "'$(date +%FT%T%Z)'"
#   }}'

remove-k3d:
	k3d cluster delete argocd-test

init-k3d:
	k3d cluster create argocd-test --api-port 6443 -p 8080:80@loadbalancer --agents 2
	k3d kubeconfig merge argocd-test

install-argocd:
	kubectl create namespace argocd	
	helm repo add argo https://argoproj.github.io/argo-helm
	helm install argocd argo/argo-cd --namespace argocd
	kubectl port-forward svc/argocd-server -n argocd 8081:443


login:
	argocd admin initial-password -n argocd
	argocd login localhost:8081


create-service:
	argocd app create guestbook \
		--repo https://github.com/luizamboni/k3d-argocd-study.git \
		--path guestbook \
		--dest-server https://kubernetes.default.svc \
		--dest-namespace default