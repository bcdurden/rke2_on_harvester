#!/bin/bash
echo "Building recipe:"
cat recipe.yaml | tee builder/recipe.yaml
printf "\n\n\n"

echo "Packaging Builder environment"
tar czvf builder.tgz builder/ &> /dev/null

# variables consumed by envsubst
export VM_FILENAME=ubuntu-jammy-rke2-amd64.img

# create Harvester builder environment VM and dependencies
kubectl create secret generic packer-disk --from-file=builder.tgz=builder.tgz --dry-run=client -o yaml | kubectl apply -f -

kubectl apply -f builder.yaml
sleep 5
kubectl logs builder-pod  -c build -f

until [[ $(kubectl get po builder-pod -o yaml | yq .status.phase) == "Running" ]]; do sleep 1; done
kubectl cp builder-pod:results/${VM_FILENAME} ${VM_FILENAME}
kubectl delete -f builder.yaml

printf "\nImage located here: ${VM_FILENAME}\n"

# cleanup
rm builder.tgz
rm builder/recipe.yaml