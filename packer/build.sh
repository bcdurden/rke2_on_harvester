#!/bin/bash
echo "Building recipe:"
cat recipe.yaml | tee builder/recipe.yaml
printf "\n\n\n"

echo "Packaging Builder environment"
tar czvf builder.tgz builder/ &> /dev/null

# variables consumed by envsubst
export VM_NAMESPACE=default
export VM_IMAGE=ubuntu
export BUILDER_DISK_SIZE_GB=40
export SSH_KEY=$(cat ~/.ssh/fulcrum.pub)
export SSH_PRIVATE_KEY="~/.ssh/fulcrum"
export OUTPUT_VM_NAME=ubuntu-jammy-rke2

# create Harvester builder environment VM and dependencies
cat env/builder_config.yaml | envsubst | kubectl apply -f -
kubectl create secret generic packer-disk --from-file=builder.tgz=builder.tgz --dry-run=client -o yaml | kubectl apply -f -
cat env/builder.yaml | envsubst | kubectl apply -f -

# wait for VM to start and post IP
echo "Waiting for Builder VM to start"
until [[ $(kubectl get virtualmachineinstance builder -o yaml | yq .status.phase) == "Running" ]]; do echo "."; sleep 5; done
until [[ $(kubectl get virtualmachineinstance builder -o yaml | yq .status.interfaces[0].ipAddresses[0]) != "null" ]]; do echo "."; sleep 5; done
IP=$(kubectl get virtualmachineinstance builder -o yaml | yq .status.interfaces[0].ipAddresses[0])

# wait until packer is finished
echo "Waiting for Builder VM to finish"
ssh -i ${SSH_PRIVATE_KEY} -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no ubuntu@${IP} "until [ -f /tmp/finished ]; do printf \".\"; sleep 5; done"

# get files
scp -i ${SSH_PRIVATE_KEY} -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no ubuntu@${IP}:/home/ubuntu/output/${OUTPUT_VM_NAME}-amd64.img ./
scp -i ${SSH_PRIVATE_KEY} -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no ubuntu@${IP}:/home/ubuntu/builder/init.log ./
scp -i ${SSH_PRIVATE_KEY} -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no ubuntu@${IP}:/home/ubuntu/builder/builder.log ./

echo "Image located here: ${OUTPUT_VM_NAME}-amd64.img"

# cleanup
kubectl delete virtualmachine builder
kubectl delete secret builder-cloudinit
kubectl delete pvc builder-disk
kubectl delete secret packer-disk
rm builder.tgz
rm builder/recipe.yaml