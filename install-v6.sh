if [ $(oc get crd | grep lokistack | wc -l) -lt 1 ]; then
    echo "Please Install LokiStack Operator or wait for installation to finish"
fi

if [ $(oc get crd | grep clusterlogforwarder | wc -l) -lt 1 ]; then
    echo "Please Install OpenShift Logging Operator or wait for installation to finish"
fi

### Installing Minio
oc create -f minio.yaml
oc create -f minio-svc.yaml
oc expose svc/minio
kubectl wait pod "minio-0"  --for="condition=Ready" --timeout="120s"
minioURL=$(oc get route minio  --no-headers -o custom-columns=":spec.host")
mc alias set myminio http://${minioURL} minioadmin minioadmin --insecure
mc mb myminio/loki

### Installing Loki
oc create secret generic logging-loki-minio   --from-literal=bucketnames="loki"   --from-literal=endpoint="http://${minioURL}"  --from-literal=access_key_id="minioadmin"   --from-literal=access_key_secret="minioadmin" -n openshift-logging
#### Setting storage to default.
sed -i "s/storageClassName.*/storageClassName: $(kubectl get storageclass | grep default | awk '{print $1}')/g" lokistack.yaml
oc create -f lokistack.yaml

### Installing OpenShift Logging
#### Create Service Account and give it permission required.
oc create sa collector -n openshift-logging
oc adm policy add-cluster-role-to-user logging-collector-logs-writer system:serviceaccount:openshift-logging:collector
oc adm policy add-cluster-role-to-user collect-application-logs system:serviceaccount:openshift-logging:collector
oc adm policy add-cluster-role-to-user collect-audit-logs system:serviceaccount:openshift-logging:collector
oc adm policy add-cluster-role-to-user collect-infrastructure-logs system:serviceaccount:openshift-logging:collector
oc create -f clf6.yaml
