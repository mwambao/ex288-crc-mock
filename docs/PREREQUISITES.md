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
```

This creates the projects used by Q1-Q15 and seeds only the resources that are intentionally present at exam start.

## 10. Final environment check

Run:

```bash
./scripts/verify-env.sh
```

Then confirm the projects:

```bash
oc get project | grep -E 'crdmson|tndy|totain|octane|acid|helm-lab|kustomize-lab|streams-lab|troubleshoot-lab|multi-lab|pipeline-lab|operator-lab'
```

You are ready when the cluster-wide checks pass, Pipelines is installed, the NGINX Gateway Fabric CRD exists, and the lab projects have been created.

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
