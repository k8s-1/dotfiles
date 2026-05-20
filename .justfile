# list available recipes
default:
    just --list

# all pods across namespaces
pods:
    kubectl get pods -A -o wide

# pods not Running or Completed
failing:
    kubectl get pods -A -o json | jq -r '["NAMESPACE","POD","STATUS","REASON"], (.items[] | select(.status.phase != "Running" and .status.phase != "Succeeded") | [.metadata.namespace, .metadata.name, .status.phase, (.status.conditions[]? | select(.type=="Ready") | .reason // "")]) | @tsv' | column -t

# pods with restarts > 0, sorted descending
restarts:
    kubectl get pods -A -o json | jq -r '["RESTARTS","NAMESPACE","POD","CONTAINER"], (.items[] | .metadata.namespace as $ns | .metadata.name as $pod | .status.containerStatuses[]? | select(.restartCount > 0) | [(.restartCount|tostring), $ns, $pod, .name]) | @tsv' | column -t | sort -rn

# warning events sorted by time
events:
    kubectl get events -A --sort-by='.lastTimestamp' | grep Warning | tail -30

# pending pods with scheduling reason
pending:
    kubectl get pods -A -o json | jq -r '["NAMESPACE","POD","REASON","MESSAGE"], (.items[] | select(.status.phase=="Pending") | [.metadata.namespace, .metadata.name, (.status.conditions[]? | select(.type=="PodScheduled") | .reason // "unknown"), (.status.conditions[]? | select(.type=="PodScheduled") | .message // "")]) | @tsv' | column -t

# node status
nodes:
    kubectl get nodes -o wide

# resource usage (nodes + top pods by memory)
top:
    #!/bin/bash
    kubectl top nodes
    echo
    kubectl top pods -A --sort-by=memory 2>/dev/null | head -20

# pods without resource limits
no-limits:
    kubectl get pods -A -o json | jq -r '["NAMESPACE","POD","CONTAINER"], (.items[] | .metadata.namespace as $ns | .metadata.name as $pod | .spec.containers[] | select(.resources.limits == null) | [$ns, $pod, .name]) | @tsv' | column -t

# all images running in cluster
images:
    kubectl get pods -A -o json | jq -r '.items[].spec.containers[].image' | sort -u

# stream logs for a pod (fzf picker)
logs:
    #!/bin/bash
    selection=$(kubectl get pods -A --no-headers | fzf --prompt="pod> ")
    [ -z "$selection" ] && exit 0
    ns=$(awk '{print $1}' <<< "$selection")
    pod=$(awk '{print $2}' <<< "$selection")
    kubectl logs -n "$ns" "$pod" --tail=100 -f

# describe a pod (fzf picker)
desc:
    #!/bin/bash
    selection=$(kubectl get pods -A --no-headers | fzf --prompt="pod> ")
    [ -z "$selection" ] && exit 0
    ns=$(awk '{print $1}' <<< "$selection")
    pod=$(awk '{print $2}' <<< "$selection")
    kubectl describe pod -n "$ns" "$pod"

# describe a node (fzf picker)
descnode:
    #!/bin/bash
    node=$(kubectl get nodes --no-headers | fzf --prompt="node> " | awk '{print $1}')
    [ -z "$node" ] && exit 0
    kubectl describe node "$node"
