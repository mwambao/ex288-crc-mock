#!/usr/bin/env bash
set -euo pipefail
echo "Preparing only shared lab infrastructure; exam projects are intentionally NOT pre-created."
if oc auth can-i create projects.project.openshift.io 2>/dev/null | grep -q yes; then
  oc get project lab-infra >/dev/null 2>&1 || oc new-project lab-infra >/dev/null
  oc apply -n lab-infra -f q2-containerfile/artifact-server.yaml
  oc rollout status -n lab-infra deployment/artifactory-mock --timeout=180s
else
  echo "WARN: current user cannot create lab-infra. Run setup once as kubeadmin/admin."
fi
echo "Shared infrastructure ready. Create task projects yourself during the mock."
