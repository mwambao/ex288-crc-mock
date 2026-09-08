# Solutions and verification

Commands assume the repository URLs are reachable from CRC. ImageStream names/builders vary slightly by CRC bundle; use `oc get is -n openshift` to discover available builders rather than memorizing a version tag.

## Q1
```bash
oc project crdmson
oc get is -n openshift | grep -i node
oc new-app nodejs:latest~<PASTEBIN-GIT-URL> --name=pastebin
oc logs -f bc/pastebin
oc expose svc/pastebin --hostname=pastebin-crdmson.apps-crc.testing
oc get pods,build,route
curl http://pastebin-crdmson.apps-crc.testing
```
Use the form to save `Per aspera ad astra`, then curl again.

## Q2
Admin step:
```bash
oc login -u kubeadmin https://api.crc.testing:6443
oc patch configs.imageregistry.operator.openshift.io/cluster --type=merge -p '{"spec":{"defaultRoute":true}}'
oc get route default-route -n openshift-image-registry
```
Developer/podman:
```bash
oc login -u developer -p developer https://api.crc.testing:6443
HOST=$(oc get route default-route -n openshift-image-registry -o jsonpath='{.spec.host}')
TOKEN=$(oc whoami -t)
podman login -u developer -p "$TOKEN" --tls-verify=false "$HOST"
podman pull registry.access.redhat.com/ubi9/ubi-minimal:latest
podman tag registry.access.redhat.com/ubi9/ubi-minimal:latest "$HOST/crdmson/registry-test:1"
podman push --tls-verify=false "$HOST/crdmson/registry-test:1"
podman pull --tls-verify=false "$HOST/crdmson/registry-test:1"
oc get is -n crdmson
```

## Q3
```bash
oc project tndy
oc create -f q3-template/php-app.yaml
oc process ex288-web-cache --parameters
oc process ex288-web-cache -p APPLICATION_DOMAIN=web-tndy.apps-crc.testing -p 'HELLO_MESSAGE=Bonjour Engineers' | oc apply -f -
oc get deploy,svc,route
curl http://web-tndy.apps-crc.testing
```

## Q4
```bash
oc project totain
oc get is -n openshift | grep -i httpd
oc new-app httpd:latest~<OXY-GIT-URL> --name=oxy
oc logs -f bc/oxy
oc expose svc/oxy
HOST=$(oc get route oxy -o jsonpath='{.spec.host}')
curl http://$HOST/
curl http://$HOST/info.html
```
If the builder's working directory differs, inspect its standard assemble script and adapt the supplied custom assemble script while preserving the task requirements.

## Q5
```bash
oc project octane
oc delete deployment blog --ignore-not-found
oc new-app python:latest~<BLOG-GIT-URL> --name=blog
oc logs -f bc/blog
POD=$(oc get pod -l deployment=blog -o name | head -1)
oc rsh "$POD" which python3
oc set build-hook bc/blog --post-commit --command -- /usr/bin/python3 mailer.py
oc start-build blog --follow
oc get bc/blog -o jsonpath='{.spec.triggers}' ; echo
```
Use the `which python3` result if it is not `/usr/bin/python3`.

## Q6
```bash
oc project octane
oc set probe deployment/blog --liveness --open-tcp=8080 --initial-delay-seconds=10 --timeout-seconds=30
oc set probe deployment/blog --readiness --open-tcp=8080 --initial-delay-seconds=5 --timeout-seconds=5
oc rollout status deployment/blog
oc get deployment blog -o yaml | grep -A8 -E 'livenessProbe|readinessProbe'
```

## Q7
```bash
oc project acid
oc new-app nodejs:latest~<PHOSPHORIE-GIT-URL> --name=phosphorie
oc create configmap sodicon --from-literal=RESPONSE="Soda pop won't stop can't...."
oc create secret generic phosphorie-secret --from-literal=APP_TOKEN='crc-ex288-secret'
oc set env deployment/phosphorie --from=configmap/sodicon
oc set env deployment/phosphorie --from=secret/phosphorie-secret
oc expose svc/phosphorie --hostname=phosphorie-acid.apps-crc.testing
curl http://phosphorie-acid.apps-crc.testing
oc exec deployment/phosphorie -- sh -c 'test -n "$APP_TOKEN" && echo APP_TOKEN_present'
```

## Q8
```bash
oc project helm-lab
helm install helmy q8-helm --set replicaCount=2 --set message=hello-from-ex288
helm status helmy
oc get pods,route
curl http://$(oc get route helmy -o jsonpath='{.spec.host}')
helm upgrade helmy q8-helm --set replicaCount=3 --set message=upgraded-ex288
helm history helmy
oc get deploy helmy
```

## Q9
```bash
oc project kustomize-lab
oc apply -k q9-kustomize/overlays/dev
oc get deploy kweb -o jsonpath='{.spec.replicas}{"\n"}{.spec.template.spec.containers[0].env}{"\n"}'
# edit only overlay value 2 -> 3
oc apply -k q9-kustomize/overlays/dev
oc rollout status deploy/kweb
```

## Q10
```bash
oc project streams-lab
oc create imagestream webbase
oc import-image webbase:stable --from=registry.access.redhat.com/ubi9/ubi-minimal:latest --confirm
oc create deployment stream-app --image=registry.access.redhat.com/ubi9/ubi-minimal:latest -- sleep 3600
oc set triggers deployment/stream-app --from-image=webbase:stable -c stream-app
oc get deployment stream-app -o yaml | grep -A8 image.openshift.io/triggers
oc import-image webbase:stable --from=registry.access.redhat.com/ubi9/ubi-minimal:9.5 --confirm
oc rollout status deployment/stream-app
oc get is webbase -o yaml
```
If a referenced UBI tag has moved, choose two valid tags visible in the registry; the assessed skill is ImageStream import/tag + image-change trigger.

## Q11
```bash
oc project troubleshoot-lab
oc get deploy,svc,pod,endpoints
oc describe svc broken-web
oc get pod --show-labels
# root cause: Service selector app=WRONG, pod label app=broken-web
oc patch svc broken-web --type=merge -p '{"spec":{"selector":{"app":"broken-web"}}}'
oc get endpoints broken-web
```
The backend program in this seeded exercise sleeps rather than serving HTTP; the required repair is specifically service-to-pod selection/endpoints.

## Q12
```bash
oc project multi-lab
oc apply -f q12-multicontainer/app.yaml
oc get pods
POD=$(oc get pod -l app=multi -o jsonpath='{.items[0].metadata.name}')
oc get pod "$POD" -o jsonpath='{.spec.containers[*].name}{"\n"}'
oc logs "$POD" -c reader --tail=10
oc scale deployment multi --replicas=2
oc rollout status deployment/multi
```

## Q13
Check Tekton first:
```bash
oc api-resources | grep -i tekton
```
Then:
```bash
oc project pipeline-lab
oc apply -f q13-pipeline/pipeline.yaml
cat <<'YAML' | oc create -f -
apiVersion: tekton.dev/v1
kind: PipelineRun
metadata: {generateName: ex288-run-}
spec:
  pipelineRef: {name: ex288-pipeline}
  params: [{name: message,value: crc-pipeline-success}]
YAML
oc get pipelinerun
oc describe pipelinerun $(oc get pr -o name | tail -1)
# if tkn is installed:
tkn pipelinerun logs -L -f
```

## Q14
The supplied file misspells `ex288-pipeline` as `ex288-pipline`.
```bash
sed 's/ex288-pipline/ex288-pipeline/' q14-pipeline-debug/broken-pipelinerun.yaml > /tmp/fixed-run.yaml
oc create -f /tmp/fixed-run.yaml
oc get pr
# with tkn:
tkn pipelinerun logs -L -f
```

## Q15
Discover the installed resource instead of memorizing it:
```bash
oc project operator-lab
oc api-resources | grep -i nginxgatewayfabric
oc explain nginxgatewayfabric
oc explain nginxgatewayfabric.spec
```
The validated CRD has API group `gateway.nginx.org`, version `v1alpha1`, kind `NginxGatewayFabric`, and no required fields under `spec`.

Create the minimum valid instance:
```bash
cat > /tmp/exam-gateway.yaml <<'YAML'
apiVersion: gateway.nginx.org/v1alpha1
kind: NginxGatewayFabric
metadata:
  name: exam-gateway
  namespace: operator-lab
spec: {}
YAML
oc apply -f /tmp/exam-gateway.yaml
```

Verify reconciliation:
```bash
oc get nginxgatewayfabric exam-gateway -n operator-lab
oc get nginxgatewayfabric exam-gateway -n operator-lab \
  -o jsonpath='{range .status.conditions[*]}{.type}{" => "}{.status}{" "}{.reason}{"\\n"}{end}'
```
On the validated lab this reports `Initialized => True` and `Deployed => True InstallSuccessful`.

Verify resources created by the Operator:
```bash
oc get deployment,service,serviceaccount -n operator-lab
oc get gatewayclass nginx
oc get nginxgateway,nginxproxy -n operator-lab
oc get events -n operator-lab --sort-by=.lastTimestamp
```
The managed names include `exam-gateway-nginx-gateway-fabric`; the Operator also creates a `GatewayClass` named `nginx` and supporting NGINX custom resources. Do not create those managed resources manually.

## Useful exam verification pattern
```bash
oc get all
oc get route
oc get events --sort-by=.lastTimestamp | tail -20
oc describe <resource>
oc logs <pod> [-c container]
oc get <resource> -o yaml
```
