# Packer builder for Harvester
Use Harvester to run a qemu instance to build a custom VM.

## Future Updates
* Auto download base VMI
* Auto create/delete ssh keys

Ensure your kubecontext is pointed at your Harvester cluster. Edit the [build.sh](./build.sh) script to ensure the parameters are correct and to your liking. The most important values are your SSH keys and the VM_IMAGE value.
```bash
# variables consumed by envsubst
export VM_NAMESPACE=default
export VM_IMAGE=ubuntu
export BUILDER_DISK_SIZE_GB=40
export SSH_KEY=$(cat ~/.ssh/fulcrum.pub)
export SSH_PRIVATE_KEY="~/.ssh/fulcrum"
export OUTPUT_VM_NAME=ubuntu-jammy-rke2
```

Edit your [recipe.yaml](./recipe.yaml) file to suit your custom VM image (its a cloud-init). Passwords and such do not persist.

Run the build script:

```console
$ ./build.sh
Building recipe:
#cloud-config
ssh_pwauth: True
package_update: true
packages:
- qemu-guest-agent
password: superpassword
chpasswd: { expire: False }
ssh_pwauth: True
runcmd:
- - systemctl
  - enable
  - '--now'
  - qemu-guest-agent.service
- mkdir -p /var/lib/rancher/rke2-artifacts && wget https://get.rke2.io -O /var/lib/rancher/install.sh && chmod +x /var/lib/rancher/install.sh


Packaging Builder environment
secret/builder-cloudinit created
secret/packer-disk configured
virtualmachine.kubevirt.io/builder created
Waiting for Builder VM to start
Error from server (NotFound): virtualmachineinstances.kubevirt.io "builder" not found
.
.
.
.
.
.
.
.
.
.
.
.
.
.
.
.
.
Waiting for Builder VM to finish
Warning: Permanently added '10.10.0.63' (ED25519) to the list of known hosts.
.....................................................Warning: Permanently added '10.10.0.63' (ED25519) to the list of known hosts.
ubuntu-jammy-rke2-amd64.img                                                                                         100%  755MB 276.3MB/s   00:02    
Warning: Permanently added '10.10.0.63' (ED25519) to the list of known hosts.
init.log                                                                                                            100% 3947     4.7MB/s   00:00    
Warning: Permanently added '10.10.0.63' (ED25519) to the list of known hosts.
builder.log                                                                                                         100%   57KB  12.6MB/s   00:00    
Image located here: ubuntu-jammy-rke2-amd64.img
virtualmachine.kubevirt.io "builder" deleted
secret "builder-cloudinit" deleted
persistentvolumeclaim "builder-disk" deleted
secret "packer-disk" deleted

```

Ensure your image copied successfully, it would be `ubuntu-jammy-rke2-amd64.img` in the above example. Check the log files for errors if it fails or pends indefinitely. The build should not take more than 5-10min.