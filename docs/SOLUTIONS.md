# Detailed Solutions and Revision Notes

> Commands assume you replaced `<GIT_BASE>` with repositories reachable from CRC. Each command is preceded by a short comment explaining its purpose. Adapt image tags after `oc get is -n openshift` if your CRC differs.

## Q1 — Git + S2I
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
```bash
# Create the project; this question intentionally does not rely on setup.sh creating it.
oc new-project container-build
# Create the Docker-strategy build from Git.
oc new-build <GIT_BASE>/q2-containerfile.git --name=container-app --strategy=docker
# Point the Docker strategy at the non-default Containerfile path.
oc patch bc/container-app --type=merge -p '{"spec":{"strategy":{"dockerStrategy":{"dockerfilePath":"container/Containerfile.exam","buildArgs":[{"name":"ARTIFACT_URL","value":"http://artifactory-mock.lab-infra.svc:8080/banner.txt"}]}}}}'
# Ensure output is the exact requested ImageStreamTag.
oc patch bc/container-app --type=merge -p '{"spec":{"output":{"to":{"kind":"ImageStreamTag","name":"container-app:1.0"}}}}'
# Build and follow logs; this is where wrong strategy/path/artifact URL becomes visible.
oc start-build container-app --follow
# Deploy the built image stream tag.
oc new-app container-app:1.0 --name=container-app
# Configure deployment image-change automation from the requested tag.
oc set triggers deployment/container-app --from-image=container-app:1.0 -c container-app
# Expose and test.
oc expose service container-app && curl -s http://$(oc get route container-app -o jsonpath='{.spec.host}')
```
Reference: https://docs.redhat.com/en/documentation/openshift_container_platform/4.18/html/builds_using_buildconfig/build-strategies and https://docs.redhat.com/en/documentation/openshift_container_platform/4.18/html/building_applications/creating-applications

## Q3 — Customized S2I
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


---

# Supplemental question solutions

## Supplemental Q9 — Kustomize

```bash
# Create a separate project for the supplemental Kustomize exercise.
oc new-project kustomize-extra

# Render the development overlay locally before changing the cluster.
oc kustomize ./q9-kustomize/overlays/dev

# Apply the overlay using the Kustomize support built into oc.
oc apply -k ./q9-kustomize/overlays/dev

# Verify the resulting replica count and labels.
oc get deployment -o wide --show-labels
```
Reference: https://docs.redhat.com/en/documentation/openshift_container_platform/4.18/html/cli_tools/openshift-cli-oc

## Supplemental Q10 — Build hooks and triggers

```bash
# Create an isolated project for hook and trigger practice.
oc new-project build-hooks-extra

# Inspect the BuildConfig before modifying its hooks or triggers.
oc get bc -o yaml

# Discover the supported post-commit fields from the API schema.
oc explain buildconfig.spec.postCommit --recursive

# Start a build and follow its output so the hook result is visible.
oc start-build <buildconfig-name> --follow

# List builds, then inspect a build to identify its trigger cause and failure details.
oc get builds
oc describe build/<build-name>

# Read the build log when diagnosing the build or post-commit command.
oc logs build/<build-name>
```
Reference: https://docs.redhat.com/en/documentation/openshift_container_platform/4.18/html/builds_using_buildconfig/triggering-builds-build-hooks

## Supplemental Q11 — OpenShift internal registry

```bash
# Inspect whether the integrated registry default route is enabled.
oc get configs.imageregistry.operator.openshift.io cluster -o jsonpath='{.spec.defaultRoute}{"\\n"}'

# Obtain the external registry hostname from OpenShift instead of hard-coding it.
REGISTRY=$(oc get route default-route -n openshift-image-registry -o jsonpath='{.spec.host}')

# Obtain the token for the currently authenticated OpenShift user.
TOKEN=$(oc whoami -t)

# Authenticate Podman to the OpenShift registry using the OpenShift identity and token.
podman login -u "$(oc whoami)" -p "$TOKEN" "$REGISTRY"

# Tag a local image using registry/project/ImageStream:tag addressing.
podman tag <local-image> "$REGISTRY/<project>/<imagestream>:practice"

# Push the image into the OpenShift integrated registry.
podman push "$REGISTRY/<project>/<imagestream>:practice"

# Verify that OpenShift records the pushed image and tag.
oc get is,istag

# Pull the image back to verify registry access in the opposite direction.
podman pull "$REGISTRY/<project>/<imagestream>:practice"
```
Reference: https://docs.redhat.com/en/documentation/openshift_container_platform/4.18/html/registry/accessing-the-registry

## Supplemental Q12 — Installed Operator

```bash
# Create the project that will contain the Operator custom resource.
oc new-project operator-extra

# Discover the NginxGatewayFabric API instead of relying on memorized YAML.
oc api-resources | grep -i nginxgatewayfabric

# Inspect the resource and its spec schema.
oc explain nginxgatewayfabric
oc explain nginxgatewayfabric.spec

# Create the minimum valid custom resource previously validated on this CRC lab.
cat > /tmp/practice-gateway.yaml <<'YAML'
apiVersion: gateway.nginx.org/v1alpha1
kind: NginxGatewayFabric
metadata:
  name: practice-gateway
  namespace: operator-extra
spec: {}
YAML

# Submit the custom resource so the installed Operator can reconcile it.
oc apply -f /tmp/practice-gateway.yaml

# Check reconciliation conditions; Initialized and Deployed should become True.
oc get nginxgatewayfabric practice-gateway -o jsonpath='{range .status.conditions[*]}{.type}{" => "}{.status}{" "}{.reason}{"\\n"}{end}'

# Inspect workloads and services created by the Operator.
oc get deployment,service,serviceaccount -n operator-extra

# Inspect related NGINX custom resources created by the Operator-managed installation.
oc get nginxgateway,nginxproxy -n operator-extra

# Review events if reconciliation does not complete successfully.
oc get events -n operator-extra --sort-by=.lastTimestamp
```
Reference: https://docs.redhat.com/en/documentation/openshift_container_platform/4.18/html/operators/understanding-operators
