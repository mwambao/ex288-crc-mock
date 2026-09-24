# EX288 CRC Remediation Mock — 8 Questions

**Target:** Red Hat EX288 / OpenShift 4.18 style. **Time:** 3 hours. **Do not read SOLUTIONS.md during a timed attempt.**

This mock deliberately concentrates on the domains where the previous attempt scored poorly, while retaining image streams (a strong area). It is not a reconstruction of any confidential exam content. The task style is based on the public EX288 objectives and public community practice material.

## Q1 — Deploy an application from Git using S2I

Create the project yourself. Source: your Git URL for `repos/q1-pastebin`.

- Create project `crimson` and deploy application `pastebin` from Git using the OpenShift Node.js builder and **S2I/source strategy**.
- The build must use an npm registry supplied to you as `NPM_REGISTRY_URL`; configure it as build environment variable `npm_config_registry`. For this CRC lab use `https://registry.npmjs.org/`.
- The build output must be an ImageStreamTag named `pastebin:latest`, and the running workload must consume that image.
- Expose the application with a Route and verify HTTP access.
- Trigger a second build after the first succeeds and confirm build history and logs.
- Diagnose and correct any build/deployment problem rather than modifying application source code.

## Q2 — Build and deploy from a Containerfile (strategy trap)

Source: your Git URL for `repos/q2-containerfile`. A mock Artifactory service is prepared by the lab.

- Create project `container-build` yourself and create a BuildConfig named `container-app` whose source is the supplied Git repository.
- The repository contains a Containerfile at `container/Containerfile.exam`; configure the build so OpenShift uses that file and uses the **Docker strategy**, not Source/S2I.
- Pass build argument `ARTIFACT_URL=http://artifactory-mock.lab-infra.svc:8080/banner.txt` so the Containerfile can consume the supplied artifact.
- Publish the result to ImageStreamTag `container-app:1.0`, then deploy it as application `container-app`.
- Configure an image-change deployment trigger so a new successful image build can roll out the application.
- Expose and test the application; use build logs/events to correct strategy, path, or artifact-download failures.

## Q3 — Customize an S2I build

Source: your Git URL for `repos/q3-custom-s2i`.

- Create project `s2i-custom` yourself and application `oxy` using an appropriate HTTPD builder ImageStreamTag from the `openshift` namespace.
- Ensure the BuildConfig uses Source strategy and the supplied repository's `.s2i/bin/assemble` customization.
- Set build environment variable `PAGE_OWNER=developer` and confirm it is present in the BuildConfig.
- Start a build, follow its logs, and prove the custom assemble script executed.
- Deploy the resulting ImageStreamTag and expose it with a Route.
- Trigger another build and inspect build history/status so you can distinguish BuildConfig configuration from an individual Build object.

## Q4 — Application configuration with ConfigMaps and Secrets

Source: your Git URL for `repos/q4-config-app`.

- Create project `acid` yourself and deploy application `phosphoric` from the supplied Git source.
- Create ConfigMap `sedicen` containing `RESPONSE=If you can see this your configmap works`; inject it into the application without hard-coding the value in the Deployment.
- Create Secret `phosphoric-secret` containing `API_TOKEN=crc-practice-token`; inject it into the application without exposing the secret value in the pod specification.
- Confirm both values are available to the running container and that the HTTP response reports the configured response and `secret-loaded`.
- Change only the ConfigMap value to `Configuration changed successfully`, roll out a new pod, and verify the new value appears.
- Use `oc describe`, `oc set env --list`, and pod logs/events to troubleshoot a deliberately wrong key or reference if your deployment does not behave as expected.

## Q5 — Implement startup, liveness and readiness monitoring

Source: your Git URL for `repos/q5-health-app`. Deploy it as `health-app` in project `health-lab` that you create.

- Configure a **startup HTTP probe** against `/startup` on the application port; allow the application roughly half a minute to become healthy, checking every few seconds, and require more than one failed check before restart eligibility.
- Configure a **liveness HTTP probe** against `/` on the application port; do not start checking immediately, check periodically, and allow only a short response timeout.
- Configure a **readiness HTTP probe** against `/ready`; begin earlier than the liveness probe, check frequently, and remove the pod from service after repeated failures.
- For every probe, explicitly configure at least two timing/threshold fields rather than relying entirely on defaults.
- Verify the three probes in the Deployment YAML and use pod describe/events to confirm they are active.
- Demonstrate that the Deployment becomes available and the Route/Service sends traffic only to ready pods.

## Q6 — Process and customize supplied templates

Source: `repos/q6-templates/build-template.yaml` and `deploy-template.yaml` in Git. Create project `templating` yourself.

- Import/process `build-template.yaml` with `APP_NAME=templated-app`, your Q1 Git URL as `GIT_URL`, and the supplied builder parameter; apply label `exam=ex288,component=build` to objects at creation/processing time using the CLI label option.
- Confirm the template creates the build-side resources and that its parameters resolve to the requested values.
- Process `deploy-template.yaml` with `APP_NAME=templated-app` and `REPLICAS=2`; apply label `exam=ex288,component=deploy` during creation/processing.
- Ensure the deployment consumes the image produced by the build template and reaches two ready replicas.
- Expose the service and verify the application responds.
- Inspect resources by label and demonstrate you can re-process a template with a changed parameter without manually editing the supplied template file.

## Q7 — Deploy a multi-container application with Helm

Chart source: your Git URL for `repos/q7-helm-chart`.

- Create project `helm-multi` yourself, clone the supplied chart, inspect `Chart.yaml`, `values.yaml`, and rendered manifests before installing.
- Install release `dualweb` and verify one Pod contains **two containers** (`writer` and `web`) sharing an `emptyDir` volume.
- Override `message` at install/upgrade time without editing the template and verify the web container serves the value written by the writer container.
- Upgrade the release so `replicaCount=2`; verify release revision/history and two ready replicas.
- Use Helm to inspect effective values and the generated release manifest, and use `helm lint`/template rendering to troubleshoot chart errors.
- Roll back to the previous revision and verify the resulting application state.

## Q8 — OpenShift Pipelines: supplied build and deploy pipelines

Pipeline definitions are supplied in Git under `repos/q8-pipelines/build-pipeline.yaml` and `deploy-pipeline.yaml`.

- Create project `cicd` yourself, retrieve/apply the two supplied Pipeline resources, and verify that Pipelines `build` and `deploy` exist.
- Inspect both Pipeline specifications and identify their required parameters before creating runs; do not modify the supplied Pipeline definitions.
- Create a PipelineRun for `build`, supplying a valid internal-registry image target parameter, and make the run complete successfully.
- Only after the build run succeeds, create a PipelineRun for `deploy` with the required application-name parameter and make it complete successfully.
- Use `oc` and, where available, `tkn` to inspect PipelineRuns, TaskRuns, logs, task ordering, parameters, and failure reasons; correct a bad run by creating a corrected PipelineRun rather than editing a completed run.
- Demonstrate repeatability by starting a second build/deploy cycle and show the history of PipelineRuns.


---

# Supplemental questions — published objective coverage

## Supplemental Q9 — Kustomize

Use the supplied Kustomize resources to practise base/overlay rendering and deployment.

## Supplemental Q10 — Build hooks and triggers

**Exact Git repository:** `https://github.com/mwambao/ex288-crc-mock.git`  
**Context directory:** `repos/q10-build-hooks`  
**Application / BuildConfig name:** `hook-app`  
**Project:** `build-hooks-extra`  
**Builder:** an available OpenShift Node.js S2I ImageStreamTag, for example `nodejs:20-ubi9`.

> Before attempting this question, make sure the updated `repos/q10-build-hooks` directory from this package has been committed and pushed to the Git repository above. The question deliberately uses a context directory inside the repository rather than a separate Git repository.

- Create project `build-hooks-extra` yourself and create an S2I BuildConfig named `hook-app` from `https://github.com/mwambao/ex288-crc-mock.git`, using context directory `repos/q10-build-hooks`.
- Configure a **post-commit build hook** that executes `./validate.sh`. A successful build must contain `POST-COMMIT VALIDATION PASSED` in its build log.
- Inspect the BuildConfig triggers and configure a **Generic webhook trigger** without deleting or recreating the BuildConfig. Display/copy the generated webhook URL.
- Make a harmless source change in `repos/q10-build-hooks/server.js`, commit and push it, then invoke the Generic webhook so OpenShift creates another build from the updated Git source. Identify the trigger cause from the resulting Build object.
- Deliberately change the hook command to `./missing-validate.sh`, start a build, use the Build status/description and logs to explain why it failed, then restore the correct `./validate.sh` hook.
- Start/trigger one final build and prove that the newest build is `Complete`, the hook executed successfully, and the BuildConfig still points to the exact Git repository and context directory specified above.

## Supplemental Q11 — OpenShift internal registry

Practise exposing/accessing the integrated registry, authenticating with an OpenShift token, and pulling/pushing an image with Podman.

## Supplemental Q12 — Application from an installed Operator

Practise discovering an installed Operator API, creating a minimal custom resource, and verifying its status and managed resources.
