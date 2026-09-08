Q15 prerequisite: NGINX Gateway Fabric Operator is installed by scripts/bootstrap-crc.sh.

Validated CR:
  apiVersion: gateway.nginx.org/v1alpha1
  kind: NginxGatewayFabric
  metadata.name: exam-gateway
  spec: {}

Expected status includes Initialized=True and Deployed=True with reason InstallSuccessful.
Use oc api-resources / oc explain during practice rather than relying only on this note.
