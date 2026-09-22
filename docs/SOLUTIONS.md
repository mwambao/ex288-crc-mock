# Detailed Solutions and Revision Notes

> Commands assume you replaced `<GIT_BASE>` with repositories reachable from CRC. Each command is preceded by a short comment explaining its purpose. Adapt image tags after `oc get is -n openshift` if your CRC differs.

## Q1 — Git + S2I

### Option A — Web console
1. In **Developer → Project → Create Project**, create `crimson`.
2. Open **+Add → Import from Git**, enter `<GIT_BASE>/q1-pastebin.git`, and expand **Show advanced Git options** if needed.
3. Under **Builder Image**, choose the Node.js builder corresponding to `nodejs:20-ubi9`. Set **Name** to `pastebin`.
4. In **Build configuration / Environment variables**, add `npm_config_registry=https://registry.npmjs.org/`. Confirm the generated build uses **Source/S2I**, not Docker.
5. Click **Create**. In **Topology**, open the `pastebin` component, then open **Resources → Builds** (or **Builds → BuildConfigs**) and follow the build log. If it fails, inspect the log before changing anything.
6. From the component **Actions**, choose **Create Route** if a Route was not created automatically. Open the Route and verify the application.
7. To rebuild, open **Builds → BuildConfigs → pastebin → Actions → Start build**. Verify the newest build succeeds.
8. Use the **YAML** tab on the BuildConfig to confirm the Git URI, Source strategy, build environment, and output ImageStreamTag.

### Option B — CLI
```bash
# Create and select the project required by the task.
oc new-project crimson
# Create an S2I app explicitly using the Node.js builder so strategy selection is unambiguous.
oc new-app nodejs:20-ubi9~<GIT_BASE>/q1-pastebin.git --name=pastebin --strategy=source
# Set the dependency registry on the BuildConfig; S2I sees this during assemble.
oc set env bc/pastebin npm_config_registry=https://registry.npmjs.org/
# Inspect strategy, source and output before spending time waiting on a broken build.
oc get bc pastebin -o yaml
# Start a clean build and stream its log.
oc start-build pastebin --follow
# Expose the service externally.
oc expose service pastebin
# Confirm route and HTTP response.
curl -s http://$(oc get route pastebin -o jsonpath='{.spec.host}')
# Trigger another build and review build history.
oc start-build pastebin --follow && oc get builds
```
Reference: https://docs.redhat.com/en/documentation/openshift_container_platform/4.18/html/building_applications/creating-applications and https://docs.redhat.com/en/documentation/openshift_container_platform/4.18/html/builds_using_buildconfig/understanding-image-builds

## Q2 — Containerfile / Docker strategy

This question can be completed either with the **OpenShift web console** or the CLI. If the CLI does not detect the non-standard Containerfile cleanly, use **Option A (web console)**. This is also useful exam practice because EX288 expects you to be comfortable managing applications from the web console.

### Option A — Web console (recommended fallback)

1. **Create/select the project.** In the Developer perspective, open **Project → Create Project**, create `container-build`, and select it.
2. Open **+Add → Import from Git** (the wording can also appear as **From Git** depending on console layout) and enter the Git URL for `q2-containerfile.git`.
3. In **Import Strategy**, choose **Edit import strategy** and select **Dockerfile**. Do **not** allow the console to use Source/S2I for this question.
4. Set the Dockerfile/Containerfile path to `container/Containerfile.exam`. Set the application/component name to `container-app`. Create the application. The important result is a `BuildConfig` whose strategy is `Docker` and whose `dockerfilePath` points at the supplied file.
5. Open the created **BuildConfig `container-app`** and use its **YAML** view/editor. Under `spec.strategy.dockerStrategy`, make sure the following values exist. Also make sure the build output is `container-app:1.0`:

```yaml
spec:
  strategy:
    type: Docker
    dockerStrategy:
      dockerfilePath: container/Containerfile.exam
      buildArgs:
      - name: ARTIFACT_URL
        value: http://artifactory-mock.lab-infra.svc:8080/banner.txt
  output:
    to:
      kind: ImageStreamTag
      name: container-app:1.0
```

6. Save the BuildConfig. From **Builds → BuildConfigs → container-app**, start a new build. Open the build logs and confirm that the non-default Containerfile and artifact URL are being used. If an earlier automatically-started build failed before you finished the configuration, that is okay; the **latest build** must succeed.
7. In **Developer → +Add → Container images**, select **Image stream tag from internal registry**, choose project `container-build`, ImageStream `container-app`, tag `1.0`, and create the application as `container-app`. Ensure a Deployment and Service are created.
8. From **Topology**, select `container-app` and create a Route (or use **Actions → Create Route**). Verify the application through the route.
9. Finally inspect the Deployment YAML/details and confirm it has an image-change trigger for `container-app:1.0`. If the console-created deployment does not have one, use the CLI fallback below to add only that trigger.

```bash
# Add an ImageStream change trigger if the web-console deployment did not create one.
oc set triggers deployment/container-app --from-image=container-app:1.0 -c container-app

# Display the trigger so you can verify it before moving to the next question.
oc set triggers deployment/container-app
```

### Option B — CLI

```bash
# Create the project required by the question.
oc new-project container-build

# Create a Docker-strategy BuildConfig from the supplied Git repository.
# A first automatic build can fail because the Containerfile is deliberately not at the default path.
oc new-build <GIT_BASE>/q2-containerfile.git --name=container-app --strategy=docker

# Tell the Docker strategy where the non-default Containerfile is and pass the artifact URL as a build argument.
oc patch bc/container-app --type=merge -p '{"spec":{"strategy":{"dockerStrategy":{"dockerfilePath":"container/Containerfile.exam","buildArgs":[{"name":"ARTIFACT_URL","value":"http://artifactory-mock.lab-infra.svc:8080/banner.txt"}]}}}}'

# Make the successful build publish to the exact ImageStreamTag requested by the task.
oc patch bc/container-app --type=merge -p '{"spec":{"output":{"to":{"kind":"ImageStreamTag","name":"container-app:1.0"}}}}'

# Start a fresh build after the BuildConfig is fully configured and follow its logs.
oc start-build container-app --follow

# Deploy the image produced by the build.
oc new-app container-app:1.0 --name=container-app

# Configure automatic rollout when the ImageStreamTag changes.
oc set triggers deployment/container-app --from-image=container-app:1.0 -c container-app

# Expose the service with an OpenShift Route.
oc expose service container-app

# Verify the deployed application through the generated route.
curl -s http://$(oc get route container-app -o jsonpath='{.spec.host}')
```

### Q2 verification / troubleshooting

```bash
# Confirm that this is a Docker build and that the custom Containerfile path is stored in the BuildConfig.
oc get bc container-app -o jsonpath='{.spec.strategy.type}{"\n"}{.spec.strategy.dockerStrategy.dockerfilePath}{"\n"}'

# Confirm the build argument used to reach the supplied Artifactory-style service.
oc get bc container-app -o jsonpath='{.spec.strategy.dockerStrategy.buildArgs}{"\n"}'

# Check the most recent builds before leaving the question.
oc get builds

# Inspect the ImageStream and confirm that tag 1.0 exists.
oc get is container-app

# Check rollout state and the route.
oc rollout status deployment/container-app
oc get route container-app
```

**Why the web-console route is valid:** OpenShift 4.18 supports creating applications from Git in the Developer perspective, lets you change the import strategy when a Dockerfile is present, and lets you specify a particular Dockerfile path. Docker BuildConfigs also support `dockerfilePath` and build arguments. If automatic detection chooses the wrong strategy, explicitly select Docker rather than relying on detection.

References:
- OpenShift 4.18 — Creating applications / Importing from Git: https://docs.redhat.com/en/documentation/openshift_container_platform/4.18/html/building_applications/creating-applications
- OpenShift 4.18 — Builds using BuildConfig / Docker build strategy: https://docs.redhat.com/en/documentation/openshift_container_platform/4.18/html/builds_using_buildconfig/build-strategies

## Q3 — Customized S2I

### Option A — Web console / UI-assisted
> The OpenShift console can create and manage the S2I build, but the custom `.s2i/bin/assemble` file lives in Git. Edit/commit that supplied file with your Git web UI/editor first if your exam Git service provides one.

1. Create project `s2i-custom` from **Developer → Project → Create Project**.
2. Open **+Add → Import from Git** and enter `<GIT_BASE>/q3-custom-s2i.git`.
3. Select the HTTPD builder matching the available `httpd:2.4-ubi9` ImageStreamTag and set the component name to `oxy`. Ensure **Source/S2I** is the selected strategy.
4. In the build environment section add `PAGE_OWNER=developer`, then create the application.
5. Open **Builds → BuildConfigs → oxy**, start a build, and inspect its logs. Look for `CUSTOM ASSEMBLE RUNNING`; this proves the repository's custom assemble script was used.
6. In **Topology → oxy → Actions → Create Route**, expose the service. Open the Route and verify the generated content.
7. Use the BuildConfig **YAML** tab to distinguish the persistent BuildConfig from individual Build objects shown in the **Builds** list.

### Option B — CLI
```bash
# Create the project for the customized S2I workload.
oc new-project s2i-custom
# Discover the exact HTTPD tag available in this CRC before creating the app.
oc get is httpd -n openshift
# Create an S2I build from the repository; replace tag if discovery showed a different one.
oc new-app httpd:2.4-ubi9~<GIT_BASE>/q3-custom-s2i.git --name=oxy --strategy=source
# Add a build-time environment value to the source strategy.
oc set env bc/oxy PAGE_OWNER=developer
# Start the build and watch for CUSTOM ASSEMBLE RUNNING from the supplied .s2i script.
oc start-build oxy --follow
# Inspect build history and distinguish BuildConfig from Build instances.
oc get bc/oxy && oc get builds -l buildconfig=oxy
# Expose and test the built application.
oc expose service oxy && curl -s http://$(oc get route oxy -o jsonpath='{.spec.host}')
```
Reference: https://docs.redhat.com/en/documentation/openshift_container_platform/4.18/html/builds_using_buildconfig/build-strategies

## Q4 — ConfigMaps and Secrets

### Option A — Web console
1. Create project `acid`, then use **+Add → Import from Git** with `<GIT_BASE>/q4-config-app.git`; choose the Node.js S2I builder and name the component `phosphoric`.
2. In the Developer perspective open **ConfigMaps → Create ConfigMap** and create `sedicen` with key `RESPONSE` and the required value.
3. Open **Secrets → Create → Key/value secret** and create `phosphoric-secret` with key `API_TOKEN`.
4. In **Topology**, select `phosphoric`, choose **Actions → Edit Deployment**, and add environment variables **from ConfigMap/Secret references**. If the form does not expose the needed reference type, use the Deployment **YAML** editor and add `envFrom` entries referencing `sedicen` and `phosphoric-secret`. Do not paste the secret value directly into the Deployment.
5. Save and watch the rollout from **Topology/Pods**. Open the Deployment YAML and confirm the references are persisted.
6. Edit `sedicen`, change `RESPONSE`, save it, then use **Actions → Restart rollout** on the Deployment because environment-variable based ConfigMap values are read when a new Pod starts. Verify the replacement Pod becomes Ready.

### Option B — CLI
```bash
# Create the application project.
oc new-project acid
# Build/deploy the supplied source with S2I.
oc new-app nodejs:20-ubi9~<GIT_BASE>/q4-config-app.git --name=phosphoric --strategy=source
# Create the non-secret application configuration.
oc create configmap sedicen --from-literal=RESPONSE='If you can see this your configmap works'
# Create the sensitive value as a Secret.
oc create secret generic phosphoric-secret --from-literal=API_TOKEN='crc-practice-token'
# Import every ConfigMap key as environment variables in the Deployment.
oc set env deployment/phosphoric --from=configmap/sedicen
# Import Secret keys through a secret reference instead of writing values into the pod spec.
oc set env deployment/phosphoric --from=secret/phosphoric-secret
# Wait for the new rollout caused by the pod-template environment change.
oc rollout status deployment/phosphoric
# List references without printing secret data directly.
oc set env deployment/phosphoric --list
# Change configuration and restart so env-var based ConfigMap data is re-read.
oc create configmap sedicen --from-literal=RESPONSE='Configuration changed successfully' --dry-run=client -o yaml | oc apply -f -
oc rollout restart deployment/phosphoric
```
Reference: https://docs.redhat.com/en/documentation/openshift_container_platform/4.18/html/building_applications/config-maps and https://docs.redhat.com/en/documentation/openshift_container_platform/4.18/html/nodes/working-with-pods#nodes-pods-secrets

## Q5 — Health monitoring

### Option A — Web console
1. Create `health-lab`, import `<GIT_BASE>/q5-health-app.git` with the Node.js S2I builder, and name it `health-app`.
2. In **Topology**, select the application and choose **Actions → Add Health Checks** (or edit the Deployment and locate **Health checks**).
3. Add the **startup probe** as an HTTP GET to `/startup` on port `8080`. Translate the question's startup budget into the requested period/failure threshold and set the timeout.
4. Add the **liveness probe** as HTTP GET `/` on port `8080`; enter the required initial delay, period, timeout, and failure threshold from the task description.
5. Add the **readiness probe** as HTTP GET `/ready` on port `8080`; configure its separate timing/failure settings.
6. Save. Open **Pods → health-app pod → Events** and **Logs** to diagnose failures. A bad readiness probe normally prevents the Pod becoming Ready; a repeatedly failing liveness/startup probe can cause restarts.
7. Open **Deployment → YAML** and verify `startupProbe`, `livenessProbe`, and `readinessProbe` are stored in the pod template so they survive replacement Pods.

### Option B — CLI
```bash
# Create project and deploy the supplied health-aware app.
oc new-project health-lab
oc new-app nodejs:20-ubi9~<GIT_BASE>/q5-health-app.git --name=health-app --strategy=source
# Startup: HTTP /startup, 5-second cadence, six failures gives ~30 seconds startup budget.
oc set probe deployment/health-app --startup --get-url=http://:8080/startup --period-seconds=5 --failure-threshold=6 --timeout-seconds=2
# Liveness: delay checks, run periodically, and use a short timeout.
oc set probe deployment/health-app --liveness --get-url=http://:8080/ --initial-delay-seconds=15 --period-seconds=10 --timeout-seconds=2 --failure-threshold=3
# Readiness: start earlier, check frequently, and require repeated failures before unready.
oc set probe deployment/health-app --readiness --get-url=http://:8080/ready --initial-delay-seconds=3 --period-seconds=5 --timeout-seconds=2 --failure-threshold=3
# Inspect the actual persisted probe configuration.
oc get deployment health-app -o yaml
# Observe readiness/probe events and rollout status.
oc describe pod -l deployment=health-app
oc rollout status deployment/health-app
```
Reference: https://docs.redhat.com/en/documentation/openshift_container_platform/4.18/html/applications/application-health

## Q6 — Templates

### Option A — Web console / UI-assisted
> Template processing is often faster and less error-prone with `oc process`, especially when the task explicitly requires `-l`. The console is still useful for importing, inspecting and instantiating templates.

1. Create project `templating`. Obtain the supplied `build-template.yaml` and `deploy-template.yaml` from Git.
2. Use **+Add → Import YAML** and paste/apply the build Template object. Repeat for the deploy Template.
3. Open **Search**, select resource type **Template**, and inspect each template's YAML/parameters. Confirm the expected parameter defaults and required fields before instantiating it.
4. Use **+Add → Developer Catalog** and locate the imported template if your console exposes project templates there. Enter the required build parameters and create the build resources.
5. Inspect the generated BuildConfig under **Builds → BuildConfigs**, start the build if necessary, and wait for success.
6. Instantiate the deployment template with the required values. Because this exercise explicitly requires labels equivalent to `oc process ... -l exam=ex288,component=...`, verify the generated objects in YAML and add the required labels through **Edit labels** or the YAML editor if the template-instantiation form does not provide them.
7. In **Topology**, verify two replicas and create/open the Route. Use **Search → Resources** with labels to verify the build/deploy resources carry the required labels.

### Option B — CLI
```bash
# Create the target project.
oc new-project templating
# Inspect parameter names/defaults before processing.
oc process -f build-template.yaml --parameters
# Process build resources with values and apply the required labels at creation time.
oc process -f build-template.yaml -p APP_NAME=templated-app -p GIT_URL=<GIT_BASE>/q1-pastebin.git -p BUILDER=nodejs:20-ubi9 -l exam=ex288,component=build | oc apply -f -
# Start and follow the generated BuildConfig.
oc start-build templated-app --follow
# Process deploy resources, including the numeric replicas parameter and labels.
oc process -f deploy-template.yaml -p APP_NAME=templated-app -p REPLICAS=2 -p NAMESPACE=templating -l exam=ex288,component=deploy | oc apply -f -
# Verify labels and two ready replicas.
oc get all -l exam=ex288 --show-labels
oc rollout status deployment/templated-app
# Expose the generated service.
oc expose service templated-app
```
Reference: https://docs.redhat.com/en/documentation/openshift_container_platform/4.18/html/building_applications/creating-applications

## Q7 — Helm multi-container

### Option A — Web console / UI-assisted
> For a chart supplied as files in Git, `helm lint`, `helm template`, and installing the local chart are normally CLI operations. The OpenShift console is very useful for managing and verifying the Helm release after installation; if the chart is published in the Developer Catalog, it can also be installed entirely from the UI.

1. Create project `helm-multi`. If the chart is available in **Developer → +Add → Helm Chart**, select it; otherwise perform the initial local-chart install with the CLI option below.
2. In the Helm install form set release name `dualweb`, `message=first-value`, and the requested replica count/other values. Use **YAML view** if the form does not expose a value directly.
3. After installation open **Developer → Helm**, select release `dualweb`, and inspect **Resources**. Open a Pod and verify that both expected containers exist and share the expected volume.
4. Choose **Upgrade** for the release, change `message` to `second-value` and `replicaCount` to `2`, then apply the upgrade.
5. Open **Revision History** for the release and inspect the new revision/effective values.
6. Use **Rollback** to return to revision 1 and verify the Deployment becomes healthy again.
7. Inspect the Deployment YAML after each operation to connect Helm values with the rendered OpenShift resources.

### Option B — CLI
```bash
# Create target project.
oc new-project helm-multi
# Validate chart syntax before installation.
helm lint ./q7-helm-chart
# Render locally to inspect exactly what Kubernetes/OpenShift will receive.
helm template dualweb ./q7-helm-chart --set message='first-value'
# Install while overriding a value without editing templates.
helm install dualweb ./q7-helm-chart --set message='first-value'
# Verify both containers are in each pod.
oc get pods -l app=dualweb -o jsonpath='{range .items[*]}{.metadata.name}{" => "}{.spec.containers[*].name}{"\n"}{end}'
# Upgrade values and scale to two replicas.
helm upgrade dualweb ./q7-helm-chart --set message='second-value' --set replicaCount=2
# Review revisions and effective values.
helm history dualweb && helm get values dualweb && helm get manifest dualweb
# Roll back one revision and verify state.
helm rollback dualweb 1 && oc rollout status deployment/dualweb
```
Reference: https://docs.redhat.com/en/documentation/openshift_container_platform/4.18/html/building_applications/working-with-helm-charts

## Q8 — Pipelines and PipelineRuns

### Option A — Web console
1. Create project `cicd`. In **Developer → Pipelines**, use **Create → Pipeline** or **Import YAML** to create the supplied `build` and `deploy` Pipeline definitions from Git.
2. Open each Pipeline and inspect its **Pipeline details/YAML** to identify required parameters before starting a run.
3. Open Pipeline `build` and choose **Actions → Start**. Supply `IMAGE=image-registry.openshift-image-registry.svc:5000/cicd/pipeline-app:latest`, then start the PipelineRun.
4. Open the PipelineRun graphical view. Select each Task to inspect status and logs. Do not start the deploy Pipeline until the build PipelineRun succeeds.
5. Open Pipeline `deploy`, choose **Start**, supply `APP_NAME=pipeline-app`, and run it. Verify the resulting application resources in **Topology**.
6. Under **Pipelines → PipelineRuns**, review run history. For a failed run, open the failed TaskRun and read **Logs**, **Events**, and the PipelineRun **YAML/status.conditions** to identify the actual failure rather than recreating resources blindly.
7. Start another run after correcting the problem and confirm the previous run remains in history.

### Option B — CLI
```bash
# Create the CI/CD project.
oc new-project cicd
# Apply the two Pipeline definitions supplied from Git.
oc apply -f build-pipeline.yaml -f deploy-pipeline.yaml
# Inspect required parameters before constructing PipelineRuns.
oc get pipeline build -o yaml && oc get pipeline deploy -o yaml
# Create a build PipelineRun declaratively; generateName preserves run history.
cat <<'EOF' | oc create -f -
apiVersion: tekton.dev/v1
kind: PipelineRun
metadata: {generateName: build-run-}
spec:
  pipelineRef: {name: build}
  params:
  - {name: IMAGE, value: image-registry.openshift-image-registry.svc:5000/cicd/pipeline-app:latest}
EOF
# Watch run/task state and inspect logs.
oc get pipelinerun,taskrun -w
# After build success, create the deploy PipelineRun with its required parameter.
cat <<'EOF' | oc create -f -
apiVersion: tekton.dev/v1
kind: PipelineRun
metadata: {generateName: deploy-run-}
spec:
  pipelineRef: {name: deploy}
  params:
  - {name: APP_NAME, value: pipeline-app}
EOF
# Show history and failure/success reasons.
oc get pipelineruns
# If tkn is installed, use it for concise status/log inspection.
tkn pipelinerun list
```
Reference: https://docs.redhat.com/en/documentation/red_hat_openshift_pipelines/latest/html/creating_cicd_pipelines/creating-applications-with-cicd-pipelines
