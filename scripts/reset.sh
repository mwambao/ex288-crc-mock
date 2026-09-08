#!/usr/bin/env bash
set -euo pipefail
projects=(crdmson tndy totain octane acid helm-lab kustomize-lab streams-lab troubleshoot-lab multi-lab pipeline-lab operator-lab)
for p in "${projects[@]}"; do oc delete project "$p" --ignore-not-found=true --wait=false; done
printf 'Projects submitted for deletion. Wait until they disappear, then run scripts/setup.sh again.\n'
