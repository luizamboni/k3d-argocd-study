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
	kubectl create namespace argocd	

install-argocd:
	kubectl apply -f argocd/install.yaml -n argocd 
# kubectl apply -f argocd/ingress.yaml -n argocd 
