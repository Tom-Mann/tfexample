#########################################################################
#Create system disk from image, the disk will be encripted by default cmk
#Please aware, it is not supported to using a customized key for encription
#when we create a volume from image
#You can refer to OTC help center for detail.
#########################################################################
resource "opentelekomcloud_blockstorage_volume_v2" "data-filer-sys-vol" {
  count    = "${var.filer_count}"
  name     = "data-filer-sys-vol-${count.index}"
  size     = 30
  image_id = "732b56f0-57d9-4b5b-8c9a-5bd8c8b76901"
  availability_zone = "eu-de-02"
  volume_type = "SATA"
}
##################################################################
#Create a blank volume
#__system__encrypted and __system__cmkid are used for encription
###################################################################
resource "opentelekomcloud_blockstorage_volume_v2" "data-filer-data-vol" {
  count = "${var.filer_count}"
  name  = "data-filer-data-vol-${count.index}"
  size  = "200"
  metadata = {
    "__system__encrypted" = 1
    "__system__cmkid" = "c62c8978-1153-48a0-b971-0f4752cbf401"
  }
}
resource "opentelekomcloud_compute_instance_v2" "data-filer" {
  count           = "${var.filer_count}"
  name            = "data-filer${count.index}"
  flavor_name     = "c2.large"
  key_pair        = "${opentelekomcloud_compute_keypair_v2.grid-terraform-key.name}"
  availability_zone = "eu-de-02"
  security_groups = [
    "${opentelekomcloud_compute_secgroup_v2.secgrp-data.name}"
  ]

  network {
    uuid           = "${opentelekomcloud_networking_network_v2.data-net.id}"
  }

  block_device {
    uuid = "${element(opentelekomcloud_blockstorage_volume_v2.data-filer-sys-vol.*.id,count.index)}"
    source_type           = "volume"
    boot_index            = 0
    destination_type      = "volume"
    delete_on_termination = true
  }
  depends_on = ["opentelekomcloud_networking_router_v2.grid-vpc", "opentelekomcloud_networking_subnet_v2.grid-subnet","opentelekomcloud_blockstorage_volume_v2.data-filer-sys-vol"]
}

resource "opentelekomcloud_compute_volume_attach_v2" "filer-volume_attach" {
  count       = "${var.filer_count}"
  instance_id = "${element(opentelekomcloud_compute_instance_v2.data-filer.*.id, count.index)}"
  volume_id   = "${element(opentelekomcloud_blockstorage_volume_v2.data-filer-data-vol.*.id, count.index)}"
  depends_on = ["opentelekomcloud_compute_instance_v2.data-filer"]
}

