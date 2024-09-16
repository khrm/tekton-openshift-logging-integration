oc create -f minio.yaml
oc create -f minio-svc.yaml
oc expose svc/minio
kubectl wait pod "minio-0"  --for="condition=Ready" --timeout="120s"
minioURL=$(oc get route minio  --no-headers -o custom-columns=":spec.host")
mc alias set myminio http://${minioURL} minioadmin minioadmin --insecure
mc mb myminio/loki
oc create secret generic logging-loki-minio   --from-literal=bucketnames="loki"   --from-literal=endpoint="http://${minioURL}"  --from-literal=access_key_id="minioadmin"   --from-literal=access_key_secret="minioadmin" -n openshift-logging
oc create -f lokistack-gcp.yaml
oc create -f logging-gcp.yaml
oc create -f clusterlogforwarder.yaml
