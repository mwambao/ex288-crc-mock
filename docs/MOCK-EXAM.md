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

# Supplemental questions — complete these after Q1–Q8

The eight questions above form the main timed remediation mock. The questions below are **SUPPLEMENTAL**, but they remain part of this same exam document so that they are not missed during revision. They cover additional skills named in the public EX288 objectives.

## Supplemental Q9 — Kustomize

- Create project `kustomize-extra` yourself.
- From the supplied Kustomize files, identify the base Deployment and Service and inspect them before applying anything.
- Create/use a development overlay that changes the Deployment replica count and adds environment-specific labels without modifying the base resources.
- Render the overlay with `oc kustomize` and inspect the generated YAML before deployment.
- Apply the overlay with `oc apply -k`, then verify the expected replicas and labels exist in the project.
- Make one further overlay-only change, reapply it, and verify the base remains unchanged.

## Supplemental Q10 — Build hooks and triggers

- Create project `build-hooks-extra` yourself and create an S2I BuildConfig from the supplied Git application.
- Configure a post-commit build hook that executes the supplied validation script after a successful image build.
- Inspect the BuildConfig triggers and configure/manage an appropriate source or configuration trigger without recreating the BuildConfig.
- Start a build, follow its logs, and prove from the build output that the post-commit hook executed successfully.
- Make a configuration/source change that causes another build through the configured trigger and identify the trigger cause from the Build object.
- Use `oc describe build` and build logs to diagnose a deliberately incorrect hook command or trigger configuration, then correct it.

## Supplemental Q11 — OpenShift internal registry

- Using an account with sufficient privileges, inspect the OpenShift integrated image registry and determine whether its default external route is enabled.
- Enable or use the registry route as required and determine its hostname without hard-coding it.
- Authenticate Podman to the registry using your OpenShift identity/token.
- Tag and push a supplied/local practice image into an ImageStreamTag in a project you create yourself.
- Verify the resulting ImageStream/ImageStreamTag from OpenShift, then pull the same image back with Podman.
- Demonstrate the relationship between the registry repository path, project name, ImageStream name, and image tag.

## Supplemental Q12 — Application from an installed Operator

- Create project `operator-extra` yourself and use `oc api-resources`, `oc explain`, and CRD inspection to discover the installed `NginxGatewayFabric` API rather than relying on memorized YAML.
- Determine the correct API group/version, kind, and minimum valid specification for the custom resource.
- Create an `NginxGatewayFabric` custom resource named `practice-gateway` using the minimum valid configuration.
- Verify that the Operator reports successful initialization/deployment through the custom resource status.
- Identify at least three resources created and managed as a consequence of the custom resource, without manually creating those managed resources.
- Use events, the custom-resource status, and Operator-managed workload status to troubleshoot reconciliation if it does not complete successfully.
