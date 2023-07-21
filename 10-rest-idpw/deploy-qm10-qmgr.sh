#!/bin/bash
#
#  (C) Copyright IBM Corp. 2021. All Rights Reserved.
#
# SPDX-License-Identifier: Apache-2.0
#
# Not for Production use. For demo and training only.
#

# Create a config map containing MQSC commands

openssl pkcs12 -in es-cert.p12 -out tls.key -nodes -nocerts

oc apply -n cp4i -f qm10-configmap.yaml

# Create a config map for mqwebuser.xml

cat > qm10-web-configmap.yaml << EOF
apiVersion: v1
kind: ConfigMap
metadata:
  name: example-10-qm10-web-configmap
  namespace: cp4i
data:
  mqwebuser.xml: |-
    <?xml version="1.0" encoding="UTF-8"?>
    <server>
    <featureManager>
        <feature>apiDiscovery-1.0</feature>
        <feature>appSecurity-2.0</feature>
        <feature>basicAuthenticationMQ-1.0</feature>
    </featureManager>

    <enterpriseApplication id="com.ibm.mq.console">
        <application-bnd>
            <security-role name="MQWebAdmin">
                <group name="MQWebAdminGroup" realm="defaultRealm"/>
            </security-role>
            <security-role name="MQWebAdminRO">
                <group name="MQWebAdminROGroup" realm="defaultRealm"/>
            </security-role>
            <security-role name="MQWebUser">
                <special-subject type="ALL_AUTHENTICATED_USERS"/>
            </security-role>
            <security-role name="MFTWebAdmin">
                <user name="mftadmin" realm="defaultRealm"/>
            </security-role>
            <security-role name="MFTWebAdminRO">
                <user name="mftreader" realm="defaultRealm"/>
            </security-role>
        </application-bnd>
    </enterpriseApplication>

    <enterpriseApplication id="com.ibm.mq.rest">
        <application-bnd>
            <security-role name="MQWebAdmin">
                <group name="MQWebAdminGroup" realm="defaultRealm"/>
            </security-role>
            <security-role name="MQWebAdminRO">
                <user name="mqreader" realm="defaultRealm"/>
            </security-role>
            <security-role name="MQWebUser">
                <special-subject type="ALL_AUTHENTICATED_USERS"/>
            </security-role>
            <security-role name="MFTWebAdmin">
                <user name="mftadmin" realm="defaultRealm"/>
            </security-role>
            <security-role name="MFTWebAdminRO">
                <user name="mftreader" realm="defaultRealm"/>
            </security-role>
        </application-bnd>
    </enterpriseApplication>

    <basicRegistry id="basic" realm="defaultRealm">
    <user name="app1" password="{hash}ATAAAAAIGH/rX4J8t/JAAAAAIJyjgH3qpIZ115Lj1lWJ6ds7Pyw2T8ri5pfB+PFqPohV"/>
    <user name="mqadmin" password="{hash}ATAAAAAIGH/rX4J8t/JAAAAAIJyjgH3qpIZ115Lj1lWJ6ds7Pyw2T8ri5pfB+PFqPohV"/>
    <user name="mqreader" password="{hash}ATAAAAAIGH/rX4J8t/JAAAAAIJyjgH3qpIZ115Lj1lWJ6ds7Pyw2T8ri5pfB+PFqPohV"/>
        <group name="MQWebAdminGroup">
           <member name="mqadmin"/>
        </group>
        <group name="MQWebAdminROGroup">
           <member name="mqreader"/>
        </group>
    </basicRegistry>

    <variable name="httpHost" value="*"/>

    <sslDefault sslRef="mqDefaultSSLConfig"/>

    <variable name="managementMode" value="externallyprovisioned"/>

    </server>
EOF

oc apply -n cp4i -f qm10-web-configmap.yaml

# Create service and route for MQ REST server

cat > qm10-svc-route.yaml << EOF
kind: Service
apiVersion: v1
metadata:
  name: example-10-qm10-rest-svc
spec:
  ports:
    - name: qmgr
      protocol: TCP
      port: 9443
      targetPort: 9443
  selector:
    app.kubernetes.io/component: integration
    app.kubernetes.io/instance: qm10
    app.kubernetes.io/name: ibm-mq
  type: ClusterIP
  sessionAffinity: None
---
apiVersion: route.openshift.io/v1
kind: Route
metadata:
  name: example-10-qm10-rest-route
spec:
  to:
    kind: Service
    name: example-10-qm10-rest-svc
  port:
    targetPort: 9443
  tls:
    termination: passthrough
  wildcardPolicy: None
EOF

oc apply -n cp4i -f qm10-svc-route.yaml

# Deploy the queue manager

cat > qm10-qmgr.yaml << EOF
apiVersion: mq.ibm.com/v1beta1
kind: QueueManager
metadata:
  name: qm10
spec:
  license:
    accept: true
    license: L-RJON-CD3JKX
    use: NonProduction
  queueManager:
    name: QM10
    ini:
      - configMap:
          name: example-10-qm10-configmap
          items:
            - qm10.ini
    mqsc:
    - configMap:
        name: example-10-qm10-configmap
        items:
        - qm10.mqsc
    storage:
      queueManager:
        type: ephemeral
  version: 9.3.0.0-r2
  template:
    pod:
      containers:
        - env:
            - name: MQ_ENABLE_EMBEDDED_WEB_SERVER
              value: 'true'
          ports:
            - containerPort: 9443
              protocol: TCP
          volumeMounts:
            - name: mqwebuser
              readOnly: true
              mountPath: "/etc/mqm/web/installations/Installation1/servers/mqweb/mqwebuser.xml"
              subPath: mqwebuser.xml
          name: qmgr
      volumes:
        - name: mqwebuser
          configMap:
            name: example-10-qm10-web-configmap
            items:
              - key: mqwebuser.xml
                path: mqwebuser.xml
            defaultMode: 420
  web:
    enabled: false
EOF

oc apply -n cp4i -f qm10-qmgr.yaml

# wait 5 minutes for queue manager to be up and running
# (shouldn't take more than 2 minutes, but just in case)
for i in {1..60}
do
  phase=`oc get qmgr -n cp4i qm10 -o jsonpath="{.status.phase}"`
  if [ "$phase" == "Running" ] ; then break; fi
  echo "Waiting for qm10...$i"
  oc get qmgr -n cp4i qm10
  sleep 5
done

if [ $phase == Running ]
   then echo Queue Manager qm10 is ready; 
   exit; 
fi

echo "*** Queue Manager qm10 is not ready ***"
exit 1
