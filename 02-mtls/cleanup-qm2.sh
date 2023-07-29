#!/bin/bash
#
#  (C) Copyright IBM Corp. 2021. All Rights Reserved.
#
# SPDX-License-Identifier: Apache-2.0
#
# Not for Production use. For demo and training only.
#
NAMESPACE=${1:-mq}

# delete queue manager
oc delete -n ${NAMESPACE} qmgr qm2
rm qm2-qmgr.yaml

# delete config map
oc delete -n ${NAMESPACE} cm example-02-qm2-configmap
rm qm2-configmap.yaml

# delete route
oc delete -n ${NAMESPACE} route example-02-qm2-route
rm qm2chl-route.yaml

oc delete -n ${NAMESPACE} route example-02-qm2-tls-route
rm qm2chl_tls-route.yaml

oc delete -n ${NAMESPACE} route example-02-qm2-mtls-route
rm qm2chl_mtls-route.yaml

# delete secrets
oc delete -n ${NAMESPACE} secret example-02-qm2-secret
oc delete -n ${NAMESPACE} secret example-02-app1-secret

# delete files
rm qm2.crt qm2.key app1key.* app1.* *.p12 *.jks ccdt.json 
