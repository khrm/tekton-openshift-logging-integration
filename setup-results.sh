export SSL_CERT_PATH=${SSL_CERT_PATH:="/tmp/tekton-results/ssl"}
set +e
mkdir -p "${SSL_CERT_PATH}"
SSL_INCLUDE_LOCALHOST=${SSL_INCLUDE_LOCALHOST:-"true"}
altNames="DNS:tekton-results-api-service.openshift-pipelines.svc.cluster.local"
if [ "$SSL_INCLUDE_LOCALHOST" = "true" ] ; then
    altNames+=",DNS:localhost"
fi

openssl req -x509 \
        -newkey rsa:4096 \
        -keyout "${SSL_CERT_PATH}/tekton-results-key.pem" \
        -out "${SSL_CERT_PATH}/tekton-results-cert.pem" \
        -days 365 \
        -nodes \
        -subj "/CN=tekton-results-api-service.openshift-pipelines.svc.cluster.local" \
        -addext "subjectAltName = ${altNames}"

oc create secret tls -n openshift-pipelines tekton-results-tls --cert="${SSL_CERT_PATH}/tekton-results-cert.pem" --key="${SSL_CERT_PATH}/tekton-results-key.pem" || true
oc create secret generic tekton-results-postgres   --namespace=openshift-pipelines   --from-literal=POSTGRES_USER=result   --from-literal=POSTGRES_PASSWORD=$(openssl rand -base64 20) || true
oc create -f result.yaml
