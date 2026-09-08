# EX288 OCP 4.18-style CRC Mock Exam

Practice target: CRC with `developer/developer`; use kubeadmin only where a task requires cluster-admin. Time target: 3 hours. Do not open SOLUTIONS.md during a timed attempt.

## Preflight
For a new/recreated CRC, complete `docs/PREREQUISITES.md` first. For a repeat attempt on an already-prepared cluster, run `eval $(crc oc-env)`, log in as developer, run `scripts/setup.sh`, and optionally run `scripts/verify-env.sh`. Put `repos/pastebin`, `repos/oxy`, `repos/blog`, and `repos/phosphorie` in Git repositories reachable by CRC. Replace `<...-GIT-URL>` in questions with those URLs.

## Q1 — S2I source deployment
In project `crdmson`, deploy `pastebin` from `<PASTEBIN-GIT-URL>` using an appropriate Node.js S2I builder. Expose it as `pastebin-crdmson.apps-crc.testing`. The application must accept and display `Per aspera ad astra`. Confirm the build and deployment are healthy.

## Q2 — Internal registry
Configure the CRC internal image registry with an externally accessible default route. As developer, authenticate Podman to that route using an OpenShift token. Publish a test image into project `crdmson`, then pull it back using the external registry route. Do not disable TLS verification unless CRC's local certificate makes it necessary.

## Q3 — Templates
In project `tndy`, import `q3-template/php-app.yaml` as template `ex288-web-cache`. `APPLICATION_DOMAIN` must remain required. Process and instantiate it with `APPLICATION_DOMAIN=web-tndy.apps-crc.testing` and `HELLO_MESSAGE="Bonjour Engineers"`. Verify the route response.

## Q4 — Custom S2I
In `totain`, deploy `oxy` from `<OXY-GIT-URL>` with an HTTPD S2I builder. The supplied `.s2i/bin/assemble` must be used. Expose the service. `/` must contain `Amor vincit omnia`; `/info.html` must contain the build date in YYYY-MM-DD form plus that phrase.

## Q5 — Build hook and trigger
In `octane`, create a Git/S2I application named `blog` from `<BLOG-GIT-URL>` using an appropriate Python builder. Configure a post-commit build hook that executes `mailer.py` with the actual Python interpreter path in the builder/result image. Trigger a new build and prove `MAILER_HOOK_OK` appears in build output. Identify the configured build triggers.

## Q6 — Health monitoring
For `blog` in `octane`, configure: liveness TCP/8080, initial delay 10s, timeout 30s; readiness TCP/8080, initial delay 5s, timeout 5s. Verify the probes are stored on the workload and survive a rollout.

## Q7 — ConfigMaps and Secrets
In `acid`, deploy `phosphorie` from `<PHOSPHORIE-GIT-URL>`. Create ConfigMap `sodicon` containing `RESPONSE=Soda pop won't stop can't....`; inject it into the application as environment data. Create Secret `phosphorie-secret` with `APP_TOKEN=crc-ex288-secret` and inject it without putting the cleartext value in the Deployment manifest. Expose `phosphorie-acid.apps-crc.testing`; verify the response and that APP_TOKEN exists in the container.

## Q8 — Helm
In `helm-lab`, install `q8-helm` as release `helmy`. Override the message to `hello-from-ex288` and replicas to 2 without editing chart templates. Verify release state, pods, and route. Then upgrade the release so replicas=3 and message=`upgraded-ex288`. Show Helm history.

## Q9 — Kustomize
In `kustomize-lab`, inspect `q9-kustomize`. Deploy the `overlays/dev` overlay with `oc apply -k`. The resulting Deployment must have 2 replicas and `APP_ENV=dev`. Change only the overlay so replicas become 3, reapply, and verify.

## Q10 — ImageStreams and image-change updates
In `streams-lab`, create ImageStream `webbase`. Import/tag a suitable public UBI image as `webbase:stable`. Create a Deployment `stream-app` whose image is managed through the ImageStream and configure an image-change trigger. Change/import the tag to a different valid image/tag and prove the Deployment template updates or rolls out because of the ImageStream change.

## Q11 — Troubleshooting
Project `troubleshoot-lab` contains `broken-web`. Users cannot reach the intended backend. Diagnose using `oc get`, `oc describe`, endpoints/EndpointSlices and logs/events. Correct the configuration without deleting/recreating the Deployment. The Service must select the running pod and have a populated backend endpoint. Record the root cause.

## Q12 — Multi-container application
In `multi-lab`, deploy `q12-multicontainer/app.yaml`. Verify the pod has two containers, both mount the same `emptyDir`, and the reader logs repeatedly show `multi-container-ok`. Scale to 2 pods and verify both replicas work.

## Q13 — Tekton pipeline
Prerequisite: OpenShift Pipelines/Tekton must be installed on CRC. In `pipeline-lab`, apply `q13-pipeline/pipeline.yaml`. Create and run a PipelineRun for `ex288-pipeline` with message `crc-pipeline-success`. Verify Succeeded=True and show task logs.

## Q14 — Pipeline troubleshooting
Still in `pipeline-lab`, apply `q14-pipeline-debug/broken-pipelinerun.yaml`. Diagnose why it cannot execute, correct the supplied YAML, create a new PipelineRun, and verify it succeeds with output `fixed-pipeline-ok`.

## Q15 — Application from an installed Operator
The NGINX Gateway Fabric Operator is already installed on the cluster. Work in project `operator-lab`. Using CLI discovery commands such as `oc api-resources`, `oc explain`, and CRD inspection, determine the API version and kind for the Operator's `NginxGatewayFabric` custom resource. Create a resource named `exam-gateway` using the minimum valid configuration. Do not manually create resources that should be managed by the Operator. Verify that the Operator reconciles the CR successfully and identify resources it creates.
