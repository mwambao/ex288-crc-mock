#!/usr/bin/env bash
set -u

pass(){ printf 'PASS  %s\n' "$*"; }
warn(){ printf 'WARN  %s\n' "$*"; }
fail(){ printf 'FAIL  %s\n' "$*"; failures=$((failures+1)); }
failures=0

command -v oc >/dev/null 2>&1 && pass "oc CLI found" || { echo "FAIL  oc CLI missing"; exit 1; }
command -v helm >/dev/null 2>&1 && pass "Helm CLI found: $(helm version --short 2>/dev/null)" || fail "Helm CLI missing"
oc kustomize --help >/dev/null 2>&1 && pass "oc kustomize available" || fail "oc kustomize unavailable"

who=$(oc whoami 2>/dev/null || true)
[[ -n "$who" ]] && pass "Logged in as: $who" || fail "Not logged in to OpenShift"

# Developer-safe API discovery checks. These do not require permission to list CRD objects.
oc api-resources 2>/dev/null | grep -q '^buildconfigs' && pass "BuildConfig API available" || fail "BuildConfig API unavailable"
oc api-resources 2>/dev/null | grep -q '^imagestreams' && pass "ImageStream API available" || fail "ImageStream API unavailable"
oc api-resources --api-group=tekton.dev 2>/dev/null | awk '{print $1}' | grep -qx 'pipelines' \
  && pass "Tekton Pipeline API available" || fail "Tekton Pipeline API missing"
oc api-resources --api-group=tekton.dev 2>/dev/null | awk '{print $1}' | grep -qx 'pipelineruns' \
  && pass "Tekton PipelineRun API available" || fail "Tekton PipelineRun API missing"
oc api-resources --api-group=gateway.nginx.org 2>/dev/null | awk '{print $1}' | grep -qx 'nginxgatewayfabrics' \
  && pass "NginxGatewayFabric API available" || fail "NginxGatewayFabric API missing"

# The image-registry ClusterOperator is cluster-scoped and normal developers commonly cannot read it.
# Perform the strong check when authorized; otherwise verify that the registry operator API exists.
if oc auth can-i get clusteroperators.config.openshift.io/image-registry >/dev/null 2>&1 \
   && [[ "$(oc auth can-i get clusteroperators.config.openshift.io/image-registry 2>/dev/null)" == "yes" ]]; then
  oc get clusteroperator image-registry >/dev/null 2>&1 \
    && pass "OpenShift image registry operator available" \
    || fail "Image registry operator unavailable"
else
  if oc api-resources --api-group=imageregistry.operator.openshift.io 2>/dev/null | grep -q '^configs'; then
    warn "Registry operator health check skipped (current user lacks cluster-admin access); Image Registry API is present"
  else
    fail "Image Registry Operator API unavailable"
  fi
fi

default_sc=$(oc get storageclass -o jsonpath='{range .items[?(@.metadata.annotations.storageclass\.kubernetes\.io/is-default-class=="true")]}{.metadata.name}{" "}{end}' 2>/dev/null || true)
[[ -n "$default_sc" ]] && pass "Default StorageClass: $default_sc" || warn "Could not detect default StorageClass with current permissions"

for is in nodejs python php httpd; do
  oc get is "$is" -n openshift >/dev/null 2>&1 \
    && pass "Builder ImageStream: $is" \
    || fail "Missing or inaccessible openshift/$is ImageStream"
done

if (( failures )); then
  echo
  echo "$failures environment check(s) failed. See docs/PREREQUISITES.md."
  exit 1
fi

echo
if [[ "$who" == "kubeadmin" ]] || [[ "$(oc auth can-i '*' '*' --all-namespaces 2>/dev/null || true)" == "yes" ]]; then
  echo "Environment checks passed (cluster-admin verification)."
else
  echo "Environment checks passed for the developer account."
  echo "For full cluster-health checks, rerun this script once as kubeadmin."
fi
