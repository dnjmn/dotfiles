# Kubernetes Aliases - Context-Aware
# Uses current kubectl context (set with: kubectl config use-context <name>)

# Base kubectl
alias k="kubectl"

# Get resources
alias kgp="kubectl get pods"
alias kgs="kubectl get svc"
alias kgd="kubectl get deployments"
alias kgn="kubectl get nodes"
alias kga="kubectl get all"

# Describe and logs
alias kd="kubectl describe"
alias kl="kubectl logs"
alias klf="kubectl logs -f"

# Execute
alias ke="kubectl exec -it"

# Context/namespace management
alias kctx="kubectl config current-context"
alias kns="kubectl config view --minify --output 'jsonpath={..namespace}'"
alias ksn="kubectl config set-context --current --namespace"
