#!/usr/bin/env bash
set -u
PASS=0; FAIL=0
ok(){ echo "  PASS  $1"; PASS=$((PASS+1)); }
bad(){ echo "  FAIL  $1"; FAIL=$((FAIL+1)); }
has(){ oc "$@" >/dev/null 2>&1; }
mark(){ q=$1; echo; echo "=== Q$q ==="; case $q in
1) has get project crimson && ok "project crimson" || bad "project crimson"; has -n crimson get bc pastebin && ok "BuildConfig pastebin" || bad "BuildConfig pastebin"; [ "$(oc -n crimson get bc pastebin -o jsonpath='{.spec.strategy.type}' 2>/dev/null)" = Source ] && ok "Source/S2I strategy" || bad "Source/S2I strategy"; has -n crimson get route pastebin && ok "route" || bad "route";;
2) has get project container-build && ok "project" || bad "project"; [ "$(oc -n container-build get bc container-app -o jsonpath='{.spec.strategy.type}' 2>/dev/null)" = Docker ] && ok "Docker strategy" || bad "Docker strategy"; [ "$(oc -n container-build get bc container-app -o jsonpath='{.spec.strategy.dockerStrategy.dockerfilePath}' 2>/dev/null)" = 'container/Containerfile.exam' ] && ok "Containerfile path" || bad "Containerfile path"; has -n container-build get is container-app && ok "ImageStream" || bad "ImageStream";;
3) has -n s2i-custom get bc oxy && ok "BuildConfig oxy" || bad "BuildConfig oxy"; [ "$(oc -n s2i-custom get bc oxy -o jsonpath='{.spec.strategy.type}' 2>/dev/null)" = Source ] && ok "Source strategy" || bad "Source strategy"; has -n s2i-custom get route oxy && ok "route" || bad "route";;
4) has -n acid get cm sedicen && ok "ConfigMap" || bad "ConfigMap"; has -n acid get secret phosphoric-secret && ok "Secret" || bad "Secret"; has -n acid get deploy phosphoric && ok "Deployment" || bad "Deployment";;
5) has -n health-lab get deploy health-app && ok "Deployment" || bad "Deployment"; d=$(oc -n health-lab get deploy health-app -o json 2>/dev/null || echo '{}'); echo "$d" | grep -q startupProbe && ok "startup probe" || bad "startup probe"; echo "$d" | grep -q livenessProbe && ok "liveness probe" || bad "liveness probe"; echo "$d" | grep -q readinessProbe && ok "readiness probe" || bad "readiness probe";;
6) has -n templating get bc templated-app && ok "build template resources" || bad "build template resources"; has -n templating get deploy templated-app && ok "deploy template resources" || bad "deploy template resources"; [ "$(oc -n templating get deploy templated-app -o jsonpath='{.spec.replicas}' 2>/dev/null)" = 2 ] && ok "2 replicas" || bad "2 replicas";;
7) helm status dualweb -n helm-multi >/dev/null 2>&1 && ok "Helm release" || bad "Helm release"; [ "$(oc -n helm-multi get deploy dualweb -o jsonpath='{.spec.template.spec.containers[*].name}' 2>/dev/null)" = 'writer web' ] && ok "two containers" || bad "two containers";;
8) has -n cicd get pipeline build && ok "build pipeline" || bad "build pipeline"; has -n cicd get pipeline deploy && ok "deploy pipeline" || bad "deploy pipeline"; [ "$(oc -n cicd get pipelinerun --no-headers 2>/dev/null | wc -l | tr -d ' ')" -ge 2 ] && ok "PipelineRun history" || bad "PipelineRun history";; esac; }
args=("$@"); [ $# -gt 0 ] || args=(all)
if [ "${args[0]}" = all ]; then for q in {1..8}; do mark $q; done; else for a in "${args[@]}"; do if [[ $a =~ ^([1-8])-([1-8])$ ]]; then for q in $(seq ${BASH_REMATCH[1]} ${BASH_REMATCH[2]}); do mark $q; done; else mark "$a"; fi; done; fi
echo; echo "SUMMARY: $PASS checks passed, $FAIL failed"; [ $FAIL -eq 0 ]
