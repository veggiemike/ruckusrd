# NAME

Ruckusrd - manual page for Ruckusrd 0.22.0-dev

# DESCRIPTION

RuckusRD - a super awesome, yet simple, mkinitrd replacement Copyright ©
2012-2024 Michael D Labriola \<veggiemike@sourceruckus.org\>

usage: ruckusrd OPTIONS \<out-initrd-image\> \<kernel-version\>

**-h**, **--help**  
Show this help message and exit.

**-V**, **--version**  
Show version string and exit.

**-v**, **--verbose**  
Show verbose output.

**-f**, **--force**  
Force overwrite existing file.

**-b**, **--basedir** BASEDIR  
Use BASEDIR as prefix to all paths.

**-c**, **--compressor** COMPMODE  
Pick compressor mode. Valid options are 'best' and 'fast'. Default is
'fast'.

**-o**, **--options** LINUXRCOPTS  
Specifiy runtime options to pass to the linuxrc init script in the
generated initramfs.

**-U**, **--with-ucode** UCODE_IMG  
Include ucode.img in generated initramfs. Default is */boot/ucode.img*

**-N**, **--no-ucode**  
Do NOT append any microcode to the generated initramfs (probably only
useful for testing).

example: ruckusrd */boot/myinitramfs.img* \`uname **-r**\`

# SQUASHFS LAYERS

As always, the default behavior of the *linuxrc* script will be to
assemble a traditional root filesystem and switch over to it. However,
it also supports a special squashfs layering mechanism for quickly
creating new systems.

If **sqsh_layers=layer2:layer1** is provided on the kernel command line,
**layer1.sqsh** will be mounted at */layer1*, **layer2.sqsh** at
*/layer2*, etc. These layers will then be used as the "lower layers" for
an OverlayFS mount. Note that OverlayFS stacks lower layers from right
to left (i.e., **layer2** is stacked on top of **layer1**).

The "upper layer" is for read-write functionality. Unless overriden via
other parameters, a speical **upper** directory on the provided root
device will be used.

After switching root, this will result in the rootdev being at
**/mnt/root-true** with each read-only squashfs layer being mounted at
**/mnt/sqsh_layer-NAME**. Since the upper layer needs to be writable,
the rootdev will be mounted read-write (unless **ram_layer**, see
**BOOT** PARAMETERS).

All the squashfs image files are expected to be on the root of the
specified root device (unless **sqsh_layerdev**, see **BOOT
PARAMETERS**).

# FIRMWARE HANDLING

RuckusRD initramfs images can have a traditional *fw.img* (e.g., created
with **firmwarenator**(1)) appended to them, or even better you can use
**fwdev** on the kernel commandline to specify a device (which can be
the same as the root device) containing a SquashFS image of system
firmware named *fw.sqsh*. This method of firmware management makes
updating system firmware independent of the initrd or kernel upgrade
process. A giant *fw.sqsh* is built in *ruckusrd/subprojects/fw.sqsh*
out of ALL the latest firmware, but isn't installed (it is quite large),
or you can make a machine-specific one (again, with
**firmwarenator**(1)).

# MICROCODE HANDLING

Initramfs images created w/ RuckusRD automatically include
*/boot/ucode.img* (*subprojects/ucode.img* gets generated out of ALL the
latest Intel and AMD microcode as a convenience but not installed, or
you can generate a machine-specific version with **microcodenator**(1)).

# BOOT PARAMETERS

Initramfs created with *ruckusrd* will handle the following kernel
command line parameters, provided in groupings based on use-case.

## Regular/Common

**blacklist**=**MODULE**  
Add the specified **MODULE** to the system's kernel module blacklist
file, to prevent it from being autoloaded by udev.

**init**=**INIT**  
Provide path to alternate init binary, **INIT**.

**quiet**  
Don't make any terminal output if you can help it. Most distros use this
as a default boot parameter as to not interupt graphical boot screens.

**root**=**DEVSPEC**  
The single most important boot parameter! Specify where the root
filesystem is located, so we can use it! **DEVSPEC can be a plain device
name, or you** can specify a filesystem label (*LABEL*=), filesystem
UUID (*UUID*=), CD/DVD-ROM label (*CDLABEL*=), or ZFS dataset (*ZFS*=).

**rootflags**=**FLAGS**  
Specify extra **FLAGS** for mounting the root device.

**rootfstype**=**FSTYPE**  
Explicitly state the **FSTYPE** of the root device, instead of
auto-detecting.

**rw**  
Leave the sysroot mounted read-write before handing off to sysroot's
init system. Most init systems expect sysroot to be read-only when they
start (and that's the default behavior of *ruckusrd* initramfs), but
sometimes you need this.

**verbose**  
Make the *linuxrc* script be extra verbose, the exact opposite of
**quiet**. This is *very* noisy, so be warned.

## Squashfs Layers

**overlayflags**=**FLAGS**  
Specify extra **FLAGS** for mounting the Overlay File System.

**ram_layer**=**SIZE**  
Use RAM for the upper layer. This will result in tmpfs of the requested
**SIZE** mounted at **/upper**. Any valid value for the tmpfs **size**
option can be specified (e.g., 2G, 50%). Since rootdev will no longer
need to be writable, it will be mounted read-only.

**root_true_rw**  
Similar to **rw**, leave the root-true device mounted read-write before
handing off to sysroot's init system.

**sqsh_layerdev**=**DEV**  
Use **DEV** as an alternate device for locating the sqsh layers. **DEV**
will be mounted read-only. This is primarily for supporting sharing of a
read-only device between multiple virtual machines which all have their
own dedicated rootdev for the upper layer.

*NOTE:* This causes us to look at rootdev AND THEN sqsh_layerdev for
named layers. This way, we'll be able to have shared base images w/
host-specific extra layers. Otherwise, if a host with lots of changes
decides to create a new layer, it would have to have write access to
sqsh_layerdev (which it almost definately does not have).

*NOTE:* This option cannot be used along with **to_ram** because... why
would you do that? The point of **to_ram** is allowing for removal of
the root device after boot. To use **to_ram** with a separate sqshdev
would work in theory, as long as we copy layers from the correct path,
but how many different pieces of removable media are really going to
require at bootup? More than 1? I see no use-case for that.

**sqsh_layerdir**=**DIR**  
Use **DIR** as the relative path to the images provided via
**sqsh_layers**. This is so that the layers can be located somewhere
other than at the root of the specified device.

**sqsh_layers**=**SQSH_LAYERS**  
Specifiy tiered list of lower layers to be used along with a read-write
upper layer (on the **root** device) in an OverlayFS mount to be userd
as the sysroot. See **SQUASHFS LAYERS** for more details.

**sqshfstype**=**FSTYPE**  
Explicitly state the **FSTYPE** of the **sqsh_layerdev** device, instead
of auto-detecting.

**to_ram**  
Used in conjunction with **ram_layer**, causes the entire contents of
the rootdev to be loaded into RAM, so you can safely unmount the root
device (i.e., if it's a USB stick or DVD-ROM). Obviously, this requires
a small root dev or a large ammount of RAM... or both.

## Initramfs Debugging

**shell**  
Drop to a shell as soon as *linuxrc* script starts, before doing
anything, not even udev rule creation. As a regular user, you never want
this. It's convenient for testing and development of the *linuxrc*
script, though. In fact, there are more **shell\_\*** breakpoints
scattered through *linuxrc*... go grep for them.

## Maintenance

**maint**  
Drop to a maintenance shell AFTER assembling */sysroot*, just prior
handing off control to */sysroot*'s init system. When this shell exits,
sysroot boot continues. This gives you a convenient way to interrupt
boot to fix something silly, then continue booting w/out even having to
fully reboot.

## Other Super Cool Options

**firstboot**  
Prior to handing control over to sysroot, run our embedded
*firstboot_wizard* to pre-configure a bunch of things for the first boot
of a new system. Even if **firstboot** is specified, if
*.ruckusrd_firstboot_done* exists at the root of the sysroot filesystem,
*firstboot_wizard* will be skipped.

**fwdev**=**FWDEV**  
Specify a device containing *fw.sqsh*. If found, this squashfs image is
mounted on */lib/firmware* to provide firmware to modules loaded during
the initramrd stage (e.g., video cards, ethernet cards).

**hoststamp**  
Append a timestamp to system hostname. Probably only desired when using
**ram_layer** and/or **to_ram** to boot a bunch of systems from a common
image (i.e., an installer or live-disk).

**initramsys**  
Completely ignore sysroot. Invoke the initramfs's init instead, and
you've got a fully functional embedded system (complete with networking
and multiple TTYs to login on) w/out any root device.

**modinject**  
Inject kernel modules (and kernel header files) from the initramfs into
the sysroot. This ensures that the same modules exist post bootup that
exist during initrd, and removes the requirement of installing kernel
modules prior to booting a new kernel.

# KERNEL COMMAND LINE EXAMPLES

Regular system

root=/dev/sda1 quiet

Regular system w/ extra cool fun features

root=LABEL=rootishness quiet firstboot modinject fwdev=LABEL=firmware

Squashfs layers, read-write upper on rootdev

root=/dev/sda1 sqsh_layers=extra:server:base

Squashfs layers, read-write upper on rootdev but sqsh_layers on
alternate read-only device

root=/dev/xvda1 sqsh_layerdev=/dev/xvdb1 sqsh_layers=extra:server:base

Squashfs layers, read-only rootdev, RAM upper layer

root=/dev/sda1 sqsh_layers=extra:server:base ram_layer=50%

Squashfs layers, unmounted/removable rootdev, RAM upper layer

root=/dev/sda1 sqsh_layers=extra:server:base ram_layer=50% to_ram

# FILES

*/etc/ruckusrd.conf*  
System-wide default config file.

*~/.ruckusrd.conf*  
User config file, which is read last.

*/boot/ucode.img*  
Default path to microcode image to be prepended to generated initrd
file.

*/.ruckusrd_firstboot_done*  
Prevents *firstboot_wizard* from running even if **firstboot** boot
parameter was specified.

# SEE ALSO

**firmwarenator**(1), **microcodenator**(1), **kernel-builder**(1)
