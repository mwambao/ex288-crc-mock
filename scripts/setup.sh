#!/usr/bin/env bash
set -euo pipefail
: "${CRC_API:=https://api.crc.testing:6443}"
oc login -u developer -p developer "$CRC_API" >/dev/null
for p in crdmson tndy totain octane acid helm-lab kustomize-lab streams-lab troubleshoot-lab multi-lab pipeline-lab operator-lab; do
  oc get project "$p" >/dev/null 2>&1 || oc new-project "$p" >/dev/null
done
# Seed Q5/Q6 blog using a simple public Python image; source is supplied in repos/blog for Git-based practice.
oc project octane >/dev/null
oc get deployment blog >/dev/null 2>&1 || oc create deployment blog --image=registry.access.redhat.com/ubi9/python-311 -- sleep infinity
# Seed Q11 intentionally broken deployment
oc project troubleshoot-lab >/dev/null
cat <<'YAML' | oc apply -f - >/dev/null
apiVersion: apps/v1
kind: Deployment
metadata: {name: broken-web}
spec:
  replicas: 1
  selector: {matchLabels: {app: broken-web}}
  template:
    metadata: {labels: {app: broken-web}}
    spec:
      containers:
      - name: web
        image: registry.access.redhat.com/ubi9/ubi-minimal:latest
        command: ["/bin/sh","-c","sleep 3600"]
        ports: [{containerPort: 8080}]
---
apiVersion: v1
kind: Service
metadata: {name: broken-web}
spec:
  selector: {app: WRONG}
  ports: [{port: 8080,targetPort: 8080}]
YAML
printf '\nSetup complete. Some questions intentionally require you to create resources yourself.\n'
