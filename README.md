Demo kubespray at Infomaniak Public Cloud
=========================================

Intro
-----

Bootstraps a full featured kubernetes cluster using:
- [Infomaniak Public Cloud](https://www.infomaniak.com/en/hosting/public-cloud)
- [kubespray](https://kubespray.io/#/)
- [terraform](https://www.terraform.io/)

It will create a 1 master 3 worker nodes cluster with:
- [cri-o](https://cri-o.io/) container engine
- [cilium](https://cilium.io/) CNI
- openstack external [cloud provider](https://github.com/kubernetes/cloud-provider-openstack)

using only one floating address for the master and API access

Persistent volumes are provided by cinder and cinder-csi plugin

Services of type Load balancer are provided by octavia

It takes approximately 50 seconds to create the infrastructure with terraform,
and an additional 5 minutes to bootstrap the cluster.

## Prepararation

Create a new openstack project in Infomaniak management pannel and download
openstack credentials

Source those credentials:

```shell
. openstack_config.txt
```

Set cluster name

```shell
export CLUSTER=mycluster
```

Create an ssh key and launch an agent

```shell
ssh-keygen -C "kubespray-$CLUSTER" -f $PWD/sshkey -t ed25519 -N ""
eval $(ssh-agent)
ssh-add sshkey
```

Prepare python virtual env

```shell
python3 -m venv venv
. venv/bin/activate
pip install -U pip wheel
```

Install terraform

```shell
mkdir bin
curl -L -o terraform_1.0.8_linux_amd64.zip https://releases.hashicorp.com/terraform/1.0.8/terraform_1.0.8_linux_amd64.zip
cd bin
unzip ../terraform_1.0.8_linux_amd64.zip
cd ..
export PATH=$PWD/bin:$PATH
```

Install kubectl

```shell
curl -L -o bin/kubectl "https://storage.googleapis.com/kubernetes-release/release/$(curl -s https://storage.googleapis.com/kubernetes-release/release/stable.txt)/bin/linux/amd64/kubectl"
chmod +x bin/kubectl
```

Download kubespray

```shell
git clone --branch release-2.18 https://github.com/kubernetes-sigs/kubespray kubespray
cd kubespray
pip install -r requirements.txt
```

## create infrastructure (terraform)

via https://github.com/kubernetes-sigs/kubespray/tree/release-2.18/contrib/terraform/openstack

Prepare inventory

```shell
mkdir inventory/$CLUSTER
cd inventory/$CLUSTER
export TERRAFORM_STATE_ROOT=$PWD
terraform init -from-module=../../contrib/terraform/openstack
cp sample-inventory/cluster.tfvars .
rm -r sample-inventory/
cp -r ../sample/group_vars/ group_vars
ln -sf ../../contrib/terraform/openstack/hosts
```

Now, add this inside `terraform {}` in `versions.tf` to store the states in the object store:

```terraform
  backend "swift" {
    container           = "elastic-terraform-state"
    archive_container   = "elastic-terraform-state-archive"
  }
```

And patch the `hosts` script to read from object storage when possible:

```shell
curl -sf https://raw.githubusercontent.com/reneluria/demo-infomaniak-kubespray/main/hosts.patch | patch -p0 --dry-run
```

Edit *cluster.tfvars*

[here](cluster.tfvars) is an example

?????? don't forget to update the ssh key path and k8s_allowed_remote_ips
to match the ip address/range/list to allow to connect to your cluster ??????

Apply

```shell
terraform apply -var-file=cluster.tfvars
```

## kubespray inventory

Adapt group_vars with the following or with this [patch file](group_vars.diff)

```shell
patch -p0 < group_vars.diff
```

### all/all.yml

```diff
-etcd_kubeadm_enabled: false
+etcd_kubeadm_enabled: true

+upstream_dns_servers:
+  - 83.166.143.51
+  - 83.166.143.52

+nameservers:
+  - 83.166.143.51
+  - 83.166.143.52

+cloud_provider: external
+external_cloud_provider: openstack

+download_container: false

+download_keep_remote_cache: true

```

### all/cri-o.yml

```yaml
---
crio_registries_mirrors:
  - prefix: docker.io
    insecure: false
    blocked: false
    location: registry-1.docker.io
    mirrors:
      - location: mirror.gcr.io
        insecure: false

crio_pids_limit: 4096
```

### all/openstack.yml

```yaml
---
external_openstack_lbaas_subnet_id: <- private_subnet_id from terraform output
external_openstack_lbaas_floating_network_id: <- floating_network_id from terraform output
cinder_csi_enabled: true
cinder_csi_ignore_volume_az: true
```

### k8s_cluster/k8s-cluster.yml

```diff
-dns_domain: "{{ cluster_name }}"
+dns_domain: cluster.local

-kube_network_plugin: calico
+kube_network_plugin: cilium

-resolvconf_mode: docker_dns
+resolvconf_mode: host_resolvconf

-container_manager: docker
+container_manager: crio

+kubeconfig_localhost: true

-persistent_volumes_enabled: false
+persistent_volumes_enabled: true
+expand_persistent_volumes: true
```

also update `cluster_name: cluster.local` to match your cluster name

openstack resources created by the cloud controler manager will use this value as a prefix

## kubespray ansible playbook

```shell
cd ..
cd ..
```

Install mitogen to speed things up

```shell
ansible-playbook mitogen.yml
```

Test connectivity to all nodes

```shell
ansible -i inventory/$CLUSTER/hosts -m ping all
```

Install cluster

```shell
ansible-playbook --become -i inventory/$CLUSTER/hosts cluster.yml
```

## test

kubeconfig

```shell
export KUBECONFIG=$PWD/inventory/$CLUSTER/artifacts/admin.conf
```

## end-to-end test

Create a pod a try to consume kubernetes API.

This validates pod creations, network connectivity and API

```shell
kubectl run -ti --rm --restart=Never --overrides='{"spec": { "terminationGracePeriodSeconds" :0 } }' toolbox --image=ghcr.io/reneluria/alpinebox:1.3.2 -- bash -c 'curl --cacert /var/run/secrets/kubernetes.io/serviceaccount/ca.crt -H "Authorization: Bearer $(</var/run/secrets/kubernetes.io/serviceaccount/token)" https://kubernetes.default/api'
```

That's all, you can use the *kubeconfig* file at inventory/$CLUSTER/artifacts/admin.conf
