# Complete CRC environment prerequisites

Use this section when creating the lab for the first time **or after deleting/recreating CRC**.

> Compatibility note: this mock is OCP 4.18-style. The environment used to validate the later questions was CRC/OpenShift 4.21.8. Always discover the resources available on your own CRC instead of memorizing version-specific output.

## 1. Start a fresh CRC cluster

Install CRC using Red Hat's supported instructions for your workstation, then initialize and start it. If CRC is already installed:

```bash
crc setup
crc start
```

Load the bundled `oc` into your shell:

```bash
eval $(crc oc-env)
oc version
crc status
```

Record the OpenShift version shown by `oc version`. A newer CRC release may not exactly match OCP 4.18; that is acceptable for this practice lab, but expect small differences.

## 2. Obtain/login with cluster-admin access

Use the kubeadmin credentials printed by `crc start` or shown by:

```bash
crc console --credentials
```

Log in with the displayed kubeadmin password. Do **not** store the password in this repository or in shell scripts.

```bash
oc login -u kubeadmin https://api.crc.testing:6443
oc whoami
oc auth can-i '*' '*' --all-namespaces
```

The final command should report `yes` before running the cluster bootstrap script.

CRC also normally provides the practice developer account. Later, switch back with:

```bash
oc login -u developer -p developer https://api.crc.testing:6443
```

## 3. Bootstrap cluster-wide exam prerequisites

From the root of this mock lab, while logged in as cluster-admin:

```bash
chmod +x scripts/*.sh
./scripts/bootstrap-crc.sh
```

The script is idempotent and performs/checks the following:

- healthy OperatorHub catalog sources;
- Red Hat OpenShift Pipelines (`openshift-pipelines-operator-rh`) from `redhat-operators`;
- NGINX Gateway Fabric (`nginx-gateway-fabric`) from `certified-operators` for Q15;
- Tekton `Task`, `TaskRun`, `Pipeline`, and `PipelineRun` APIs;
- NGINX Gateway Fabric CRD;
- OpenShift build and ImageStream APIs;
- the internal image registry;
- a default StorageClass;
- the external registry default route is set to **disabled initially**, so Q2 is not pre-solved.

Operator installation can take several minutes. The script waits for the relevant CSVs to reach `Succeeded`.

### Why the NGINX Operator is installed cluster-wide

Q15 tests **creating an application/resource from an already-installed Operator**. The timed question should not be spent installing the Operator itself. The validated custom resource is:

```text
apiVersion: gateway.nginx.org/v1alpha1
kind: NginxGatewayFabric
```

A minimal `spec: {}` was validated successfully and produced `Initialized=True` and `Deployed=True` with reason `InstallSuccessful`.

## 4. Verify Helm, Kustomize and builders

Run:

```bash
helm version
oc kustomize --help >/dev/null && echo 'oc kustomize: OK'
oc get is -n openshift
```

For the validated CRC environment, useful builder families included Node.js, Python, PHP, HTTPD, MySQL and PostgreSQL. **Do not assume a tag.** Discover current tags before a practice attempt:

```bash
oc get is nodejs python php httpd mysql postgresql -n openshift
oc describe is nodejs -n openshift
```

This mock commonly expects modern UBI9-family tags where available (for example Node.js 20, Python 3.11, PHP 8.2, HTTPD 2.4 and MySQL 8.0), but your CRC bundle is authoritative.

## 5. Verify Pipelines/Tekton

```bash
oc get subscription -A | grep -i pipeline || true
oc get csv -A | grep -i pipeline || true
oc get pods -n openshift-pipelines
oc api-resources | grep -Ei 'taskrun|pipelinerun|pipeline'
oc get crd | grep tekton.dev
```

The Q13/Q14 manifests in this lab use `tekton.dev/v1`.

`tkn` is useful but not required. If it is not installed, use `oc get`, `oc describe`, pod logs, and TaskRun/PipelineRun status for verification.

## 6. Verify the Q15 Operator

```bash
oc get subscription -n nginx-gateway nginx-gateway-fabric
oc get csv -n nginx-gateway
oc get crd nginxgatewayfabrics.gateway.nginx.org
oc api-resources | grep -i nginxgatewayfabric
oc explain nginxgatewayfabric.spec
```

The installed NGINX Gateway Fabric Operator supports an AllNamespaces installation mode, which is why the bootstrap creates an OperatorGroup without `targetNamespaces`.

## 7. Verify registry and storage

```bash
oc get clusteroperator image-registry
oc get pods -n openshift-image-registry
oc get configs.imageregistry.operator.openshift.io cluster \
  -o jsonpath='{.spec.defaultRoute}{"\\n"}'
oc get storageclass
```

Before the mock begins, `defaultRoute` should be `false`. Q2 asks you to expose it.

## 8. Prepare the four Git repositories

The mock includes source directories:

```text
repos/pastebin/
repos/oxy/
repos/blog/
repos/phosphorie/
```

Create four Git repositories reachable from CRC and push each directory. Do not commit passwords or access tokens. Record the clone URLs and substitute them for:

```text
<PASTEBIN-GIT-URL>
<OXY-GIT-URL>
<BLOG-GIT-URL>
<PHOSPHORIE-GIT-URL>
```

Public repositories are simplest for repeated practice. Private repositories require an OpenShift source secret.

## 9. Create the per-question lab state

Switch to the developer account:

```bash
oc login -u developer -p developer https://api.crc.testing:6443
./scripts/setup.sh

If `setup.sh` reports that a project already exists but `developer` cannot access it, switch back to cluster-admin and run:

```bash
./scripts/bootstrap-crc.sh
```

Then log in as `developer` again and rerun `./scripts/setup.sh`. The bootstrap is idempotent and will grant `developer` access to all lab projects without deleting their contents.
```

The cluster-admin bootstrap creates the projects used by Q1-Q15 and grants the CRC `developer` account project-admin access to each one. `setup.sh` then seeds only the resources that are intentionally present at exam start.

This split is deliberate: if a project already exists but was originally created by `kubeadmin`, the `developer` user may not be able to see it. In that situation an older `setup.sh` could fail with `AlreadyExists`. Re-run `bootstrap-crc.sh` once as cluster-admin to repair project access, then run `setup.sh` as `developer`.

## 10. Final environment check

The verification script is designed to work with either the **developer** account or **kubeadmin**. Some cluster-wide resources such as `ClusterOperator` objects are intentionally not readable by a normal developer. The script therefore uses API discovery for developer-safe checks and performs stronger health checks when you run it as cluster-admin.

After `setup.sh`, while logged in as `developer`, run:

```bash
./scripts/verify-env.sh
```

A developer run should pass the exam-relevant API checks. You may see a `WARN` saying the registry operator health check was skipped because the current user is not cluster-admin; that warning is expected.

For a full cluster-health check, switch to kubeadmin and run the same script once:

```bash
oc login -u kubeadmin https://api.crc.testing:6443
./scripts/verify-env.sh
```

Do not put the kubeadmin password in this repository or any script.

Then confirm the projects:

```bash
oc get project | grep -E 'crdmson|tndy|totain|octane|acid|helm-lab|kustomize-lab|streams-lab|troubleshoot-lab|multi-lab|pipeline-lab|operator-lab'
```

You are ready when the developer-safe checks pass, Pipelines and the NGINX Gateway Fabric APIs are discoverable, and the lab projects have been created. A one-time kubeadmin run is recommended after rebuilding CRC to confirm cluster-wide operator health.

## Repeating the mock without deleting CRC

Do **not** rerun the full cluster bootstrap every time. Reset only the question projects:

```bash
./scripts/reset.sh
```

Wait until they disappear:

```bash
oc get project
```

Then:

```bash
./scripts/setup.sh
```

## If you completely delete CRC later

Repeat sections 1-10. In short:

```text
fresh CRC
  -> crc setup/start
  -> cluster-admin login
  -> bootstrap-crc.sh
  -> verify-env.sh
  -> prepare/reuse Git repositories
  -> developer login
  -> setup.sh
  -> start mock exam
```


# v7 remediation-lab additions

## Git resources
Create eight Git repositories reachable by CRC from the directories under `repos/`. The mock uses placeholders such as `<GIT_BASE>/q1-pastebin.git`; substitute your actual Git URLs. Keeping these as separate repos mimics an exam where different supplied repositories are referenced by different questions.

## Mock Artifactory endpoint
Q2 practices consuming a supplied artifact URL during a Docker-strategy build. As kubeadmin/admin run:
```bash
oc new-project lab-infra || true
oc apply -n lab-infra -f q2-containerfile/artifact-server.yaml
oc rollout status -n lab-infra deployment/artifactory-mock
oc get svc -n lab-infra artifactory-mock
```
The in-cluster URL used by Q2 is `http://artifactory-mock.lab-infra.svc:8080/banner.txt`. This is deliberately a lightweight stand-in for an Artifactory/Nexus HTTP artifact endpoint; it does not pretend to implement the full products.

## Dependency-registry practice
Q1 accepts an `NPM_REGISTRY_URL`. For a self-contained CRC rebuild use `https://registry.npmjs.org/`. If you later deploy a real Nexus/Artifactory npm proxy, replace that value with its URL without changing the exercise.
