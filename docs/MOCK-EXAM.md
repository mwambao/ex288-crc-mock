# EX288 OCP 4.18-style CRC Mock Exam — Objective-aligned edition

Practice target: CRC. Official target: OpenShift Container Platform 4.18. Time target: 3 hours. Do not open `SOLUTIONS.md` during a timed attempt.

## Preflight
For a new/recreated CRC, complete `docs/PREREQUISITES.md` first. For a repeat attempt, log in as developer, run `scripts/setup.sh`, then `scripts/verify-env.sh`. Put `repos/pastebin`, `repos/oxy`, `repos/blog`, and `repos/phosphorie` in Git repositories reachable by CRC and replace the `<...-GIT-URL>` placeholders. After answering a question, you may self-mark it with `scripts/mark.sh <number>`; for a strict timed attempt, wait until the end and run `scripts/mark.sh all`.

## Q1 — Git + S2I single-container deployment
In project `crdmson`, deploy `pastebin` from `<PASTEBIN-GIT-URL>` using an appropriate Node.js S2I builder. Expose it as `pastebin-crdmson.apps-crc.testing`. Confirm the build and deployment are healthy and verify the application can accept/display `Per aspera ad astra`.

## Q2 — Internal registry + publish/pull an image
Configure the OpenShift internal image registry so it has an externally accessible default route. Authenticate Podman to the route using an OpenShift token. Pull a pre-built UBI image, tag it for project `crdmson`, push it into the OpenShift registry, and pull it back. Verify the resulting ImageStream/tag. Use the privileges supplied by the lab for the registry configuration step.

## Q3 — Parameterized multi-container OpenShift Template
In `tndy`, import the supplied `q3-template/php-app.yaml` as template `ex288-web-cache`. Inspect its parameters and objects. `APPLICATION_DOMAIN` must be required. Process the pre-existing YAML template with `APPLICATION_DOMAIN=web-tndy.apps-crc.testing` and `HELLO_MESSAGE="Bonjour Engineers"`. Instantiate it and verify that the resulting pod contains both containers, the route works, and the response contains the supplied message.

## Q4 — Customized S2I builder workflow
In `totain`, deploy `oxy` from `<OXY-GIT-URL>` with an appropriate HTTPD S2I builder. The supplied `.s2i/bin/assemble` customization must participate in the build. Expose the application. `/` must contain `Amor vincit omnia`; `/info.html` must contain a build date in YYYY-MM-DD form plus that phrase. Verify the BuildConfig and build logs.

## Q5 — Build hooks, triggers, and build troubleshooting
In `octane`, create the Git/S2I application `blog` from `<BLOG-GIT-URL>` with an appropriate Python builder. Apply the supplied `q5-build/broken-postcommit-patch.yaml` to `bc/blog` and start a build. Diagnose the build failure without changing application source code. Correct the post-commit hook so it executes the provided `mailer.py` with the correct interpreter, trigger a new build, and prove `MAILER_HOOK_OK` appears in the build output. Identify the BuildConfig triggers and manually trigger one additional build.

## Q6 — Application health monitoring
For `blog` in `octane`, configure liveness TCP/8080 with initial delay 10s and timeout 30s, plus readiness TCP/8080 with initial delay 5s and timeout 5s. Verify the probes are stored on the workload and survive a rollout.

## Q7 — ConfigMaps and Secrets
In `acid`, deploy `phosphorie` from `<PHOSPHORIE-GIT-URL>`. Create ConfigMap `sodicon` containing `RESPONSE=Soda pop won't stop can't....` and inject it as environment data. Create Secret `phosphorie-secret` with `APP_TOKEN=crc-ex288-secret` and inject it without placing the cleartext value in the Deployment manifest. Expose `phosphorie-acid.apps-crc.testing`; verify the response and verify `APP_TOKEN` exists in the container.

## Q8 — Helm multi-container application
In `helm-lab`, install the supplied `q8-helm` chart as release `helmy`. Override the message to `hello-from-ex288` and replicas to 2 without editing chart templates. Verify release state, route, replicas, and that each pod has two containers. Upgrade to replicas=3 and message=`upgraded-ex288`, then show Helm history.

## Q9 — Kustomize deployment customization
In `kustomize-lab`, inspect `q9-kustomize`. Deploy `overlays/dev` with `oc apply -k`. The resulting Deployment must have 2 replicas and `APP_ENV=dev`. Change only the overlay so replicas become 3, reapply, and verify the rollout.

## Q10 — Pre-built base image, BuildConfig, ImageStream, and image-change trigger
In `streams-lab`, use the supplied `q10-imagestream/Dockerfile`, which is based on a pre-built UBI image, to create an OpenShift Docker-strategy BuildConfig named `webbase-build`. Its output must be ImageStreamTag `webbase:stable`. Run the build and verify the image was published to the OpenShift registry. Deploy `stream-app` from `webbase:stable` and configure an image-change trigger. Make a harmless change to the Dockerfile label, rebuild, and prove the ImageStream change causes the Deployment template/image or rollout revision to update.

## Q11 — Deployment troubleshooting + web console management
Project `troubleshoot-lab` contains `broken-web`. Diagnose why its Service has no usable backend by using `oc get`, `oc describe`, EndpointSlices/endpoints, logs/events as appropriate. Correct the configuration without deleting/recreating the Deployment. Verify the Service has a populated endpoint. Then use the **OpenShift web console** to inspect the workload and scale `broken-web` from 1 to 2 replicas. Verify from the CLI that two ready replicas exist. Record the original root cause.

## Q12 — Multi-container application
In `multi-lab`, deploy `q12-multicontainer/app.yaml`. Verify the pod has two containers, both mount the same `emptyDir`, and reader logs repeatedly show `multi-container-ok`. Scale to 2 pods and verify both replicas work.

## Q13 — Define and trigger a Tekton CI/CD workflow
OpenShift Pipelines/Tekton is installed. In `pipeline-lab`, inspect the supplied Task definition in `q13-pipeline/pipeline.yaml`. Using standard `tekton.dev/v1` CRDs, define a Pipeline named `ex288-pipeline` that calls `echo-message` and passes a string parameter named `message`. Create/trigger a PipelineRun with `message=crc-pipeline-success`. Verify `Succeeded=True` and show task logs. Be able to explain the Task → Pipeline → PipelineRun relationship.

## Q14 — Troubleshoot a Tekton workflow
Still in `pipeline-lab`, apply `q14-pipeline-debug/broken-pipelinerun.yaml`. Diagnose why the workflow cannot execute, correct the supplied definition, create a new PipelineRun, and verify it succeeds with output `fixed-pipeline-ok`. Use PipelineRun/TaskRun status, events, and logs during diagnosis.

## Q15 — Application from an installed Operator
The NGINX Gateway Fabric Operator is already installed. Work in `operator-lab`. Using CLI discovery (`oc api-resources`, `oc explain`, and CRD inspection), determine the API version and kind for the Operator's `NginxGatewayFabric` resource. Create `exam-gateway` using the minimum valid configuration. Do not manually create resources managed by the Operator. Verify successful reconciliation and identify the application resources the Operator creates.
