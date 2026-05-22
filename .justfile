# list recipes
default:
    just --list --unsorted

# get + top nodes with last ready time
nodes:
    #!/bin/bash
    node_data=$(kubectl get nodes -o json \
        | jq -r '.items[] | (.status.conditions[] | select(.type=="Ready")) as $ready | [.metadata.name, (if $ready.status=="True" then "Ready" else "NotReady" end), .status.nodeInfo.kubeletVersion, $ready.lastTransitionTime] | @tsv')
    top_data=$(kubectl top nodes --no-headers)
    (
        echo -e "NAME\tSTATUS\tVERSION\tLAST-READY\tCPU\tCPU%\tMEM\tMEM%"
        while IFS=$'\t' read -r name status version last_ready; do
            top_line=$(grep "^$name " <<< "$top_data")
            cpu=$(awk '{print $2}' <<< "$top_line")
            cpu_pct=$(awk '{print $3}' <<< "$top_line")
            mem=$(awk '{print $4}' <<< "$top_line")
            mem_pct=$(awk '{print $5}' <<< "$top_line")
            echo -e "$name\t$status\t$version\t$last_ready\t${cpu:--}\t${cpu_pct:--}\t${mem:--}\t${mem_pct:--}"
        done <<< "$node_data"
    ) | column -t

# cluster events sorted by time (kyverno=true to include kyverno events, n=0 for all)
events ns='' kyverno='false' n='10':
    kubectl get events {{ if ns != '' { '-n ' + ns } else { '-A' } }} \
    --field-selector type=Warning -o json \
    | jq -r --argjson kyverno {{kyverno}} --argjson n {{n}} \
    '[.items[] | select($kyverno or .metadata.namespace != "kyverno")] | sort_by(.lastTimestamp) | if $n > 0 then .[-$n:] else . end | .[] | "\(.lastTimestamp)\t\(.metadata.namespace)\t\(.type)\t\(.reason)\t\(.involvedObject.name)\t\(.message)"'

# pending, failing and restarting pods
issues ns='':
    just pending {{ns}}
    @echo
    just failing {{ns}}
    @echo
    just restarts {{ns}}

# get pods with last ready time
pods ns='':
    #!/bin/bash
    echo "kubectl get pods {{ if ns != '' { '-n ' + ns } else { '-A' } }} -o json | jq | column -t"
    kubectl get pods {{ if ns != '' { '-n ' + ns } else { '-A' } }} -o json \
        | jq -r '["NAMESPACE","POD","STATUS","RESTARTS","READY-SINCE","NODE"],(.items[]|(.status.conditions[]?|select(.type=="Ready")) as $ready|(.status.containerStatuses//[]|map(.restartCount)|add//0) as $restarts|[.metadata.namespace,.metadata.name,.status.phase,($restarts|tostring),($ready.lastTransitionTime//"-"),(.spec.nodeName//"-")])|@tsv' \
        | column -t

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

# pod CPU/memory usage
top ns='':
    kubectl top pods {{ if ns != '' { '-n ' + ns } else { '-A' } }} --sort-by=memory

# VPA resource recommendations (target CPU/memory per container)
vpa ns='':
    #!/bin/bash
    echo "kubectl get vpa {{ if ns != '' { '-n ' + ns } else { '-A' } }} -o json | jq | column -t"
    kubectl get vpa {{ if ns != '' { '-n ' + ns } else { '-A' } }} -o json \
        | jq -r '["NAMESPACE","VPA","CONTAINER","TARGET-CPU","TARGET-MEM","MIN-CPU","MIN-MEM","MAX-CPU","MAX-MEM"],(.items[]|.metadata.namespace as $ns|.metadata.name as $name|(.status.recommendation.containerRecommendations//[]|.[]|[$ns,$name,.containerName,(.target.cpu//"-"),(.target.memory//"-"),(.lowerBound.cpu//"-"),(.lowerBound.memory//"-"),(.upperBound.cpu//"-"),(.upperBound.memory//"-")]))|@tsv' \
        | column -t

# port-forward a service
forward ns='':
    #!/bin/bash
    if [ -z "{{ns}}" ]; then
        ns=$(kubectl get ns --no-headers | awk '{print $1}' | fzf --prompt="ns> " --height=40%)
    else
        ns="{{ns}}"
    fi
    [ -z "$ns" ] && exit 0
    svc=$(kubectl get svc -n "$ns" --no-headers | fzf --prompt="svc> " --height=40% | awk '{print $1}')
    [ -z "$svc" ] && exit 0
    svc_port=$(kubectl get svc "$svc" -n "$ns" -o jsonpath='{.spec.ports[0].port}')
    echo "kubectl port-forward svc/$svc -n $ns 8080:$svc_port"
    echo "Open: http://localhost:8080"
    kubectl port-forward svc/"$svc" -n "$ns" "8080:$svc_port"

# decode a secret
secrets ns='':
    #!/bin/bash
    if [ -z "{{ns}}" ]; then
        ns=$(kubectl get ns --no-headers | awk '{print $1}' | fzf --prompt="ns> " --height=40%)
    else
        ns="{{ns}}"
    fi
    [ -z "$ns" ] && exit 0
    secret=$(kubectl get secret -n "$ns" --no-headers | fzf --prompt="secret> " --height=40% | awk '{print $1}')
    [ -z "$secret" ] && exit 0
    kubectl get secret "$secret" -n "$ns" -o json | jq -r '
      .data // {} | to_entries[] | "\(.key): \(.value | @base64d)"
    '

[private]
failing ns='':
    #!/bin/bash
    kubectl get pods {{ if ns != '' { '-n ' + ns } else { '-A' } }} -o json | jq -r '
      ["NAMESPACE","POD","REASON","FAILING-SINCE"],
      (
        .items[]
        | select(.status.phase != "Running" and .status.phase != "Succeeded")
        | [
            .metadata.namespace,
            .metadata.name,
            (
              (.status.containerStatuses // [] | map(.state.terminated.reason // .state.waiting.reason // empty) | first) //
              .status.reason //
              "-"
            ),
            ((.status.conditions // []) | map(select(.type=="Ready")) | .[0].lastTransitionTime) // (.metadata.creationTimestamp // "-")
          ]
      )
      | @tsv
    ' | column -t | (read -r header; echo "$header"; sort -k4)

[private]
pending ns='':
    #!/bin/bash
    kubectl get pods {{ if ns != '' { '-n ' + ns } else { '-A' } }} -o json | jq -r '
      ["NAMESPACE","POD","REASON","PENDING-SINCE","MESSAGE"],
      (
        .items[]
        | select(.status.phase=="Pending")
        | (.status.conditions // []) as $conds
        | [
            .metadata.namespace,
            .metadata.name,
            ($conds | map(select(.type=="PodScheduled")) | .[0].reason) // "unknown",
            (.metadata.creationTimestamp // "-"),
            ($conds | map(select(.type=="PodScheduled")) | .[0].message) // "-"
          ]
      )
      | @tsv
    ' | column -t | (read -r header; echo "$header"; sort -k4)

[private]
restarts ns='':
    #!/bin/bash
    kubectl get pods {{ if ns != '' { '-n ' + ns } else { '-A' } }} -o json | jq -r '
      ["NAMESPACE","POD","CONTAINER","RESTARTS","LAST-RESTART"],
      (
        .items[]
        | .metadata.namespace as $ns
        | .metadata.name as $pod
        | .status.containerStatuses[]?
        | select(.restartCount > 0)
        | [$ns, $pod, .name, (.restartCount|tostring), (.lastState.terminated.finishedAt // "-")]
      )
      | @tsv
    ' | column -t | (read -r header; echo "$header"; sort -k5)

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

# get argocd admin password
argo-admin:
    @kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d && echo

# login to argocd (port-forwards argocd-server, logs in, then you can use other argo-* recipes)
argo-login:
    #!/bin/bash
    password=$(kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d)
    echo "Port-forwarding argocd-server to localhost:8080..."
    kubectl port-forward svc/argocd-server -n argocd 8080:443 &>/dev/null &
    pf_pid=$!
    for i in $(seq 1 50); do nc -z localhost 8080 2>/dev/null && break; sleep 0.5; done
    sleep 2
    argocd login localhost:8080 --username admin --password "$password" --insecure
    kill $pf_pid 2>/dev/null
    echo "Logged in. Run just argo-* recipes now."

# delete an argocd app
argo-delete:
    #!/bin/bash
    app=$(argocd app list -o name 2>/dev/null | fzf --prompt="app> " --height=40%)
    [ -z "$app" ] && exit 0
    read -p "Delete '$app' and all its cluster resources? [y/N]: " confirm
    [[ "$confirm" =~ ^[Yy]$ ]] || exit 0
    argocd app delete "$app" --cascade

# sync an argocd app
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

# delete evicted/error/completed pods and unbound PVCs/PVs older than N days (default: 30)
clean-cluster days='30':
    #!/bin/bash
    min_age=$(( {{days}} * 86400 ))
    echo "==> [1/4] Deleting completed/failed pods older than {{days}} days..."
    while IFS=$'\t' read -r ns name; do
        echo "    pod $ns/$name"
        kubectl delete pod -n "$ns" "$name" --wait=false
        sleep 0.05
    done < <(kubectl get pods -A -o json | jq -r --argjson min_age "$min_age" '
      .items[] |
      select(
        (.status.phase == "Failed" or .status.phase == "Succeeded") and
        (now - (.metadata.creationTimestamp | fromdateiso8601)) > $min_age
      ) |
      [.metadata.namespace, .metadata.name] | @tsv
    ')
    echo "==> [2/4] Building PVC usage map from all workloads..."
    used=$(kubectl get pods,statefulsets,deployments,daemonsets,jobs -A -o json | jq '[
      .items[] |
      (.metadata.namespace) as $ns |
      (
        .spec.volumes[]?,
        .spec.template.spec.volumes[]?
      ) |
      .persistentVolumeClaim?.claimName // empty |
      $ns + "/" + .
    ] | unique')
    cronjob_used=$(kubectl get cronjobs -A -o json | jq '[
      .items[] |
      (.metadata.namespace) as $ns |
      .spec.jobTemplate.spec.template.spec.volumes[]? |
      .persistentVolumeClaim?.claimName // empty |
      $ns + "/" + .
    ] | unique')
    sts_prefixes=$(kubectl get statefulsets -A -o json | jq '[
      .items[] |
      (.metadata.namespace) as $ns |
      (.metadata.name) as $sts |
      .spec.volumeClaimTemplates[]?.metadata.name |
      $ns + "/" + . + "-" + $sts + "-"
    ]')
    used=$(jq -n --argjson a "$used" --argjson b "$cronjob_used" '$a + $b | unique')
    echo "    PVCs in use: $(echo "$used" | jq 'length')"
    echo "    StatefulSet volumeClaimTemplate prefixes: $(echo "$sts_prefixes" | jq 'length')"
    echo "==> [3/4] PVCs to delete (older than {{days}} days)..."
    bound_pvcs=$(kubectl get pvc -A -o json | jq -r --argjson used "$used" --argjson prefixes "$sts_prefixes" --argjson min_age "$min_age" '
      .items[] |
      (.metadata.namespace + "/" + .metadata.name) as $key |
      select(
        .status.phase == "Bound" and
        ($used | index($key) == null) and
        ($prefixes | map($key | startswith(.)) | any | not) and
        (.metadata.annotations["keep-pvc"] // "" | . != "true") and
        (now - (.metadata.creationTimestamp | fromdateiso8601)) > $min_age
      ) |
      [.metadata.namespace, .metadata.name] | @tsv
    ')
    unbound_pvcs=$(kubectl get pvc -A -o json | jq -r --argjson min_age "$min_age" '
      .items[] |
      select(
        .status.phase != "Bound" and
        (now - (.metadata.creationTimestamp | fromdateiso8601)) > $min_age
      ) |
      [.metadata.namespace, .metadata.name] | @tsv
    ')
    unbound_pvs=$(kubectl get pv -o json | jq -r --argjson min_age "$min_age" '
      .items[] |
      select(
        .status.phase != "Bound" and
        (now - (.metadata.creationTimestamp | fromdateiso8601)) > $min_age
      ) |
      .metadata.name
    ')
    [ -n "$bound_pvcs" ]   && echo "$bound_pvcs"  | awk -F'\t' '{print "    pvc (bound)   " $1 "/" $2}'
    [ -n "$unbound_pvcs" ] && echo "$unbound_pvcs" | awk -F'\t' '{print "    pvc (unbound) " $1 "/" $2}'
    echo "==> [4/4] PVs to delete..."
    [ -n "$unbound_pvs" ] && echo "$unbound_pvs" | awk '{print "    pv " $1}'
    if [ -z "$bound_pvcs" ] && [ -z "$unbound_pvcs" ] && [ -z "$unbound_pvs" ]; then
        echo "    (nothing to delete)"
        echo "==> Done."
        exit 0
    fi
    echo ""
    read -r -p "Delete all of the above? [y/N] " confirm
    [[ "$confirm" =~ ^[Yy]$ ]] || { echo "Aborted."; exit 0; }
    echo "Deleting..."
    while IFS=$'\t' read -r ns name; do
        echo "    pvc $ns/$name"
        kubectl delete pvc -n "$ns" "$name" --wait=false
        sleep 0.05
    done <<< "$bound_pvcs"
    while IFS=$'\t' read -r ns name; do
        echo "    pvc $ns/$name (unbound)"
        kubectl delete pvc -n "$ns" "$name" --wait=false
        sleep 0.05
    done <<< "$unbound_pvcs"
    while read -r name; do
        echo "    pv $name"
        kubectl delete pv "$name" --wait=false
        sleep 0.05
    done <<< "$unbound_pvs"
    echo "==> Done."

