# your Kubernetes cluster name here
cluster_name = "mycluster"

# list of availability zones available in your OpenStack cluster
az_list = ["dc3-a-04", "dc3-a-09", "dc3-a-10"]
az_list_node = ["dc3-a-04", "dc3-a-09", "dc3-a-10"]

# SSH key to use for access to nodes
public_key_path = "/home/kubespray/sshkey.pub"

# image to use for bastion, masters, standalone etcd instances, and nodes
image = "Debian 11 bullseye"

# user on the node (ex. core on Container Linux, ubuntu on Ubuntu, etc.)
ssh_user = "debian"

# 0|1 bastion nodes
number_of_bastions = 0

# standalone etcds
number_of_etcd = 0

# masters
number_of_k8s_masters = 1

number_of_k8s_masters_no_etcd = 0

number_of_k8s_masters_no_floating_ip = 0

number_of_k8s_masters_no_floating_ip_no_etcd = 0

# a2-ram4-disk80-perf1
flavor_k8s_master = "60298864-77b4-4058-9861-50fea072c5fd"

# nodes
number_of_k8s_nodes = 0

number_of_k8s_nodes_no_floating_ip = 3

# a4-ram8-disk80-perf1
flavor_k8s_node = "d120e7de-01a3-4aca-b7e6-0fae9e9e7937"

# GlusterFS
# either 0 or more than one
#number_of_gfs_nodes_no_floating_ip = 0
#gfs_volume_size_in_gb = 150
# Container Linux does not support GlusterFS
#image_gfs = "<image name>"
# May be different from other nodes
#ssh_user_gfs = "ubuntu"
#flavor_gfs_node = "<UUID>"

# networking
network_name = "mycluster"

# ext-floating1
external_net = "0f9c3806-bd21-490f-918d-4a6d1c648489"

subnet_cidr = "10.10.0.0/24"

floatingip_pool = "ext-floating1"

k8s_allowed_remote_ips = ["yourip"]

dns_nameservers = ["83.166.143.51", "83.166.143.52"]

master_allowed_ports = [
   {
      "protocol"         = "icmp"
      "port_range_min"   = 0
      "port_range_max"   = 0
      "remote_ip_prefix" = "0.0.0.0/0"
    },
]
