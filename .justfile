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
describe ns='':
    #!/bin/bash
    selection=$(kubectl get pods -A {{ if ns != '' { '--field-selector metadata.namespace={{ns}}' } else { '' } }} --no-headers | fzf --prompt="pod> " --height=40% --preview "kubectl get pod -n {1} {2} -o wide")
    [ -z "$selection" ] && exit 0
    ns=$(awk '{print $1}' <<< "$selection")
    pod=$(awk '{print $2}' <<< "$selection")
    echo "kubectl describe pod -n $ns $pod"
    kubectl describe pod -n "$ns" "$pod"

# exec into a pod
exec ns='':
    #!/bin/bash
    selection=$(kubectl get pods -A {{ if ns != '' { '--field-selector metadata.namespace={{ns}}' } else { '' } }} --no-headers | fzf --prompt="pod> " --height=40% --preview "kubectl get pod -n {1} {2} -o wide")
    [ -z "$selection" ] && exit 0
    ns=$(awk '{print $1}' <<< "$selection")
    pod=$(awk '{print $2}' <<< "$selection")
    echo "kubectl exec -it -n $ns $pod -- bash"
    kubectl exec -it -n "$ns" "$pod" -- bash 2>/dev/null || kubectl exec -it -n "$ns" "$pod" -- sh 2>/dev/null || echo "no shell available"

# restart deployments (multi-select, labels visible in picker)
rollout ns='':
    #!/bin/bash
    if [ -z "{{ns}}" ]; then
        ns=$(kubectl get ns --no-headers | awk '{print $1}' | fzf --prompt="ns> " --height=40%)
    else
        ns="{{ns}}"
    fi
    [ -z "$ns" ] && exit 0
    selection=$(kubectl get deployments -n "$ns" --show-labels --no-headers | fzf --prompt="rollout restart deployment (TAB to multi-select)> " --height=40% --multi)
    [ -z "$selection" ] && exit 0
    while read -r line; do
        deploy=$(awk '{print $1}' <<< "$line")
        echo "kubectl rollout restart deployment/$deploy -n $ns"
        kubectl rollout restart deployment/"$deploy" -n "$ns"
    done <<< "$selection"

# stream logs for a pod
logs ns='':
    #!/bin/bash
    selection=$(kubectl get pods -A {{ if ns != '' { '--field-selector metadata.namespace={{ns}}' } else { '' } }} --no-headers | fzf --prompt="pod> " --height=40% --preview "kubectl get pod -n {1} {2} -o wide")
    [ -z "$selection" ] && exit 0
    ns=$(awk '{print $1}' <<< "$selection")
    pod=$(awk '{print $2}' <<< "$selection")
    echo "kubectl logs -n $ns $pod --tail=30 -f"
    kubectl logs -n "$ns" "$pod" --tail=30 -f

# PVCs with status, capacity and reclaim policy
pvc ns='':
    kubectl get pvc {{ if ns != '' { '-n ' + ns } else { '-A' } }} -o json | jq -r '["NAMESPACE","PVC","STATUS","CAPACITY","ACCESS","STORAGECLASS"], (.items[] | [.metadata.namespace, .metadata.name, .status.phase, (.status.capacity.storage // "-"), (.spec.accessModes[0] // "-"), (.spec.storageClassName // "-")]) | @tsv' | column -t

# migrate a PVC to a new larger one (fzf picker)
pvc-migrate:
    #!/bin/bash
    ns=$(kubectl get ns --no-headers | awk '{print $1}' | fzf --prompt="ns> " --height=40%)
    [ -z "$ns" ] && exit 0
    pvc=$(kubectl get pvc -n "$ns" --no-headers | fzf --prompt="pvc> " --height=40% | awk '{print $1}')
    [ -z "$pvc" ] && exit 0
    access_mode=$(kubectl get pvc -n "$ns" "$pvc" -o jsonpath='{.spec.accessModes[0]}')
    storage_class=$(kubectl get pvc -n "$ns" "$pvc" -o jsonpath='{.spec.storageClassName}')
    read -p "New size (e.g. 10Gi): " new_size
    [ -z "$new_size" ] && exit 0
    new_pvc="${pvc}-migrate"
    jq -n --arg name "$new_pvc" --arg ns "$ns" --arg mode "$access_mode" --arg sc "$storage_class" --arg size "$new_size" \
        '{apiVersion:"v1",kind:"PersistentVolumeClaim",metadata:{name:$name,namespace:$ns},spec:{accessModes:[$mode],storageClassName:$sc,resources:{requests:{storage:$size}}}}' \
        | kubectl apply -f -
    jq -n --arg ns "$ns" --arg pvc "$pvc" --arg new_pvc "$new_pvc" \
        '{apiVersion:"v1",kind:"Pod",metadata:{name:"pvc-migrate-temp",namespace:$ns},spec:{restartPolicy:"Never",containers:[{name:"migrate",image:"busybox",command:["sleep","3600"],volumeMounts:[{name:"source",mountPath:"/source"},{name:"dest",mountPath:"/dest"}]}],volumes:[{name:"source",persistentVolumeClaim:{claimName:$pvc}},{name:"dest",persistentVolumeClaim:{claimName:$new_pvc}}]}}' \
        | kubectl apply -f -
    echo "Waiting for migration pod..."
    kubectl wait pod/pvc-migrate-temp -n "$ns" --for=condition=Ready --timeout=120s
    echo "Copying data..."
    kubectl exec -n "$ns" pvc-migrate-temp -- cp -av /source/. /dest/
    kubectl delete pod pvc-migrate-temp -n "$ns"
    echo ""
    echo "Done. Update your deployment to use: $new_pvc"
    echo "Then delete the old PVC: kubectl delete pvc $pvc -n $ns"

# launch a netshoot debug pod
netshoot ns='':
    #!/bin/bash
    if [ -z "{{ns}}" ]; then
        ns=$(kubectl get ns --no-headers | awk '{print $1}' | fzf --prompt="ns> " --height=40%)
    else
        ns="{{ns}}"
    fi
    [ -z "$ns" ] && exit 0
    echo "kubectl run netshoot --rm -it --image=nicolaka/netshoot -n $ns -- bash"
    echo ""
    echo "useful commands:"
    echo "  dig <svc>.<ns>.svc.cluster.local"
    echo "  curl http://<svc>.<ns>.svc.cluster.local"
    echo "  ping <pod-ip>"
    echo ""
    kubectl run netshoot --rm -it --image=nicolaka/netshoot -n "$ns" -- bash

# gateways and httproutes
routes ns='':
    kubectl get gateway,httproute {{ if ns != '' { '-n ' + ns } else { '-A' } }}

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

