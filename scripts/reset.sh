#!/usr/bin/env bash
set -euo pipefail
for p in crimson container-build s2i-custom acid health-lab templating helm-multi cicd; do oc delete project "$p" --ignore-not-found=true; done
echo "Exam projects removed. lab-infra and cluster-wide operators are preserved."
