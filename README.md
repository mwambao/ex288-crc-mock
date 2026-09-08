# EX288 CRC Mock Lab — OCP 4.18-style

This lab is designed around the current EX288 objective areas and has been validated on a CRC/OpenShift 4.21.8 practice cluster. The exam target used when the lab was authored is OCP 4.18, so minor CLI/API/image-tag differences are possible.

## First-time or rebuilt CRC environment

If you deleted/recreated CRC, start with **`docs/PREREQUISITES.md`**. It covers the complete environment rebuild: CRC startup, admin/developer access, OperatorHub checks, OpenShift Pipelines/Tekton, NGINX Gateway Fabric for Q15, Helm, Kustomize, ImageStreams/builders, registry, storage, Git repositories, lab projects, and final validation.

Quick path after CRC itself is running:

1. `eval $(crc oc-env)`
2. Log in as a cluster administrator.
3. Run `./scripts/bootstrap-crc.sh` to install/check cluster-wide prerequisites.
4. Run `./scripts/verify-env.sh` and resolve any FAIL results.
5. Push the four directories under `repos/` to Git repositories reachable by CRC and replace the `<...-GIT-URL>` placeholders in the exam.
6. Log in as `developer` and run `./scripts/setup.sh` to create/reset the per-question lab resources.
7. Attempt `docs/MOCK-EXAM.md` without opening solutions.
8. Review `docs/SOLUTIONS.md` afterward.
9. Between attempts, run `./scripts/reset.sh`, wait for project deletion, then rerun `./scripts/setup.sh`.

`reset.sh` intentionally removes only exam projects. It does **not** uninstall OpenShift Pipelines or NGINX Gateway Fabric, so you do not have to rebuild cluster-wide prerequisites after every practice attempt.
