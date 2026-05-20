# list recipes
default:
    just --list --unsorted

# get + top nodes
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

# get pods
pods ns='':
    kubectl get pods {{ if ns != '' { '-n ' + ns } else { '-A' } }} -o wide

# describe pods
describe ns='':
    #!/bin/bash
    selection=$(kubectl get pods -A {{ if ns != '' { '--field-selector metadata.namespace={{ns}}' } else { '' } }} --no-headers | fzf --prompt="pod> " --height=40% --preview "kubectl get pod -n {1} {2} -o wide")
    [ -z "$selection" ] && exit 0
    ns=$(awk '{print $1}' <<< "$selection")
    pod=$(awk '{print $2}' <<< "$selection")
    echo "kubectl describe pod -n $ns $pod"
    kubectl describe pod -n "$ns" "$pod"

# exec -it pod
exec ns='':
    #!/bin/bash
    selection=$(kubectl get pods -A {{ if ns != '' { '--field-selector metadata.namespace={{ns}}' } else { '' } }} --no-headers | fzf --prompt="pod> " --height=40% --preview "kubectl get pod -n {1} {2} -o wide")
    [ -z "$selection" ] && exit 0
    ns=$(awk '{print $1}' <<< "$selection")
    pod=$(awk '{print $2}' <<< "$selection")
    echo "kubectl exec -it -n $ns $pod -- bash"
    kubectl exec -it -n "$ns" "$pod" -- bash 2>/dev/null || kubectl exec -it -n "$ns" "$pod" -- sh 2>/dev/null || echo "no shell available"

# restart deployment
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

# pod logs
logs ns='':
    #!/bin/bash
    selection=$(kubectl get pods -A {{ if ns != '' { '--field-selector metadata.namespace={{ns}}' } else { '' } }} --no-headers | fzf --prompt="pod> " --height=40% --preview "kubectl get pod -n {1} {2} -o wide")
    [ -z "$selection" ] && exit 0
    ns=$(awk '{print $1}' <<< "$selection")
    pod=$(awk '{print $2}' <<< "$selection")
    echo "kubectl logs -n $ns $pod --tail=30 -f"
    kubectl logs -n "$ns" "$pod" --tail=30 -f

# PVCs with status, capacity and disk usage (- if no pod is mounting it)
pvc ns='':
    #!/bin/bash
    declare -A mount_map
    pod_mounts=$(kubectl get pods {{ if ns != '' { '-n ' + ns } else { '-A' } }} -o json | jq -r '
      .items[] | select(.status.phase=="Running") |
      .metadata.namespace as $ns | .metadata.name as $pod |
      (.spec.volumes[]? | select(.persistentVolumeClaim) | .persistentVolumeClaim.claimName) as $pvc |
      (.spec.volumes[]? | select(.persistentVolumeClaim.claimName == $pvc) | .name) as $volname |
      .spec.containers[].volumeMounts[] | select(.name == $volname) |
      [$ns, $pvc, $pod, .mountPath] | @tsv
    ')
    while IFS=$'\t' read -r mns mpvc mpod mmount; do
        mount_map["$mns/$mpvc"]="$mpod:$mmount"
    done <<< "$pod_mounts"
    pvc_list=$(kubectl get pvc {{ if ns != '' { '-n ' + ns } else { '-A' } }} -o json | jq -r '
      .items[] | [.metadata.namespace, .metadata.name, .status.phase, (.status.capacity.storage // "-"), (.spec.accessModes[0] // "-"), (.spec.storageClassName // "-")] | @tsv
    ')
    (
      echo -e "NAMESPACE\tPVC\tSTATUS\tCAPACITY\tUSED\tUSE%\tACCESS\tSTORAGECLASS"
      while IFS=$'\t' read -r ns pvc status cap access sc; do
          used="-" pct="-"
          if [ -n "${mount_map[$ns/$pvc]}" ]; then
              pod="${mount_map[$ns/$pvc]%%:*}"
              mount="${mount_map[$ns/$pvc]#*:}"
              df_line=$(kubectl exec "$pod" -n "$ns" -- df -h "$mount" 2>/dev/null | awk 'NR==2')
              [ -n "$df_line" ] && used=$(awk '{print $3}' <<< "$df_line") && pct=$(awk '{print $5}' <<< "$df_line")
          fi
          echo -e "$ns\t$pvc\t$status\t$cap\t$used\t$pct\t$access\t$sc"
      done <<< "$pvc_list"
    ) | column -t

# migrate a PVC to a new larger one
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
    jq -n \
        --arg name "$new_pvc" --arg ns "$ns" \
        --arg mode "$access_mode" --arg sc "$storage_class" --arg size "$new_size" \
        '{
          apiVersion: "v1",
          kind: "PersistentVolumeClaim",
          metadata: {name: $name, namespace: $ns},
          spec: {
            accessModes: [$mode],
            storageClassName: $sc,
            resources: {requests: {storage: $size}}
          }
        }' | kubectl apply -f -
    jq -n \
        --arg ns "$ns" --arg pvc "$pvc" --arg new_pvc "$new_pvc" \
        '{
          apiVersion: "v1",
          kind: "Pod",
          metadata: {name: "pvc-migrate-temp", namespace: $ns},
          spec: {
            restartPolicy: "Never",
            containers: [{
              name: "migrate",
              image: "busybox",
              command: ["sleep", "86400"],
              volumeMounts: [
                {name: "source", mountPath: "/source"},
                {name: "dest", mountPath: "/dest"}
              ]
            }],
            volumes: [
              {name: "source", persistentVolumeClaim: {claimName: $pvc}},
              {name: "dest", persistentVolumeClaim: {claimName: $new_pvc}}
            ]
          }
        }' | kubectl apply -f -
    echo "Waiting for migration pod..."
    kubectl wait pod/pvc-migrate-temp -n "$ns" --for=condition=Ready --timeout=120s
    echo "Copying data from $pvc to $new_pvc..."
    kubectl exec -n "$ns" pvc-migrate-temp -- cp -av /source/. /dest/
    kubectl delete pod pvc-migrate-temp -n "$ns"
    affected=$(kubectl get deploy,statefulset,pod,job,cronjob -n "$ns" -o json 2>/dev/null | jq -r --arg pvc "$pvc" '
      .items[] | select(.spec.template.spec.volumes[]?.persistentVolumeClaim.claimName == $pvc or .spec.volumes[]?.persistentVolumeClaim.claimName == $pvc) |
      "\(.kind)/\(.metadata.name)"
    ')
    echo ""
    echo "================================================"
    echo " Migration complete: data copied to $new_pvc"
    echo "================================================"
    echo ""
    if [ -n "$affected" ]; then
        echo "The following resources still reference the OLD PVC ($pvc):"
        echo "$affected" | sed 's/^/  /'
        echo ""
        echo "Update claimName in your manifests:"
        echo "  change: $pvc"
        echo "  to:     $new_pvc"
        echo ""
        echo "Without gitops — edit each resource directly:"
        while IFS= read -r resource; do
            kind=$(cut -d/ -f1 <<< "$resource" | tr '[:upper:]' '[:lower:]')
            name=$(cut -d/ -f2 <<< "$resource")
            echo "  kubectl edit $kind $name -n $ns"
            echo "    -> find the volume referencing $pvc and change claimName to $new_pvc"
        done <<< "$affected"
        echo ""
        echo "With gitops (ArgoCD/Flux):"
        echo "  1. just argo-pause   (pause only the affected app, not the whole cluster)"
        echo "  2. In git, in the same commit:"
        echo "     - Rename the PVC manifest from $pvc to $new_pvc"
        echo "     - Update claimName in the affected deploy/statefulset to $new_pvc"
        echo "     - Remove the old PVC manifest (or ArgoCD will recreate it empty)"
        echo "  3. Push and just argo-resume"
        echo ""
        echo "Only delete the old PVC after the workload is running on $new_pvc:"
        echo "  kubectl delete pvc $pvc -n $ns"
    else
        echo "Nothing in namespace '$ns' references $pvc (checked deploy, statefulset, pod, job, cronjob)."
        echo "Safe to delete:"
        echo "  kubectl delete pvc $pvc -n $ns"
    fi
    echo ""

# launch network debug pod
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

# get gateway,httproute
routes ns='':
    kubectl get gateway,httproute {{ if ns != '' { '-n ' + ns } else { '-A' } }}

# list container images
images ns='':
    kubectl get pods {{ if ns != '' { '-n ' + ns } else { '-A' } }} -o json | jq -r '.items[].spec.containers[].image' | sort -u

[private]
failing ns='':
    #!/bin/bash
    kubectl get pods {{ if ns != '' { '-n ' + ns } else { '-A' } }} -o json | jq -r '
      ["NAMESPACE","POD","STATUS","REASON"],
      (
        .items[]
        | select(.status.phase != "Running" and .status.phase != "Succeeded")
        | [
            .metadata.namespace,
            .metadata.name,
            .status.phase,
            ((.status.conditions // []) | map(select(.type=="Ready")) | .[0].reason) // ""
          ]
      )
      | @tsv
    ' | column -t

[private]
pending ns='':
    #!/bin/bash
    kubectl get pods {{ if ns != '' { '-n ' + ns } else { '-A' } }} -o json | jq -r '
      ["NAMESPACE","POD","REASON","MESSAGE"],
      (
        .items[]
        | select(.status.phase=="Pending")
        | (.status.conditions // []) as $conds
        | [
            .metadata.namespace,
            .metadata.name,
            ($conds | map(select(.type=="PodScheduled")) | .[0].reason) // "unknown",
            ($conds | map(select(.type=="PodScheduled")) | .[0].message) // ""
          ]
      )
      | @tsv
    ' | column -t

[private]
restarts ns='':
    #!/bin/bash
    kubectl get pods {{ if ns != '' { '-n ' + ns } else { '-A' } }} -o json | jq -r '
      ["NAMESPACE","POD","CONTAINER","RESTARTS"],
      (
        .items[]
        | .metadata.namespace as $ns
        | .metadata.name as $pod
        | .status.containerStatuses[]?
        | select(.restartCount > 0)
        | [$ns, $pod, .name, (.restartCount|tostring)]
      )
      | @tsv
    ' | column -t | (read -r header; echo "$header"; sort -k4 -rn)

# get argocd admin password
argo-admin:
    @kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d && echo

# delete an argocd app (cascade deletes all cluster resources)
argo-delete:
    #!/bin/bash
    app=$(argocd app list -o name 2>/dev/null | fzf --prompt="app> " --height=40%)
    [ -z "$app" ] && exit 0
    read -p "Delete '$app' and all its cluster resources? [y/N]: " confirm
    [[ "$confirm" =~ ^[Yy]$ ]] || exit 0
    argocd app delete "$app" --cascade

# sync an argocd app (requires: argocd CLI logged in)
argo-sync:
    #!/bin/bash
    app=$(argocd app list -o name 2>/dev/null | fzf --prompt="app> " --height=40%)
    [ -z "$app" ] && exit 0
    argocd app sync "$app"

# disable auto-sync for an argocd app
argo-pause:
    #!/bin/bash
    app=$(argocd app list -o name 2>/dev/null | fzf --prompt="app> " --height=40%)
    [ -z "$app" ] && exit 0
    argocd app set "$app" --sync-policy none
    echo "Auto-sync disabled for $app"

# re-enable auto-sync for an argocd app
argo-resume:
    #!/bin/bash
    app=$(argocd app list -o name 2>/dev/null | fzf --prompt="app> " --height=40%)
    [ -z "$app" ] && exit 0
    argocd app set "$app" --sync-policy automated
    echo "Auto-sync enabled for $app"

# disable auto-sync for ALL argocd apps
argo-pause-all:
    #!/bin/bash
    apps=$(argocd app list -o name 2>/dev/null)
    [ -z "$apps" ] && echo "no apps found" && exit 1
    while IFS= read -r app; do
        echo "Pausing $app..."
        argocd app set "$app" --sync-policy none
    done <<< "$apps"
    echo "All apps paused."

# re-enable auto-sync for ALL argocd apps
argo-resume-all:
    #!/bin/bash
    apps=$(argocd app list -o name 2>/dev/null)
    [ -z "$apps" ] && echo "no apps found" && exit 1
    while IFS= read -r app; do
        echo "Resuming $app..."
        argocd app set "$app" --sync-policy automated
    done <<< "$apps"
    echo "All apps resumed."

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

