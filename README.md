RuckusRD - a super awesome, yet simple, mkinitrd replacement
============================================================

Copyright 2012-2023 Michael D Labriola <veggiemike@sourceruckus.org>

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
     networking utilities, rsync, and ssh.

 4.  Easy microcode loading/updating.  Initramfs images created w/ RuckusRD
     automatically include /boot/ucode.img (subprojects/ucode.img gets
     generated out of ALL the latest Intel and AMD microcode but not installed,
     or you can generate a machine-specific version with microcodenator).

 5.  Firmware loading made easy.  RuckusRD initramfs images can have an
     appropriate `fw.img` (e.g., created with `firmwarenator`) appended to them, or
     even better you can use `FWDEV=disk` on the kernel commandline to specify a
     device containing `fw.sqsh`.  This makes updating firmware independent of
     the initrd or kernel upgrade process.  A giant `fw.sqsh` is built in
     `subprojects/fw.sqsh` out of ALL the latest firmware, but isn't installed.
     Alternatively, you can create a machine-specific set of firmware with
     `firmwarenator`.

See [docs](docs/) for more ramblings.  ;-)

Get the latest and greatest from https://github.com/sourceruckus/ruckusrd and
take a gander at the sister utilities firmwarenator and microcodenator at
https://github.com/sourceruckus/firmwarenator and
https://github.com/sourceruckus/microcodenator.

<pre>
usage: ruckusrd OPTIONS <out-initrd-image> <kernel-version>

  -h, --help                  Show this help message and exit.

  -V, --version               Show version string and exit.

  -v, --verbose               Show verbose output.

  -f, --force                 Force overwrite existing file.

  -b, --basedir BASEDIR       Use BASEDIR as prefix to all paths.

  -c, --compressor COMPMODE   Pick compressor mode.  Valid options are 'best'
                              and 'fast'.  Default is 'fast'.

  -o, --options LINUXRCOPTS   Specifiy runtime options to pass to the linuxrc
                              init script in the generated initramfs.

  -U, --with-ucode UCODE_IMG  Include ucode.img in generated initramfs.  Default
                              is /boot/ucode.img

example: ruckusrd /boot/myinitramfs.img `uname -r`
</pre>
