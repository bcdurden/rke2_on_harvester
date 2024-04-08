# RKE2 on Harvester via Helm

This helmchart will start as a simple PoC for deploying an RKE2 cluster onto Harvester directly without use of other infrastructure tools. This cluster will be of a static state and VM-based. If you need LCM capability of your cluster, this could be a starting point but the Rancher MCM interface is significantly more rich and sophisticated.
[Helm Charts for Rancher MCM downstream clusters](https://github.com/rancherfederal/rancher-cluster-templates)

## Prereqs
* kubectl
* helm
* Harvester cluster
* VM image preloaded in Harvester
* yq


## Usage
Follow the simple checklist before installing:

* Create a `values.yaml` file containing the non-defaults for your cluster and environment or use the command-line. 
* Ensure you have a VM image defined in Harvester for your nodes or use the `vm.create` feature.
* Ensure your kubecontext is set to your Harvester cluster directly. This will not work on normal K8S clusters that do not have the Harvester CRDs
* Ensure your SSH public key value is provided or you will not be able to fetch the kubeconfig.

Kick off the install using helm-cli:
Example usage:
```console
> helm install cluster --set control_plane.vip=10.10.0.5 --set ssh_pub_key="$(cat ~/.ssh/fulcrum.pub)" --set control_plane.node_count=3 --set worker.node_count=0 --set control_plane.ipam=static charts/rke2

NAME: cluster
LAST DEPLOYED: Fri Apr  5 12:15:11 2024
NAMESPACE: default
STATUS: deployed
REVISION: 1
TEST SUITE: None
```

View the deployment through the Harvester UI:
![image](images/vm_deployed.png)

Using your SSH key, watch the cloud init status until it runs to completion:
`ssh -i ~/.ssh/fulcrum -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no ubuntu@10.10.0.6 "while [ ! -f /var/lib/cloud/instance/boot-finished ]; do echo 'Waiting for Cloud-Init...'; sleep 5; done" `

```console
> ssh -i ~/.ssh/fulcrum -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no ubuntu@10.10.0.6 "while [ ! -f /var/lib/cloud/instance/boot-finished ]; do echo 'Waiting for Cloud-Init...'; sleep 5; done" 
Warning: Permanently added '10.10.0.6' (ED25519) to the list of known hosts.
Waiting for Cloud-Init...
Waiting for Cloud-Init...
Waiting for Cloud-Init...
Waiting for Cloud-Init...
```

Grab the kubeconfig from one of the nodes (I use 10.10.0.6 here) and set the url with your VIP
```console 
export VIP=$(helm get values cluster | yq .control_plane.vip)
ssh -i ~/.ssh/fulcrum -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no ubuntu@10.10.0.6 "sudo cat /etc/rancher/rke2/rke2.yaml" 2> /dev/null | \
sed "s/127.0.0.1/${VIP}/g" > kube.yaml
```

Check your node state, in my example I expect to see 3 nodes:
```console
> kubectl --kubeconfig kube.yaml get nodes
NAME             STATUS   ROLES                       AGE     VERSION
mycluster-cp-0   Ready    control-plane,etcd,master   5m36s   v1.26.10+rke2r2
mycluster-cp-1   Ready    control-plane,etcd,master   4m28s   v1.26.10+rke2r2
mycluster-cp-2   Ready    control-plane,etcd,master   4m11s   v1.26.10+rke2r2
```

## Upcoming Features

Packer builder for VM image.