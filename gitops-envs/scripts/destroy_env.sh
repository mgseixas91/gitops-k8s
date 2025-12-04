#!/bin/bash
ENV=$1

echo "Deletando namespace $ENV e todos os apps"
kubectl delete ns $ENV --wait

