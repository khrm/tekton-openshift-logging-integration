# Install Minio

Create statefulset, service and route for minio.
```
oc create -f minio.yaml
oc create -f minio-svc.yaml
oc expose svc/minio
```

If using OCP instead of crc, then use `minio-gcp.yaml`.


Get minio client and and then create bucket for logs.

```
mc alias set myminio http://route-url minioadmin minioadmin --insecure
mc mb myminio/loki
```

# Install Lokistack and OpenShift Logging Operator
Install OpenShift Logging Operator from operatorhub.
Install Red Hat supported Lokistack operator from operatorhub.

## Install Lokistack

Create minio secret and `LokiStack` resource using it.
```
oc create secret generic logging-loki-minio   --from-literal=bucketnames="loki"   --from-literal=endpoint="http://route-url"  --from-literal=access_key_id="minioadmin"   --from-literal=access_key_secret="minioadmin" -n openshift-logging
oc create -f lokistack.yaml
```

If using OCP instead of crc, then use `lokistack-gcp.yaml`.


## Install OpenShift Logging

Create `ClusterLogging` resource.
```
oc create -f logging.yaml
```

You should get an update for webconsole. On refreshing, you should be able to the see the Logs in Observe tab.


## Rolebinding to view logs

Create clusterrolebinding to view logs across the namespace.
```
oc create -f clusterrolebinding.yaml
```
