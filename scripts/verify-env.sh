#!/usr/bin/env bash
set -u
pass(){ printf 'PASS  %s\n' "$*"; }
fail(){ printf 'FAIL  %s\n' "$*"; failures=$((failures+1)); }
failures=0

command -v oc >/dev/null 2>&1 && pass "oc CLI found" || { echo "FAIL  oc CLI missing"; exit 1; }
command -v helm >/dev/null 2>&1 && pass "Helm CLI found: $(helm version --short 2>/dev/null)" || fail "Helm CLI missing"
oc kustomize --help >/dev/null 2>&1 && pass "oc kustomize available" || fail "oc kustomize unavailable"
oc api-resources 2>/dev/null | grep -q '^buildconfigs' && pass "BuildConfig API available" || fail "BuildConfig API unavailable"
oc api-resources 2>/dev/null | grep -q '^imagestreams' && pass "ImageStream API available" || fail "ImageStream API unavailable"
oc get crd pipelines.tekton.dev >/dev/null 2>&1 && pass "Tekton Pipeline CRD installed" || fail "Tekton Pipeline CRD missing"
oc get crd pipelineruns.tekton.dev >/dev/null 2>&1 && pass "Tekton PipelineRun CRD installed" || fail "Tekton PipelineRun CRD missing"
oc get crd nginxgatewayfabrics.gateway.nginx.org >/dev/null 2>&1 && pass "NginxGatewayFabric CRD installed" || fail "NginxGatewayFabric CRD missing"
oc get clusteroperator image-registry >/dev/null 2>&1 && pass "OpenShift image registry operator available" || fail "Image registry operator unavailable"
default_sc=$(oc get storageclass -o jsonpath='{range .items[?(@.metadata.annotations.storageclass\.kubernetes\.io/is-default-class=="true")]}{.metadata.name}{" "}{end}' 2>/dev/null)
[[ -n "$default_sc" ]] && pass "Default StorageClass: $default_sc" || fail "No default StorageClass detected"
for is in nodejs python php httpd; do oc get is "$is" -n openshift >/dev/null 2>&1 && pass "Builder ImageStream: $is" || fail "Missing openshift/$is ImageStream"; done

if (( failures )); then
  echo
  echo "$failures environment check(s) failed. See docs/PREREQUISITES.md."
  exit 1
fi
echo
echo "Environment checks passed."
