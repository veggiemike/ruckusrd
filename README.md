RuckusRD - a super awesome, yet simple, mkinitrd replacement
============================================================

Copyright 2012-2025 Michael D Labriola <veggiemike@sourceruckus.org>

Licensed under the GPLv3. See the file COPYING for details. 

This utility is a derivative of fedora's livecd-creator's `mayflower` script,
written by David Zeuthen <davidz@redhat.com>, circa Fedora 8 (oh my gosh old).

It's been largely rewritten to be a `mkinitrd` replacement specifically for
embedded systems and removable media, but it's also perfectly usable on normal
desktop Linux systems.


Strengths:

 1.  Layered Squashfs Root Filesystem.  When supplied with one or more
     sqsh_layers containing a root filesystem, an initrd created by RuckusRD
     will create a read-write virtual device for the rootfs by combining the
     squashfs image(s) (read-only by nature) with a read-write upper layer.  If
     another block device is used for the upper layer, changes to the system
     will be persistent.  If the upper layer is RAM, the system becomes
     non-persistent (any changes will go away upon reboot).
     
     Furthermore, when using RAM for upper layer, the lower sqsh_layers can be
     loaded entirely into RAM, enabling the user to unmount and remove the boot
     media.

     You don't HAVE to use sqsh_layers, though.  You can use an initrd created
     by RuckusRD to boot a normal old root filesystem and still benefit from
     the other bits of awesomeness RuckusRD provides.

     See [sqsh_layers.txt](docs/sqsh_layers.txt) for more info.

 2.  Universal Initramfs.  Images created by RuckusRD can be used for multiple
     machines with different hardware without regenerating initrd.  All the
     kernel modules needed for early boot (e.g., sccsi, filesystems),
     maintenance shells (e.g., USB HID, keyboard), and networking (e.g.,
     wired/wireless subsystems, protocols, device drivers) are included in the
     initramfs, along with any modules they in turn require.

     Actually, as of v0.16, ALL kernel modules are included in the initramfs so
     that everything the kernel was configured to be able to do is fully
     availabile in the maintenence shell.

     All modules and kernel headers can be injected into the root filesystem
     once mounted (if the initrd was created w/ `-o modinject=1`), making
     simply booting the kernel into a kernel installation mechanism (super
     handy for VMs or kernel testing).

 3.  Swiss army knife maintenance shell of doom.  Just add `maint` to the
     kernel commandline.  The maintenence shell provided is a fully functional
     embedded rootfs with BusyBox, eudev, lvm, mdadm, e2fsprogs,
     squashfs-tools, the OpenZFS userland tools, syslinux, efibootmgr, wired
     networking utilities, rsync, ssh, and fsarchiver.  When the `maint` shell
     exits, bootup continues.

     Alternatively, you can use `initramsys` or `initramsys-net` to forgo the
     sysroot entirely and just launch an embedded Linux system.  In this case,
     you can do sysroot maintenance easily using the `mount_sysroot` command to
     get yourself ready to chroot into the sysroot (complete with virutal
     filesystems and all additional sysroot mountpoints (e.g., /home)).

 4.  Easy microcode loading/updating.  Initramfs images created w/ RuckusRD
     automatically include `/boot/ucode.img` (`subprojects/ucode.img` gets
     generated out of ALL the latest Intel and AMD microcode as a convenience
     but not installed, or you can generate a machine-specific version with
     `microcodenator`).

 5.  Firmware loading made easy.  RuckusRD initramfs images can have an
     appropriate `fw.img` (e.g., created with `firmwarenator`) appended to them, or
     even better you can use `fwdev=DISK` on the kernel commandline to specify a
     device containing `fw.sqsh`.  This makes updating firmware independent of
     the initrd or kernel upgrade process.  A giant `fw.sqsh` is built in
     `subprojects/fw.sqsh` out of ALL the latest firmware, but isn't installed.
     Alternatively, you can create a machine-specific set of firmware with
     `firmwarenator`.

 6.  Built-in `firstboot_wizard` for last-minute configuration of newly built
     systems.  Similar to most distro installers and/or firstboot wizards, this
     is perfect if you're fapidly provisioning machines based off of a common
     image (or set of sqsh_layers!).  All configuration is done from within the
     initramfs, prior to handing off control to the system's init process.

 7.  Embedded system installer right in the initramfs!  You can bundle up
     sqsh_layers (and a config file describing them) and use
     `initramsys-installer` to boot up and install on blank disks.  Disks will
     be auto-detected, setup in an appropriate ZFS pool (yes, ZFS for rootfs!),
     and prepped with selected sqsh_layers.  EFI booting will be configured via
     syslinux on potentially multiple ESPs.

     See https://github.com/sourceruckus/sourceruckus-deb for an example
     project that wraps Ubuntu sqsh_layers with a RuckusRD initramfs installer,
     and https://github.com/sourceruckus/linux-mdl for longterm kernel sources
     w/ ZFS already merged in!


See the [manpage](ruckusrd.1.md) for more details, or [docs](docs/)
for more developmental ramblings.  ;-)

Get the latest and greatest from https://github.com/sourceruckus/ruckusrd and
take a gander at the sister utilities `firmwarenator` and `microcodenator` at
https://github.com/sourceruckus/firmwarenator and
https://github.com/sourceruckus/microcodenator.
