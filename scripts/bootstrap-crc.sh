#!/usr/bin/env bash
set -euo pipefail

say(){ printf '\n==> %s\n' "$*"; }
fail(){ echo "ERROR: $*" >&2; exit 1; }

command -v oc >/dev/null || fail "oc is not in PATH. Run: eval \$(crc oc-env)"
[[ "$(oc auth can-i '*' '*' --all-namespaces 2>/dev/null || true)" == "yes" ]] || \
  fail "Log in as a cluster administrator first. Use 'crc console --credentials' to obtain CRC credentials."

say "Cluster"
oc version

say "OperatorHub catalog sources"
oc get catalogsource -n openshift-marketplace
for c in redhat-operators certified-operators; do
  oc get catalogsource "$c" -n openshift-marketplace >/dev/null || fail "Missing CatalogSource: $c"
done

say "Installing/checking Red Hat OpenShift Pipelines"
# openshift-operators normally has the global OperatorGroup used by AllNamespaces operators.
oc get namespace openshift-operators >/dev/null 2>&1 || oc create namespace openshift-operators
if ! oc get subscription openshift-pipelines-operator-rh -n openshift-operators >/dev/null 2>&1; then
  cat <<'YAML' | oc apply -f -
apiVersion: operators.coreos.com/v1alpha1
kind: Subscription
metadata:
  name: openshift-pipelines-operator-rh
  namespace: openshift-operators
spec:
  channel: latest
  installPlanApproval: Automatic
  name: openshift-pipelines-operator-rh
  source: redhat-operators
  sourceNamespace: openshift-marketplace
YAML
fi

say "Installing/checking NGINX Gateway Fabric"
oc get namespace nginx-gateway >/dev/null 2>&1 || oc create namespace nginx-gateway
if ! oc get operatorgroup nginx-gateway -n nginx-gateway >/dev/null 2>&1; then
  cat <<'YAML' | oc apply -f -
apiVersion: operators.coreos.com/v1
kind: OperatorGroup
metadata:
  name: nginx-gateway
  namespace: nginx-gateway
YAML
fi
if ! oc get subscription nginx-gateway-fabric -n nginx-gateway >/dev/null 2>&1; then
  cat <<'YAML' | oc apply -f -
apiVersion: operators.coreos.com/v1alpha1
kind: Subscription
metadata:
  name: nginx-gateway-fabric
  namespace: nginx-gateway
spec:
  channel: stable
  installPlanApproval: Automatic
  name: nginx-gateway-fabric
  source: certified-operators
  sourceNamespace: openshift-marketplace
YAML
fi

wait_csv(){
  ns="$1"; sub="$2"; label="$3"
  say "Waiting for $label CSV"
  for _ in $(seq 1 90); do
    csv=$(oc get subscription "$sub" -n "$ns" -o jsonpath='{.status.installedCSV}' 2>/dev/null || true)
    if [[ -n "$csv" ]]; then
      phase=$(oc get csv "$csv" -n "$ns" -o jsonpath='{.status.phase}' 2>/dev/null || true)
      printf '%s: %s %s\n' "$label" "$csv" "$phase"
      [[ "$phase" == "Succeeded" ]] && return 0
    fi
    sleep 5
  done
  fail "$label did not reach CSV phase Succeeded in time"
}
wait_csv openshift-operators openshift-pipelines-operator-rh "OpenShift Pipelines"
wait_csv nginx-gateway nginx-gateway-fabric "NGINX Gateway Fabric"

say "Waiting for required CRDs/APIs"
for _ in $(seq 1 60); do
  if oc get crd pipelines.tekton.dev >/dev/null 2>&1 && \
     oc get crd pipelineruns.tekton.dev >/dev/null 2>&1 && \
     oc get crd nginxgatewayfabrics.gateway.nginx.org >/dev/null 2>&1; then break; fi
  sleep 5
done
oc get crd pipelines.tekton.dev pipelineruns.tekton.dev nginxgatewayfabrics.gateway.nginx.org >/dev/null

say "Build/ImageStream APIs and sample builders"
oc api-resources | grep -E 'buildconfigs|imagestreams' || true
oc get is nodejs python php httpd mysql postgresql -n openshift || true

say "Image registry"
oc get clusteroperator image-registry
oc patch configs.imageregistry.operator.openshift.io/cluster --type=merge -p '{"spec":{"defaultRoute":false}}'

say "Storage"
oc get storageclass

say "Cluster bootstrap complete"
echo "Next: log in as developer, run ./scripts/setup.sh, then ./scripts/verify-env.sh"
