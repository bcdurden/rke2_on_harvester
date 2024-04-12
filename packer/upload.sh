#!/bin/bash
# params:
# HARVESTER_VIP
# HARVESTER_PASSWORD

export IMAGE_NAME=ubuntu-rke2
export IMAGE_FILE=$(ls *.img)
export NAMESPACE=default

echo "Acquiring API Token"
export TOKEN=$(curl -sk -X POST https://${HARVESTER_VIP}/v3-public/localProviders/local?action=login -H 'content-type: application/json' -d '{"username":"admin","password":"'${HARVESTER_PASSWORD}'"}' | jq -r '.token')

export IMAGE_SIZE=$(stat -c%s "$IMAGE_FILE")
echo "Creating VM Image object"
cat templates/vmi.yaml | envsubst | \
curl -sk -X POST -H "Authorization: Bearer ${TOKEN}" \
    -H "Content-Type: application/yaml" \
    --data-binary @- \
    "https://${HARVESTER_VIP}/v1/harvester/harvesterhci.io.virtualmachineimages/${NAMESPACE}" &> /dev/null

echo "Wait for Longhorn backend to open reader pod"
sleep 5

echo "Uploading ${IMAGE_NAME}"
curl -sk -X POST -H "Authorization: Bearer ${TOKEN}"\
    -F "chunk=@${IMAGE_FILE}" \
    "https://${HARVESTER_VIP}/v1/harvester/harvesterhci.io.virtualmachineimages/${NAMESPACE}/${IMAGE_NAME}?action=upload&size=${IMAGE_SIZE}"

# wait a bit for progress to catch up to etcd entry
sleep 5

if [[ $(kubectl get virtualmachineimage ubuntu-rke2 -o go-template='{{.status.progress}}') == "100" ]]; then echo "Image successfully uploaded";
else echo "There was an error uploading the image: $(kubectl get virtualmachineimage ubuntu-rke2 -o go-template='{{.status}}')"
fi
