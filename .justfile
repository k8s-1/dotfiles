# list available recipes
default:
    just --list --unsorted

# node status and resource usage
nodes:
    kubectl get nodes -o wide | awk '{print $1,$2,$3,$4,$5,$6}' | column -t
    kubectl top nodes

# pending, failing and restarting pods
issues ns='':
    just pending {{ns}}
    @echo
    just failing {{ns}}
    @echo
    just restarts {{ns}}

# all pods
pods ns='':
    kubectl get pods {{ if ns != '' { '-n ' + ns } else { '-A' } }} -o wide

# describe a pod
desc ns='':
    #!/bin/bash
    selection=$(kubectl get pods -A {{ if ns != '' { '--field-selector metadata.namespace={{ns}}' } else { '' } }} --no-headers | fzf --prompt="pod> " --height=40% --preview "kubectl get pod -n {1} {2} -o wide")
    [ -z "$selection" ] && exit 0
    ns=$(awk '{print $1}' <<< "$selection")
    pod=$(awk '{print $2}' <<< "$selection")
    echo "kubectl describe pod -n $ns $pod"
    kubectl describe pod -n "$ns" "$pod"

# stream logs for a pod
logs ns='':
    #!/bin/bash
    selection=$(kubectl get pods -A {{ if ns != '' { '--field-selector metadata.namespace={{ns}}' } else { '' } }} --no-headers | fzf --prompt="pod> " --height=40% --preview "kubectl get pod -n {1} {2} -o wide")
    [ -z "$selection" ] && exit 0
    ns=$(awk '{print $1}' <<< "$selection")
    pod=$(awk '{print $2}' <<< "$selection")
    echo "kubectl logs -n $ns $pod --tail=30 -f"
    kubectl logs -n "$ns" "$pod" --tail=30 -f

# all images running in cluster
images ns='':
    kubectl get pods {{ if ns != '' { '-n ' + ns } else { '-A' } }} -o json | jq -r '.items[].spec.containers[].image' | sort -u

[private]
failing ns='':
    kubectl get pods {{ if ns != '' { '-n ' + ns } else { '-A' } }} -o json | jq -r '["NAMESPACE","POD","STATUS","REASON"], (.items[] | select(.status.phase != "Running" and .status.phase != "Succeeded") | [.metadata.namespace, .metadata.name, .status.phase, (.status.conditions[]? | select(.type=="Ready") | .reason // "")]) | @tsv' | column -t

[private]
pending ns='':
    kubectl get pods {{ if ns != '' { '-n ' + ns } else { '-A' } }} -o json | jq -r '["NAMESPACE","POD","REASON","MESSAGE"], (.items[] | select(.status.phase=="Pending") | [.metadata.namespace, .metadata.name, (.status.conditions[]? | select(.type=="PodScheduled") | .reason // "unknown"), (.status.conditions[]? | select(.type=="PodScheduled") | .message // "")]) | @tsv' | column -t

[private]
restarts ns='':
    kubectl get pods {{ if ns != '' { '-n ' + ns } else { '-A' } }} -o json | jq -r '["RESTARTS","NAMESPACE","POD","CONTAINER"], (.items[] | .metadata.namespace as $ns | .metadata.name as $pod | .status.containerStatuses[]? | select(.restartCount > 0) | [(.restartCount|tostring), $ns, $pod, .name]) | @tsv' | column -t | sort -rn

# install: go install github.com/zegl/kube-score/cmd/kube-score@latest
# audit cluster resources with kube-score
audit ns='':
    #!/bin/bash
    if [ -z "{{ns}}" ]; then
        ns=$(kubectl get ns --no-headers | awk '{print $1}' | fzf --prompt="ns> " --height=40%)
    else
        ns="{{ns}}"
    fi
    [ -z "$ns" ] && exit 0
    echo "kubectl get pods,deployments,services -n $ns -o yaml | kube-score score -"
    kubectl get pods,deployments,services -n "$ns" -o yaml | kube-score score - || true

