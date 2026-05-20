# list available recipes
default:
    just --list

# node status and resource usage
nodes:
    kubectl get nodes -o wide | awk '{print $1,$2,$3,$4,$5,$6}' | column -t
    kubectl top nodes

# all pods accepts namespace
pods ns='':
    kubectl get pods {{ if ns != '' { '-n ' + ns } else { '-A' } }} -o wide

# pods not Running or Completed accepts namespace
failing ns='':
    kubectl get pods {{ if ns != '' { '-n ' + ns } else { '-A' } }} -o json | jq -r '["NAMESPACE","POD","STATUS","REASON"], (.items[] | select(.status.phase != "Running" and .status.phase != "Succeeded") | [.metadata.namespace, .metadata.name, .status.phase, (.status.conditions[]? | select(.type=="Ready") | .reason // "")]) | @tsv' | column -t

# pods with restarts > 0, sorted descending accepts namespace
restarts ns='':
    kubectl get pods {{ if ns != '' { '-n ' + ns } else { '-A' } }} -o json | jq -r '["RESTARTS","NAMESPACE","POD","CONTAINER"], (.items[] | .metadata.namespace as $ns | .metadata.name as $pod | .status.containerStatuses[]? | select(.restartCount > 0) | [(.restartCount|tostring), $ns, $pod, .name]) | @tsv' | column -t | sort -rn

# pending pods with scheduling reason accepts namespace
pending ns='':
    kubectl get pods {{ if ns != '' { '-n ' + ns } else { '-A' } }} -o json | jq -r '["NAMESPACE","POD","REASON","MESSAGE"], (.items[] | select(.status.phase=="Pending") | [.metadata.namespace, .metadata.name, (.status.conditions[]? | select(.type=="PodScheduled") | .reason // "unknown"), (.status.conditions[]? | select(.type=="PodScheduled") | .message // "")]) | @tsv' | column -t

# warning events sorted by time accepts namespace
events ns='':
    kubectl get events {{ if ns != '' { '-n ' + ns } else { '-A' } }} --sort-by='.lastTimestamp' | grep Warning | tail -50

# pods without resource limits accepts namespace
no-limits ns='':
    kubectl get pods {{ if ns != '' { '-n ' + ns } else { '-A' } }} -o json | jq -r '["NAMESPACE","POD","CONTAINER"], (.items[] | .metadata.namespace as $ns | .metadata.name as $pod | .spec.containers[] | select(.resources.limits == null) | [$ns, $pod, .name]) | @tsv' | column -t

# all images running in cluster accepts namespace
images ns='':
    kubectl get pods {{ if ns != '' { '-n ' + ns } else { '-A' } }} -o json | jq -r '.items[].spec.containers[].image' | sort -u

# stream logs for a pod fzf picker, accepts namespace
logs ns='':
    #!/bin/bash
    if [ -n "{{ns}}" ]; then
        pod=$(kubectl get pods -n "{{ns}}" --no-headers | fzf --prompt="pod> " --height=40% --preview "kubectl get pod -n {{ns}} {1} -o wide" | awk '{print $1}')
        [ -z "$pod" ] && exit 0
        echo "kubectl logs -n {{ns}} $pod --tail=100 -f"
        kubectl logs -n "{{ns}}" "$pod" --tail=100 -f
    else
        selection=$(kubectl get pods -A --no-headers | fzf --prompt="pod> " --height=40%)
        [ -z "$selection" ] && exit 0
        ns=$(awk '{print $1}' <<< "$selection")
        pod=$(awk '{print $2}' <<< "$selection")
        echo "kubectl logs -n $ns $pod --tail=100 -f"
        kubectl logs -n "$ns" "$pod" --tail=100 -f
    fi

# describe a pod fzf picker, accepts namespace
desc ns='':
    #!/bin/bash
    if [ -n "{{ns}}" ]; then
        pod=$(kubectl get pods -n "{{ns}}" --no-headers | fzf --prompt="pod> " --height=40% --preview "kubectl get pod -n {{ns}} {1} -o wide" | awk '{print $1}')
        [ -z "$pod" ] && exit 0
        echo "kubectl describe pod -n {{ns}} $pod"
        kubectl describe pod -n "{{ns}}" "$pod"
    else
        selection=$(kubectl get pods -A --no-headers | fzf --prompt="pod> " --height=40%)
        [ -z "$selection" ] && exit 0
        ns=$(awk '{print $1}' <<< "$selection")
        pod=$(awk '{print $2}' <<< "$selection")
        echo "kubectl describe pod -n $ns $pod"
        kubectl describe pod -n "$ns" "$pod"
    fi

# describe a node (fzf picker)
descnode:
    #!/bin/bash
    node=$(kubectl get nodes --no-headers | fzf --prompt="node> " | awk '{print $1}')
    [ -z "$node" ] && exit 0
    echo "kubectl describe node $node"
    kubectl describe node "$node"
