#!/usr/bin/env bash
# Read-only self-marker for the EX288 CRC mock exam.
# Compatible with macOS Bash 3.2. Does not modify cluster resources.
set -u

PASS=0
FAIL=0
WARN=0
QPASS=0
QFAIL=0
QWARN=0
TOTAL_Q=0
PASSED_Q=0
FAILED_Q=0
WARN_Q=0

say_pass(){ printf '  PASS  %s\n' "$1"; PASS=$((PASS+1)); QPASS=$((QPASS+1)); }
say_fail(){ printf '  FAIL  %s\n' "$1"; FAIL=$((FAIL+1)); QFAIL=$((QFAIL+1)); }
say_warn(){ printf '  WARN  %s\n' "$1"; WARN=$((WARN+1)); QWARN=$((QWARN+1)); }

have(){ command -v "$1" >/dev/null 2>&1; }
project_ok(){ oc get project "$1" >/dev/null 2>&1; }
res(){ oc -n "$1" get "$2" >/dev/null 2>&1; }
jp(){ oc -n "$1" get "$2" -o "jsonpath=$3" 2>/dev/null; }
http_body(){
  host="$1"
  if have curl; then
    curl -kfsS --connect-timeout 3 --max-time 8 "http://$host" 2>/dev/null || \
    curl -kfsS --connect-timeout 3 --max-time 8 "https://$host" 2>/dev/null || true
  fi
}
latest_build_name(){ oc -n "$1" get builds -l "buildconfig=$2" --sort-by=.metadata.creationTimestamp -o jsonpath='{.items[-1:].metadata.name}' 2>/dev/null; }
latest_build_phase(){ oc -n "$1" get builds -l "buildconfig=$2" --sort-by=.metadata.creationTimestamp -o jsonpath='{.items[-1:].status.phase}' 2>/dev/null; }
ready_replicas(){ v=$(jp "$1" "deployment/$2" '{.status.readyReplicas}'); [ -n "$v" ] && echo "$v" || echo 0; }

begin_q(){
  TOTAL_Q=$((TOTAL_Q+1)); QPASS=0; QFAIL=0; QWARN=0
  printf '\n=== Q%s: %s ===\n' "$1" "$2"
}
end_q(){
  if [ "$QFAIL" -gt 0 ]; then
    printf 'RESULT Q%s: FAIL (%s pass, %s fail, %s warning)\n' "$1" "$QPASS" "$QFAIL" "$QWARN"
    FAILED_Q=$((FAILED_Q+1))
  elif [ "$QWARN" -gt 0 ]; then
    printf 'RESULT Q%s: PASS WITH WARNING (%s pass, %s warning)\n' "$1" "$QPASS" "$QWARN"
    WARN_Q=$((WARN_Q+1)); PASSED_Q=$((PASSED_Q+1))
  else
    printf 'RESULT Q%s: PASS (%s checks)\n' "$1" "$QPASS"
    PASSED_Q=$((PASSED_Q+1))
  fi
}

q1(){
  begin_q 1 'Git + S2I single-container deployment'
  project_ok crdmson || say_fail 'Project crdmson is accessible'
  res crdmson bc/pastebin && say_pass 'BuildConfig pastebin exists' || say_fail 'BuildConfig pastebin exists'
  [ "$(latest_build_phase crdmson pastebin)" = Complete ] && say_pass 'Latest pastebin build is Complete' || say_fail 'Latest pastebin build is Complete'
  res crdmson deployment/pastebin && say_pass 'Deployment pastebin exists' || say_fail 'Deployment pastebin exists'
  [ "$(ready_replicas crdmson pastebin)" -ge 1 ] 2>/dev/null && say_pass 'pastebin has a ready replica' || say_fail 'pastebin has a ready replica'
  host=$(jp crdmson route/pastebin '{.spec.host}')
  [ "$host" = 'pastebin-crdmson.apps-crc.testing' ] && say_pass 'Route hostname is correct' || say_fail "Route hostname is pastebin-crdmson.apps-crc.testing (found: ${host:-none})"
  body=$(http_body "${host:-invalid}")
  printf '%s' "$body" | grep -Fq 'Per aspera ad astra' && say_pass 'Application currently displays required phrase' || say_fail 'Application currently displays Per aspera ad astra'
  end_q 1
}

q2(){
  begin_q 2 'Internal registry + publish/pull image'
  res crdmson 'imagestreamtag/registry-test:1' && say_pass 'ImageStreamTag registry-test:1 exists' || say_fail 'ImageStreamTag registry-test:1 exists in crdmson'
  if oc auth can-i get routes -n openshift-image-registry 2>/dev/null | grep -qx yes; then
    host=$(jp openshift-image-registry route/default-route '{.spec.host}')
    [ -n "$host" ] && say_pass "Registry default route exists: $host" || say_fail 'Registry default route exists'
  else
    say_warn 'Current user cannot verify the cluster-scoped/admin registry-route step; verify Q2 once as kubeadmin'
  fi
  say_warn 'Podman pull-back is a client-side action and cannot be proven from cluster state alone'
  end_q 2
}

q3(){
  begin_q 3 'Parameterized multi-container Template'
  res tndy template/ex288-web-cache && say_pass 'Template ex288-web-cache exists' || say_fail 'Template ex288-web-cache exists'
  req=$(jp tndy template/ex288-web-cache '{range .parameters[?(@.name=="APPLICATION_DOMAIN")]}{.required}{end}')
  [ "$req" = true ] && say_pass 'APPLICATION_DOMAIN is required' || say_fail 'APPLICATION_DOMAIN is required'
  res tndy deployment/web && say_pass 'Deployment web exists' || say_fail 'Deployment web exists'
  cc=$(jp tndy deployment/web '{.spec.template.spec.containers[*].name}')
  echo "$cc" | grep -qw web && echo "$cc" | grep -qw helper && say_pass 'Pod template contains web and helper containers' || say_fail 'Pod template contains both web and helper containers'
  host=$(jp tndy route/web '{.spec.host}')
  [ "$host" = 'web-tndy.apps-crc.testing' ] && say_pass 'Route hostname is correct' || say_fail "Route hostname is correct (found: ${host:-none})"
  body=$(http_body "${host:-invalid}")
  printf '%s' "$body" | grep -Fq 'Bonjour Engineers' && say_pass 'Route returns Bonjour Engineers' || say_fail 'Route returns Bonjour Engineers'
  end_q 3
}

q4(){
  begin_q 4 'Customized S2I builder workflow'
  res totain bc/oxy && say_pass 'BuildConfig oxy exists' || say_fail 'BuildConfig oxy exists'
  [ "$(latest_build_phase totain oxy)" = Complete ] && say_pass 'Latest oxy build is Complete' || say_fail 'Latest oxy build is Complete'
  host=$(jp totain route/oxy '{.spec.host}')
  [ -n "$host" ] && say_pass "Route oxy exists: $host" || say_fail 'Route oxy exists'
  root=$(http_body "${host:-invalid}")
  printf '%s' "$root" | grep -Fq 'Amor vincit omnia' && say_pass 'Root page contains required phrase' || say_fail 'Root page contains Amor vincit omnia'
  info=''
  if [ -n "$host" ] && have curl; then info=$(curl -kfsS --max-time 8 "http://$host/info.html" 2>/dev/null || curl -kfsS --max-time 8 "https://$host/info.html" 2>/dev/null || true); fi
  printf '%s' "$info" | grep -Fq 'Amor vincit omnia' && printf '%s' "$info" | grep -Eq '[0-9]{4}-[0-9]{2}-[0-9]{2}' && say_pass 'info.html contains phrase and YYYY-MM-DD date' || say_fail 'info.html contains phrase and YYYY-MM-DD date'
  end_q 4
}

q5(){
  begin_q 5 'Build hooks, triggers, troubleshooting'
  res octane bc/blog && say_pass 'BuildConfig blog exists' || say_fail 'BuildConfig blog exists'
  hook=$(jp octane bc/blog '{.spec.postCommit.command}')
  echo "$hook" | grep -q 'mailer.py' && ! echo "$hook" | grep -q 'missing-mailer.py' && say_pass 'Post-commit hook points to mailer.py' || say_fail "Post-commit hook points to mailer.py (found: ${hook:-none})"
  trig=$(jp octane bc/blog '{.spec.triggers[*].type}')
  [ -n "$trig" ] && say_pass "BuildConfig has trigger(s): $trig" || say_fail 'BuildConfig has at least one trigger'
  b=$(latest_build_name octane blog)
  [ -n "$b" ] && [ "$(latest_build_phase octane blog)" = Complete ] && say_pass "Latest build $b is Complete" || say_fail 'Latest blog build is Complete'
  if [ -n "$b" ]; then
    logs=$(oc -n octane logs "build/$b" 2>/dev/null || true)
    printf '%s' "$logs" | grep -Fq 'MAILER_HOOK_OK' && say_pass 'Latest build logs contain MAILER_HOOK_OK' || say_fail 'Latest build logs contain MAILER_HOOK_OK'
  else
    say_fail 'A blog build exists for log verification'
  fi
  end_q 5
}

q6(){
  begin_q 6 'Application health monitoring'
  lp=$(jp octane deployment/blog '{.spec.template.spec.containers[0].livenessProbe.tcpSocket.port}')
  ld=$(jp octane deployment/blog '{.spec.template.spec.containers[0].livenessProbe.initialDelaySeconds}')
  lt=$(jp octane deployment/blog '{.spec.template.spec.containers[0].livenessProbe.timeoutSeconds}')
  rp=$(jp octane deployment/blog '{.spec.template.spec.containers[0].readinessProbe.tcpSocket.port}')
  rd=$(jp octane deployment/blog '{.spec.template.spec.containers[0].readinessProbe.initialDelaySeconds}')
  rt=$(jp octane deployment/blog '{.spec.template.spec.containers[0].readinessProbe.timeoutSeconds}')
  [ "$lp" = 8080 ] && [ "$ld" = 10 ] && [ "$lt" = 30 ] && say_pass 'Liveness TCP/8080 delay=10 timeout=30 is correct' || say_fail "Liveness probe values are correct (found port=${lp:-none} delay=${ld:-none} timeout=${lt:-none})"
  [ "$rp" = 8080 ] && [ "$rd" = 5 ] && [ "$rt" = 5 ] && say_pass 'Readiness TCP/8080 delay=5 timeout=5 is correct' || say_fail "Readiness probe values are correct (found port=${rp:-none} delay=${rd:-none} timeout=${rt:-none})"
  [ "$(ready_replicas octane blog)" -ge 1 ] 2>/dev/null && say_pass 'blog has a ready replica after rollout' || say_fail 'blog has a ready replica after rollout'
  end_q 6
}

q7(){
  begin_q 7 'ConfigMaps and Secrets'
  resp=$(jp acid configmap/sodicon '{.data.RESPONSE}')
  [ "$resp" = "Soda pop won't stop can't...." ] && say_pass 'ConfigMap sodicon RESPONSE is correct' || say_fail 'ConfigMap sodicon RESPONSE is correct'
  res acid secret/phosphorie-secret && say_pass 'Secret phosphorie-secret exists' || say_fail 'Secret phosphorie-secret exists'
  sk=$(jp acid secret/phosphorie-secret '{.data.APP_TOKEN}')
  [ -n "$sk" ] && say_pass 'Secret contains APP_TOKEN key' || say_fail 'Secret contains APP_TOKEN key'
  dep=$(oc -n acid get deployment phosphorie -o yaml 2>/dev/null || true)
  printf '%s' "$dep" | grep -q 'sodicon' && say_pass 'Deployment references sodicon' || say_fail 'Deployment references sodicon'
  printf '%s' "$dep" | grep -q 'phosphorie-secret' && say_pass 'Deployment references phosphorie-secret' || say_fail 'Deployment references phosphorie-secret'
  if printf '%s' "$dep" | grep -Fq 'crc-ex288-secret'; then say_fail 'Cleartext secret value is present in Deployment manifest'; else say_pass 'Cleartext secret value is not in Deployment manifest'; fi
  host=$(jp acid route/phosphorie '{.spec.host}')
  [ "$host" = 'phosphorie-acid.apps-crc.testing' ] && say_pass 'Route hostname is correct' || say_fail "Route hostname is correct (found: ${host:-none})"
  body=$(http_body "${host:-invalid}")
  printf '%s' "$body" | grep -Fq "Soda pop won't stop can't...." && say_pass 'Application response contains ConfigMap value' || say_fail 'Application response contains ConfigMap value'
  end_q 7
}

q8(){
  begin_q 8 'Helm multi-container application'
  if have helm; then
    stat=$(helm status helmy -n helm-lab -o json 2>/dev/null | grep -o '"status"[[:space:]]*:[[:space:]]*"[^"]*"' | head -1 || true)
    echo "$stat" | grep -q deployed && say_pass 'Helm release helmy is deployed' || say_fail 'Helm release helmy is deployed'
    hc=$(helm history helmy -n helm-lab 2>/dev/null | awk 'NR>1 && $1 ~ /^[0-9]+$/ {c++} END{print c+0}')
    [ "$hc" -ge 2 ] && say_pass 'Helm history has at least two revisions' || say_fail "Helm history has at least two revisions (found: $hc)"
  else
    say_fail 'Helm CLI is available'
  fi
  rep=$(jp helm-lab deployment/helmy '{.spec.replicas}')
  [ "$rep" = 3 ] && say_pass 'helmy is upgraded to 3 replicas' || say_fail "helmy is upgraded to 3 replicas (found: ${rep:-none})"
  cc=$(jp helm-lab deployment/helmy '{.spec.template.spec.containers[*].name}')
  [ "$(echo "$cc" | wc -w | tr -d ' ')" -eq 2 ] && say_pass 'helmy pod template has two containers' || say_fail 'helmy pod template has two containers'
  host=$(jp helm-lab route/helmy '{.spec.host}')
  body=$(http_body "${host:-invalid}")
  printf '%s' "$body" | grep -Fq 'upgraded-ex288' && say_pass 'Route returns upgraded-ex288' || say_fail 'Route returns upgraded-ex288'
  end_q 8
}

q9(){
  begin_q 9 'Kustomize deployment customization'
  rep=$(jp kustomize-lab deployment/kweb '{.spec.replicas}')
  [ "$rep" = 3 ] && say_pass 'kweb has 3 replicas' || say_fail "kweb has 3 replicas (found: ${rep:-none})"
  env=$(jp kustomize-lab deployment/kweb '{range .spec.template.spec.containers[0].env[?(@.name=="APP_ENV")]}{.value}{end}')
  [ "$env" = dev ] && say_pass 'APP_ENV=dev is applied' || say_fail "APP_ENV=dev is applied (found: ${env:-none})"
  [ "$(ready_replicas kustomize-lab kweb)" -ge 3 ] 2>/dev/null && say_pass 'Three kweb replicas are ready' || say_fail 'Three kweb replicas are ready'
  if [ -f q9-kustomize/overlays/dev/kustomization.yaml ]; then say_pass 'Kustomize overlay file is present locally'; else say_warn 'Run marker from repository root to inspect local Kustomize files'; fi
  end_q 9
}

q10(){
  begin_q 10 'BuildConfig + ImageStream + image-change trigger'
  res streams-lab bc/webbase-build && say_pass 'BuildConfig webbase-build exists' || say_fail 'BuildConfig webbase-build exists'
  strat=$(jp streams-lab bc/webbase-build '{.spec.strategy.type}')
  [ "$strat" = Docker ] && say_pass 'BuildConfig uses Docker strategy' || say_fail "BuildConfig uses Docker strategy (found: ${strat:-none})"
  out=$(jp streams-lab bc/webbase-build '{.spec.output.to.name}')
  [ "$out" = 'webbase:stable' ] && say_pass 'Build output is webbase:stable' || say_fail "Build output is webbase:stable (found: ${out:-none})"
  res streams-lab 'imagestreamtag/webbase:stable' && say_pass 'ImageStreamTag webbase:stable exists' || say_fail 'ImageStreamTag webbase:stable exists'
  [ "$(latest_build_phase streams-lab webbase-build)" = Complete ] && say_pass 'Latest webbase-build is Complete' || say_fail 'Latest webbase-build is Complete'
  res streams-lab deployment/stream-app && say_pass 'Deployment stream-app exists' || say_fail 'Deployment stream-app exists'
  ann=$(jp streams-lab deployment/stream-app '{.metadata.annotations.image\.openshift\.io/triggers}')
  echo "$ann" | grep -q 'webbase:stable' && say_pass 'Image-change trigger references webbase:stable' || say_fail 'Image-change trigger references webbase:stable'
  rev=$(jp streams-lab deployment/stream-app '{.metadata.annotations.deployment\.kubernetes\.io/revision}')
  [ "${rev:-0}" -ge 2 ] 2>/dev/null && say_pass "Deployment revision indicates a subsequent rollout (revision $rev)" || say_fail "Deployment revision is at least 2 after rebuild (found: ${rev:-none})"
  end_q 10
}

q11(){
  begin_q 11 'Deployment troubleshooting + web console'
  sel=$(jp troubleshoot-lab service/broken-web '{.spec.selector.app}')
  [ "$sel" = broken-web ] && say_pass 'Service selector is repaired to app=broken-web' || say_fail "Service selector is app=broken-web (found: ${sel:-none})"
  eps=$(jp troubleshoot-lab endpoints/broken-web '{.subsets[0].addresses[0].ip}')
  [ -n "$eps" ] && say_pass "Service has a populated endpoint: $eps" || say_fail 'Service has a populated endpoint'
  rep=$(jp troubleshoot-lab deployment/broken-web '{.spec.replicas}')
  ready=$(ready_replicas troubleshoot-lab broken-web)
  [ "$rep" = 2 ] && [ "$ready" -ge 2 ] 2>/dev/null && say_pass 'broken-web is scaled to 2 ready replicas' || say_fail "broken-web is scaled to 2 ready replicas (desired=${rep:-none}, ready=$ready)"
  say_warn 'The marker cannot prove that scaling was performed through the OpenShift web console; this is a manual exam requirement'
  end_q 11
}

q12(){
  begin_q 12 'Multi-container application'
  rep=$(jp multi-lab deployment/multi '{.spec.replicas}')
  [ "$rep" = 2 ] && say_pass 'multi is scaled to 2 replicas' || say_fail "multi is scaled to 2 replicas (found: ${rep:-none})"
  cc=$(jp multi-lab deployment/multi '{.spec.template.spec.containers[*].name}')
  echo "$cc" | grep -qw writer && echo "$cc" | grep -qw reader && say_pass 'Pod template has writer and reader containers' || say_fail 'Pod template has writer and reader containers'
  ed=$(jp multi-lab deployment/multi '{.spec.template.spec.volumes[?(@.name=="shared")].emptyDir}')
  [ -n "$ed" ] || vol=$(oc -n multi-lab get deployment multi -o yaml 2>/dev/null | grep -A2 'name: shared' || true)
  echo "${ed:-}${vol:-}" | grep -q 'emptyDir' && say_pass 'Shared volume uses emptyDir' || say_fail 'Shared volume uses emptyDir'
  pods=$(oc -n multi-lab get pod -l app=multi -o name 2>/dev/null || true)
  ok=0
  for p in $pods; do
    logs=$(oc -n multi-lab logs "$p" -c reader --tail=20 2>/dev/null || true)
    echo "$logs" | grep -q 'multi-container-ok' && ok=$((ok+1))
  done
  [ "$ok" -ge 2 ] && say_pass 'Reader logs show multi-container-ok in both replicas' || say_fail "Reader logs show multi-container-ok in both replicas (verified: $ok)"
  end_q 12
}

q13(){
  begin_q 13 'Define and trigger Tekton CI/CD workflow'
  res pipeline-lab task/echo-message && say_pass 'Task echo-message exists' || say_fail 'Task echo-message exists'
  res pipeline-lab pipeline/ex288-pipeline && say_pass 'Pipeline ex288-pipeline exists' || say_fail 'Pipeline ex288-pipeline exists'
  pref=$(jp pipeline-lab pipeline/ex288-pipeline '{.spec.tasks[0].taskRef.name}')
  [ "$pref" = echo-message ] && say_pass 'Pipeline references Task echo-message' || say_fail "Pipeline references Task echo-message (found: ${pref:-none})"
  found=0
  for pr in $(oc -n pipeline-lab get pipelinerun -o name 2>/dev/null); do
    ref=$(jp pipeline-lab "$pr" '{.spec.pipelineRef.name}')
    msg=$(jp pipeline-lab "$pr" '{range .spec.params[?(@.name=="message")]}{.value}{end}')
    suc=$(jp pipeline-lab "$pr" '{range .status.conditions[?(@.type=="Succeeded")]}{.status}{end}')
    if [ "$ref" = ex288-pipeline ] && [ "$msg" = crc-pipeline-success ] && [ "$suc" = True ]; then found=1; break; fi
  done
  [ "$found" -eq 1 ] && say_pass 'A successful PipelineRun used message=crc-pipeline-success' || say_fail 'A successful PipelineRun used message=crc-pipeline-success'
  end_q 13
}

q14(){
  begin_q 14 'Troubleshoot a Tekton workflow'
  found=0
  for pr in $(oc -n pipeline-lab get pipelinerun -o name 2>/dev/null); do
    ref=$(jp pipeline-lab "$pr" '{.spec.pipelineRef.name}')
    msg=$(jp pipeline-lab "$pr" '{range .spec.params[?(@.name=="message")]}{.value}{end}')
    suc=$(jp pipeline-lab "$pr" '{range .status.conditions[?(@.type=="Succeeded")]}{.status}{end}')
    if [ "$ref" = ex288-pipeline ] && [ "$msg" = fixed-pipeline-ok ] && [ "$suc" = True ]; then found=1; break; fi
  done
  [ "$found" -eq 1 ] && say_pass 'A corrected PipelineRun succeeded with fixed-pipeline-ok' || say_fail 'A corrected PipelineRun succeeded with fixed-pipeline-ok'
  if [ -f q14-pipeline-debug/broken-pipelinerun.yaml ]; then
    grep -q 'ex288-pipline' q14-pipeline-debug/broken-pipelinerun.yaml && say_pass 'Original supplied broken file remains available for diagnosis' || say_warn 'Original broken fixture appears modified; normally correct it into a new file'
  else
    say_warn 'Run marker from repository root to inspect the supplied broken fixture'
  fi
  end_q 14
}

q15(){
  begin_q 15 'Application from an installed Operator'
  res operator-lab nginxgatewayfabric/exam-gateway && say_pass 'NginxGatewayFabric exam-gateway exists' || say_fail 'NginxGatewayFabric exam-gateway exists'
  init=$(jp operator-lab nginxgatewayfabric/exam-gateway '{range .status.conditions[?(@.type=="Initialized")]}{.status}{end}')
  dep=$(jp operator-lab nginxgatewayfabric/exam-gateway '{range .status.conditions[?(@.type=="Deployed")]}{.status}{end}')
  reason=$(jp operator-lab nginxgatewayfabric/exam-gateway '{range .status.conditions[?(@.type=="Deployed")]}{.reason}{end}')
  [ "$init" = True ] && say_pass 'Operator reports Initialized=True' || say_fail "Operator reports Initialized=True (found: ${init:-none})"
  [ "$dep" = True ] && [ "$reason" = InstallSuccessful ] && say_pass 'Operator reports Deployed=True / InstallSuccessful' || say_fail "Operator reports Deployed=True / InstallSuccessful (found: ${dep:-none}/${reason:-none})"
  [ "$(ready_replicas operator-lab exam-gateway-nginx-gateway-fabric)" -ge 1 ] 2>/dev/null && say_pass 'Operator-managed controller Deployment has a ready replica' || say_fail 'Operator-managed controller Deployment has a ready replica'
  res operator-lab service/exam-gateway-nginx-gateway-fabric && say_pass 'Operator-managed Service exists' || say_fail 'Operator-managed Service exists'
  res operator-lab nginxgateway/exam-gateway-config && say_pass 'Operator-managed NginxGateway exists' || say_fail 'Operator-managed NginxGateway exists'
  res operator-lab nginxproxy/exam-gateway-proxy-config && say_pass 'Operator-managed NginxProxy exists' || say_fail 'Operator-managed NginxProxy exists'
  if oc auth can-i get gatewayclasses.gateway.networking.k8s.io 2>/dev/null | grep -qx yes; then
    oc get gatewayclass nginx >/dev/null 2>&1 && say_pass 'GatewayClass nginx exists' || say_fail 'GatewayClass nginx exists'
  else
    say_warn 'Current user cannot verify cluster-scoped GatewayClass nginx'
  fi
  end_q 15
}

usage(){
  cat <<'TXT'
Usage:
  ./scripts/mark.sh 5          Mark one question
  ./scripts/mark.sh 1 3 7     Mark selected questions
  ./scripts/mark.sh 1-5       Mark a range
  ./scripts/mark.sh all       Mark all 15 questions

The script is read-only. PASS/FAIL is based on observable cluster state.
WARN means a requirement cannot be fully proven automatically (for example,
a web-console action or a client-side Podman pull).
TXT
}

expand_arg(){
  a="$1"
  case "$a" in
    all) seq 1 15 ;;
    *-*)
      s=${a%-*}; e=${a#*-}
      case "$s:$e" in *[!0-9:]*|'') return 1;; esac
      i=$s; while [ "$i" -le "$e" ]; do echo "$i"; i=$((i+1)); done ;;
    *) echo "$a" ;;
  esac
}

if ! have oc; then echo 'ERROR: oc CLI not found.' >&2; exit 2; fi
if ! oc whoami >/dev/null 2>&1; then echo 'ERROR: Not logged in to OpenShift. Run oc login first.' >&2; exit 2; fi
if [ "$#" -eq 0 ]; then usage; exit 2; fi

questions=''
for a in "$@"; do
  vals=$(expand_arg "$a") || { echo "Invalid argument: $a" >&2; usage; exit 2; }
  questions="$questions $vals"
done

for q in $questions; do
  case "$q" in
    1) q1;; 2) q2;; 3) q3;; 4) q4;; 5) q5;; 6) q6;; 7) q7;; 8) q8;;
    9) q9;; 10) q10;; 11) q11;; 12) q12;; 13) q13;; 14) q14;; 15) q15;;
    *) echo "Invalid question number: $q (valid: 1-15)" >&2; exit 2;;
  esac
done

printf '\n================ MARKING SUMMARY ================\n'
printf 'Questions checked : %s\n' "$TOTAL_Q"
printf 'Questions passed  : %s\n' "$PASSED_Q"
printf 'Questions failed  : %s\n' "$FAILED_Q"
printf 'Passed w/warning  : %s\n' "$WARN_Q"
printf 'Individual checks : %s PASS, %s FAIL, %s WARN\n' "$PASS" "$FAIL" "$WARN"
if [ "$FAILED_Q" -gt 0 ]; then
  printf 'OVERALL: FAIL — review the failed checks above.\n'
  exit 1
fi
printf 'OVERALL: PASS'
[ "$WARN" -gt 0 ] && printf ' WITH WARNING(S)'
printf '\n'
exit 0
