#!/bin/ash
#
# Copyright 2012-2025 Michael D Labriola <veggiemike@sourceruckus.org>
#
# Licensed under the GPLv3. See the file COPYING for details. 
#


# define pushd/popd aliases because ash doesn't implement them and all our
# scripts are designed to run from within the initramfs using ash.
alias pushd='wd="$(pwd) ${wd}" && cd'
alias popd='cd ${wd%% *} && wd=${wd#* }'


# prepend $* with "ruckusrd:" label, while potentially reordering $* so that
# command line args to echo (e.g., -n) are still at the front (so echo will
# actually consume them).
#
# NOTE: If -n has been specified, the "ruckusrd:" label is NOT preppended
#       (because -n is used for continually updating the line and we don't want
#       multiple "ruckusrd:" labels).  In this case, it's up to the user to add
#       it.
#
# FIXME: This does eat leading space off of the output message, even if
#        quoted... not sure I like that... but I don't think I can fix it...
#
__preppend_and_reorder()
{
    flags=
    preppend="ruckusrd: "
    # iterate through $* until $1 does NOT start with a flag
    while [ -n "$1" ]; do
        case "$1" in
            -*n*)
                # don't preppend in this case, as we're doing some sort of
                # updating line thingy (e.g., . . . . accross the screen until
                # finished).
                preppend=
                ;;
        esac
        case "$1" in
            -*)
                [ -n "$flags" ] && flags="$flags "
                flags="$flags$1"
                shift
                ;;
            *)
                # as soon as we encounter an item that isn't potentially a
                # command line option to echo, we stop parsing things.
                break
                ;;
        esac
    done
    echo "$flags $preppend$*"
}


decho()
{
    if [ -z "$quiet" ] || [ -n "$verbose" ]; then
        echo $(__preppend_and_reorder $*)
    fi
}


decho2()
{
    if [ -n "$verbose" ]; then
        echo $(__preppend_and_reorder $*)
    fi
}


# Wait up to $1 seconds for any of the specified device nodes to exist.  If
# timeout occurs, something is wrong, but maybe the user can fix it, so we drop
# to an emergency shell.
#
# Example: wait_for_dev 10 fwdev LABEL=FIRMWARE
#
# Example: wait_for_dev 10 fwdev LABEL=ESP LABEL=ESP2
#
# Example: wait_for_dev 10 "at least ond hdd" /dev/sda /dev/nvme0n1 /dev/xvda
#
# Example: wait_for_dev 30 "/dev/root symlink" /dev/root
#
# NOTE: Creates /dev/lastwaited symlink pointing at either the device that
#       eventually showed up or /dev/null... in case you need an extra way of
#       checking status.
#
wait_for_dev()
{
    seconds=$1
    txt=$2
    shift 2
    devices=$*

    msg="waiting up to $seconds seconds for $txt to appear..."
    found=
    ln -fs /dev/null /dev/lastwaited
    while [ $seconds -gt 0 ]; do
        if [ -n "$msg" ]; then
            decho -n ruckusrd: $msg
            msg=""
        else
            decho -n "."
        fi
        # just in case we need to activate LVM on a freshly plugged device
        # (e.g., USB that was a bit slow to register)
        vgchange -a y --quiet --quiet
        # check for each device
        for dev in $devices; do
            decho2 "checking dev=$dev..."
            # try to resolve LABEL= and the like
            #
            # NOTE: This looks wonky because finds prints either a resolved
            #       block device name or nothing if not found... but if passed
            #       a /dev/whatever it doesn't look it just prints it back
            #       out... so findfs /dev/blargynotreal will print
            #       /dev/blargynotreal and we have to verify it exists still.
            #
            dev=$(findfs $dev || echo -n)
            [ -n "$dev" ] || continue
            if [ -e $dev ]; then
                found=$dev
                ln -fs $dev /dev/lastwaited
                # break out of both loops, we're done done
                break 2
            fi
        done
        seconds=$(($seconds-1))
        decho2 "waiting for $seconds more seconds"
        sleep 1
    done

    # NOTE: At this point, either a device we were waiting for exists OR our
    #       waitloop timed out.  If we timed out, qe'll give the user a chance
    #       to manually fix things.
    #
    # FIXME: original fwdev wait code didn't treat failure as fatal... this is
    #        probably better, but think it over.
    #
    if [ -n "$found" ]; then
        [ -z "$msg" ] && decho -en ". $found found\n"
        decho2 "$found exists (waited on: $devices)"
    else
        echo
        echo
        echo "--------------------------------------"
        echo "WARNING: Timed out waiting for $devices!"
        echo "--------------------------------------"
        echo
        echo "Create devices (or symlinks) manually and then exit this shell to continue"
        echo "the boot sequence."
        echo
        control_shell
    fi
}


emergency_shell()
{
    echo "Bug in initramfs /init detected. Dropping to a shell. Good luck!"
    echo
    control_shell
}


# FIXME: do I need the setsid cttyhack after outside of linuxrc?  does it hurt
#        anything after the handoff to init?
#
#        I think it *IS* causing problems when emergency_shell gets called from
#        inside system_installer...
#
control_shell()
{
    echo "uptime: $(cat /proc/uptime | cut -d' ' -f1)"
    echo
    setsid cttyhack env LESS=-cMR bash
}


modprobe()
{
    grep -q $1.ko /lib/modules/$(uname -r)/modules.builtin || /sbin/modprobe $*
}


autoload_fs_module()
{
    TYPE=
    # NOTE: Normal blkid can be given LABEL=whatever here and do the right
    #       thing.  The busybox version doesn't like it, though.  But busybox
    #       does provide findfs, which can do the lookup for us.
    eval $(blkid -o export $(findfs $1))
    [ -n "$TYPE" ] && modprobe $TYPE
}


# This method creates udev rules such that we end up with a /dev/$1 symlink
# that points to the device specified by $2, which can be CDLABEL, LABEL, UUID,
# or an actual device name (e.g., /dev/sda1, /dev/md0, /dev/mapper/vg0_lv1).
#
# NOTE: This method modifies the following important global variables:
#
#       thingtomount: argument to be mounted for root filesys
#
generate_udev_rules()
{
    name=$1
    str=$2

    # FIXME: probably want to entirely rewrite these rules for eudev (upstream
    #        220).
    #
    case $str in
        # NOTE: While CDLABEL and LABEL could use the same udev rule, we use
        #       the different str to differentiate later on (e.g., for fsck).
        #
        CDLABEL=*)
            # NOTE: we're assuming SCSI device nodes here, now that SATA, PATA,
            #       USB, and SCSI should all be using them.
            #
            # FIXME: can we just use the cdrom.rule's ID_CDROM=1?  looks like
            #        no...
            #
            CDLABEL=${str#CDLABEL=}
            cat <<EOF >> etc/udev/rules.d/99-ruckusrd.rules
SUBSYSTEM=="block", KERNEL=="sr[0-9]*", ENV{ID_FS_LABEL_ENC}=="$CDLABEL", SYMLINK+="$name"
EOF
            decho2 "Added udev rule for CDLABEL=='$CDLABEL'"
            if [ "$name" = "root" ]; then
                thingtomount=/dev/root
            fi
            ;;
        LABEL=*)
            LABEL=${str#LABEL=}
            cat <<EOF >> etc/udev/rules.d/99-ruckusrd.rules
SUBSYSTEM=="block", KERNEL!="sr[0-9]", ENV{ID_FS_LABEL_ENC}=="$LABEL", SYMLINK+="$name"
EOF
            decho2 "Added udev rule for LABEL=='$LABEL'"
            if [ "$name" = "root" ]; then
                thingtomount=/dev/root
            fi
            ;;
        UUID=*)
            UUID=${str#UUID=}
            cat <<EOF >> etc/udev/rules.d/99-ruckusrd.rules
SUBSYSTEM=="block", ENV{ID_FS_UUID_ENC}=="$UUID", SYMLINK+="$name"
EOF
            decho2 "Added udev rule for UUID=='$UUID'"
            if [ "$name" = "root" ]; then
                thingtomount=/dev/root
            fi
            ;;
        ZFS=*)
            # NOTE: We don't use udev here.  Instead, we've got a block of ZFS
            #       initialization code down below that uses the ZFS and
            #       ZFS_POOL variables, set here.
            #
            ZFS=${str#ZFS=}
            ZFS_POOL=${ZFS%%/*}
            if [ "$name" = "root" ]; then
                thingtomount=$ZFS
                rootfstype=zfs
            elif [ "$name" = "sqsh_layerdev" ]; then
                thingtomount_sqsh=$ZFS
                sqshfstype=zfs
            fi
            ;;
        /dev/*)
            ln -fs $str /dev/$name
            if [ "$name" = "root" ]; then
                thingtomount=$str
            fi
            ;;
        *)
            if [ "$name" = "root" ]; then
                thingtomount=$str
            fi
            ;;
    esac
}


# FIXME: basing this off how generate_udev_rules works has pointed out some
#        inconsistencies that i don't like...
#
#        1. thingtomount and thingtomount_sqsh are named real_rootdev and
#           real_sqsh_layerdev here
#
#        2. rootfstype is the same here, but sqshfstype is sqsh_layerdevfstype
#
#        3. ZFS and ZFS_POOL are overwritten... so both root and sqsh_layerdev
#           have to be in the same zpool.  i don't think i've ever put them in
#           different pools... but it wouldn't work if i did.
#
special_device_lookup()
{
    name=$1
    str=$2

    realdev=
    fstype=
    case $str in
        CDLABEL=*)
            realdev=$(findfs LABEL=${str#CDLABEL=})
            fstype=$(eval $(blkid -o export $realdev); echo $TYPE)
            ;;
        LABEL=*|UUID=*|/dev/*)
            realdev=$(findfs $str)
            fstype=$(eval $(blkid -o export $realdev); echo $TYPE)
            ;;
        ZFS=*)
            ZFS=${str#ZFS=}
            ZFS_POOL=${ZFS%%/*}
            realdev=$ZFS
            # NOTE We don't normally *need* to know fstype, it can be
            #      autodetected at mount-time.  But when mounting zfs datasets
            #      via 'mount' you have to specify -t zfs (if memory serves).
            #
            fstype=zfs
            ;;
    esac

    # assign results to appropriate variables (so if name=root, we want to set
    # realrootdev, etc)
    eval real_${name}=$realdev
    eval ${name}fstype=$fstype
}


lookup_layer()
{
    name=$1.sqsh
    for path in $sqsh_layerdir; do
        if [ -e $path/$name ]; then
            echo $path/$name
            return
        fi
    done

    # just in case it's not found, echo something sane-ish looking so we don't
    # end up with wrong number of arguments later on.
    echo not-found-$name
}


# FIXME: maybe start_udev, start_md, start_lvm, and start_zfs should be
#        installed in /sbin so they can be executed easily by hand once logged
#        in?
#
#        well, lvm is just a single call to vgchange...  similarly, zfs is just
#        zpool import.  and it looks like md is being automatically configured
#        by the kernel.  So really just start_udev is non-trivial.
#
#        starting to think maybe that's silly...  plus, this func has nice
#        verbose/quiet support that would be lost (perhaps?) if we made it a
#        script in /sbin.
#
#        we could fix the verbose/quiet stuff and add start_dhcp, start_sshd as
#        well
#
start_udev()
{
    # prep udev hwdb
    go="/sbin/udevadm"
    [ -n "$verbose" ] && go="$go --debug"
    go="$go hwdb --update"
    decho2 $go
    eval $go

    decho2 "starting udevd"
    /sbin/udevd --daemon --resolve-names=never

    # tell udevd to start processing its queue
    #
    # NOTE: I used to just trigger and settle...  LFS does these 3 triggers and
    #       then conditionally settles.  Not 100% sure of the rationale, but
    #       I'll follow LFS on this one.
    #
    /sbin/udevadm trigger --action=add --type=subsystems
    /sbin/udevadm trigger --action=add --type=devices
    /sbin/udevadm trigger --action=change --type=devices
}


deactivate_unneeded_lvm()
{
    # NOTE: We have to loop over a list of unused logvols to deactivate,
    #       because we can't just do a `vgchange -a n` (that refuses to
    #       deactivate anything unless it can deactivate EVERYTHING).
    for lv in $(lvs --noheadings --options vg_name,lv_name --separator=/ --select lv_device_open!=yes); do
        # NOTE: We already know the lv is unused, so this shouldn't ever fail, but
        #       just in case we'll give the user some indication of what's going on.
        lvchange -a n --quiet --quiet $lv || (
            echo "---------------------------------"
            echo "WARNING: Failed to deactivate unused logvol $lv"
            echo "---------------------------------"
            echo
            echo "Dropping to a shell to investigate."
            echo "When done, exit the shell to continue. Good luck!"
            echo
            control_shell
        )
    done
}


start_ruckusrd_system()
{
    # set hostname to something unique
    #
    # NOTE: The kernel supports hostname= on its command line since 5.19+.  If
    #       hostname has been set already, we leave it alone.
    #
    [ "$(hostname)" == "(none)" ] && hostname ruckusrd-`date +%Y%m%d%H%M%S`

    # clean up some stuff we won't be needing
    #
    # FIXME: should we consider removing more?  We've only got 25% of total RAM
    #        for rootfs, and no easy way to monitor that...  we could remove
    #        /usr/src to free up 115M...  is anyone really going to be trying
    #        to compile kernel modules from in here?
    #
    #        sadly, that might actually be a use case for this shell...  fixing
    #        borked 3rd party but important kernel modules that are non-trivial
    #        to fix (e.g., NVIDIA, ZFS, DRBD)
    #
    rm -rf /kernel
    rmdir /sysroot

    # deactivate unneeded LVM
    deactivate_unneeded_lvm

    # NOTE: Traditionally this would be done after switch_root via an rcS
    #       script, but we've already done all the rest of the stuff that
    #       script would normally handle (e.g., initial device nodes, virtual
    #       filesystem mounts)... and we're really not switching to another
    #       rootfs.  So we do it here.
    #
    start_udev
    sleep 1

    # attempt to mount efivars
    if [ -d /sys/firmware/efi ]; then
        decho "mounting efivars"
        mount efivarfs -t efivarfs /sys/firmware/efi/efivars || echo "WARNING: Failed to mount efivars. Cannot manage UEFI settings."
    else
        decho "system doesn't support EFI, not mounting efivars"
    fi

    # check for existence of serial devices and uncomment getty entries in
    # /etc/inittab accordingly
    [ -c /dev/ttyS0 ] && sed -i 's|^#ttyS0::|ttyS0::|' /etc/inittab
    [ -c /dev/hvc0 ] && sed -i 's|^#hvc0::|hvc0::|' /etc/inittab

    # configure networking
    if [ -n "$initramsys_net" ]; then
        decho "starting networking"
        dev=eth0
        opts=${initramsys_net_conf//,/ }
        for o in $opts; do
            case "$o" in
                DEV=*)
                    dev=${o#DEV=}
                    ;;
                IP=*)
                    ip=${o#IP=}
                    ;;
                VLAN=*)
                    vlan=${o#VLAN=}
                    ;;
                HOSTNAME=*)
                    hostname ${o#HOSTNAME=}
                    ;;
                *)
                    decho "ignoring invalid initramsys_net config option $o"
                    ;;
            esac
        done
        if [ -z "$ip" ] || [ "$ip" = "auto" ]; then
            decho "will use DHCP on $dev as `hostname -s`"
        fi
        ip link set $dev up
        if [ -n "$vlan" ]; then
            vconfig add $dev $vlan
            dev=$dev.$vlan
        fi
        if [ -n "$ip" ] && [ "$ip" != "auto" ]; then
            ip addr add $ip dev $dev
        else
            udhcpc -i $dev -qf -F `hostname -s` >/dev/null 2>&1
        fi
        dropbear -RB
    else
        cat >> /etc/motd <<"EOF"
Welcome!  Might I suggest setting up networking and SSH access?  For example,
to create a VLAN20 interface on eth0 using DHCP and start ssh:

% vconfig add eth0 20
% ip link set eth0 up
% udhcpc -i eth0.20 -qf -F `hostname -s`
% dropbear -RB

EOF
    fi

    # enable the installer
    if [ -n "$initramsys_installer" ]; then
        sed -i 's|^ttyS0::respawn:/sbin/getty|ttyS0::respawn:/sbin/system_installer once /sbin/getty|' /etc/inittab
        sed -i 's|^hvc0::respawn:/sbin/getty|hvc0::respawn:/sbin/system_installer once /sbin/getty|' /etc/inittab
        sed -i 's|^tty1::respawn:/sbin/getty|tty1::respawn:/sbin/system_installer once /sbin/getty|' /etc/inittab
    fi

    # hand off control to /sbin/init
    go="exec /sbin/init"
    decho2 $go
    eval $go
}


parse_boot_params()
{
    # use /proc/cmdline if args not specified
    if [ -n "$*" ]; then
        opts=$*
    else
        opts=$(cat /proc/cmdline)
        opts_from_proc=y
    fi

    for o in $opts ; do
        case $o in 
            init=*)
                init=${o#init=}
                ;;
            quiet)
                quiet=1
                verbose=
                ;;
            verbose)
                verbose=1
                quiet=
                ;;
            to_ram)
                to_ram=1
	        ;;
            shell)
                shell=1
                ;;
            shell_mountdevs)
                shell_mountdevs=1
                ;;
            shell_sqshprep)
                shell_sqshprep=1
                ;;
            shell_mountoverlay)
                shell_mountoverlay=1
                ;;
            maint)
	        maint=1
	        ;;
            firstboot)
                firstboot=1
                ;;
            rw)
                root_rw=1
                ;;
            root_true_rw)
                root_true_rw="rw"
                ;;
            hoststamp)
                hoststamp=1
                ;;
            blacklist=*)
                blacklist=${o#blacklist=}
                echo "blacklist $blacklist" >> /etc/modprobe.d/ruckusrd-blacklist.conf
                ;;
            root=*)
                root=${o#root=}
                ;;
            rootflags=*)
                rootflags=${o#rootflags=}
                ;;
            rootfstype=*)
                rootfstype=${o#rootfstype=}
                ;;
            overlayflags=*)
                overlayflags=${o#overlayflags=}
                ;;
            sqsh_layers=*)
                sqsh_layers=${o#sqsh_layers=}
                # make layers space-delimited for iterating
                sqsh_layers_ws=${sqsh_layers//:/ }
                ;;
            sqsh_layerdev=*)
                sqsh_layerdev=${o#sqsh_layerdev=}
                sqsh_layerdir="$sqsh_layerdir /sqsh_layerdev"
                ;;
            sqsh_layerdir=*)
                sqsh_layerdir_rel=${o#sqsh_layerdir=}
                ;;
            sqshfstype=*)
                sqshfstype=${o#sqshfstype=}
                ;;
            ram_layer=*)
                ram_layer=${o#ram_layer=}
                ;;
            modinject)
                modinject=1
                ;;
            fwdev=*)
                fwdev=${o#fwdev=}
                fwdev_ws=${fwdev//,/ }
                ;;
            initramsys)
                initramsys=1
                ;;
            initramsys-net)
                initramsys=1
                initramsys_net=1
                ;;
            initramsys-net=*)
                initramsys=1
                initramsys_net=1
                initramsys_net_conf=${o#initramsys-net=}
                ;;
            initramsys-installer)
                initramsys=1
                initramsys_installer=1
                ;;
            initramsys-installer=*)
                initramsys=1
                initramsys_installer=1
                initramsys_installer_conf=${o#initramsys-installer=}
                ;;
            modules-early=*)
                modules_early=${o#modules-early=}
                modules_early_ws=${modules_early//,/ }
                ;;
            *)
                # NOTE: putting "loop.max_loop=16" in cmdline would cause "options loop
                #       max_loop=16" to get written in modprobe.conf...
                m=$(echo $o |cut -s -d . -f 1)
                opt=$(echo $o |cut -s -d . -f 2-)
                if [ -z "$m" -o -z "$opt" ]; then
                    continue
                fi
                p=$(echo $opt |cut -s -d = -f 1)
                v=$(echo $opt |cut -s -d = -f 2-)
                if [ -z "$p" -o -z "$v" ]; then
                    continue
                fi
                echo "options $m $p=$v" >> /etc/modprobe.d/ruckusrd-options.conf
                ;;
        esac
    done

    # if user provided sqsh_layerdir, append it to the device mountpoint
    if [ -n "$sqsh_layerdir_rel" ]; then
        tmp=
        for x in $sqsh_layerdir; do
            tmp="$tmp $x/$sqsh_layerdir_rel"
        done
        sqsh_layerdir=$tmp
    fi

    # only pass kernel command line if we're launching /sbin/init
    if [ "$init" == "/sbin/init" ] ; then
        initargs=$opts
    else
        initargs=""
    fi

    # verbose config summary
    decho2 "opts=$opts"
    decho2 "opts_from_proc=$opts_from_proc"
    decho2 "init=$init"
    decho2 "initargs=$initargs"
    decho2 "root=$root"
    decho2 "root_rw=$root_rw"
    decho2 "root_true_rw=$root_true_rw"
    decho2 "rootflags=$rootflags"
    decho2 "rootfstype=$rootfstype"
    decho2 "overlayflags=$overlayflags"
    decho2 "to_ram=$to_ram"
    decho2 "shell=$shell"
    decho2 "shell_mountdevs=$shell_mountdevs"
    decho2 "shell_sqshprep=$shell_sqshprep"
    decho2 "shell_mountoverlay=$shell_mountoverlay"
    decho2 "maint=$maint"
    decho2 "firstboot=$firstboot"
    decho2 "hoststamp=$hoststamp"
    decho2 "sqsh_layers=$sqsh_layers"
    decho2 "sqsh_layerdev=$sqsh_layerdev"
    decho2 "sqsh_layerdir=$sqsh_layerdir"
    decho2 "sqsh_layerdir_rel=$sqsh_layerdir_rel"
    decho2 "sqshfstype=$sqshfstype"
    decho2 "ram_layer=$ram_layer"
    decho2 "modinject=$modinject"
    decho2 "fwdev=$fwdev"
    decho2 "initramsys=$initramsys"
    decho2 "initramsys_net=$initramsys_net"
    decho2 "initramsys_net_conf=$initramsys_net_conf"
    decho2 "initramsys_installer=$initramsys_installer"
    decho2 "initramsys_installer_conf=$initramsys_installer_conf"
    decho2 "modules_early=$modules_early"
}


# efibootmgr calls can be slow, we need to do a bunch of querries in loops, and
# we know when the actual boot config is changed, so we cache the results.
# Update the cache by calling efi_update_cache before accessing this file,
# which will refresh it if it's older than 1 minute.  Likewise, anywhere we
# modify via efibootmgr, redirect the output to the cache file to keep it
# correct.
#
# NOTE: We need to ensure that this includes labal and disk paths.  Make sure
#       to use '-v' on all efibootmgr invocations.
#
efibootcache=/tmp/efiboot.cache


# NOTE: efibootmgr v17 vs v18 output changes annoyingly.  Starting with v18,
#       the default verbosity has changed to the old -v verbosity level, and if
#       you do -v now you get a ton of extra info on multiple lines per boot
#       entry.  (so jammy good, noble bad)
#
#       Our parsing scripts were unaffected by this change, because we check to
#       see if lines start with Boot[0-9a-fA-F]+. but keep this in mind when
#       adding other parsing functions.

efi_update_cache()
{
    if [ ! -f $efibootcache ] || [ -z "$(find $efibootcache -mmin 1) 2>/devnull" ]; then
        efibootmgr -v > $efibootcache
    fi
}


# take efi boot entry label, echo it's associated hex id
efi_get_bootnum()
{
    # can't just use $1, we need to quote the entire arg list, in case the name
    # has spaces in it.
    name="$*"

    # update cache
    efi_update_cache

    # transform that output into a nice table that looks like this:
    #
    # 00001  label1
    # 00004  label2 that could have spaces and special characters
    # 000a0  label3
    #
    # then print the 1st element if the whole line matches
    #
    # NOTE: At some point we started to need to escape out the asterisk in
    #       sub("* "," ").
    #
    #       In ash it works fine w/ or w/out the escape.  Bash in bionic works
    #       either way but prints a warning if you escape it (probably why I
    #       originally didn't).  Starting with jammy, the escape is needed in
    #       bash.  Just in case this gets sourced from actual bash, we'll
    #       escape it.
    #
    cat $efibootcache | sed 's|\t.*||g' | awk '{sub("\* ","  "); if ($1 ~ "^Boot[0-9a-fA-F]+") {sub("Boot",""); print}}' | awk "/^[0-9a-fA-F]+  $name\$/"' {print $1}'
}


# take device name, echo list of associated efi boot numbers
#
# NOTE: It's entirely possible that this returns more than one
#
efi_get_bootnum_by_disk()
{
    disk=$1

    # update cache
    efi_update_cache

    # get list of partitions for the specified device
    partitions=
    [ -e ${disk}1 ] && partitions=${disk}[0-9]*
    [ -e ${disk}p1 ] && partitions=${disk}p[0-9]*

    # iterate over each partition, looking up its UUID and then scanning
    # efibootmgr output for the UUID
    for x in $partitions; do
        eval $(blkid -o export $x)
        [ -n "$PARTUUID" ] || continue
        cat $efibootcache | awk '{sub("\* ","  "); if ($1 ~ "^Boot[0-9a-fA-F]+$") {sub("Boot",""); print}}' | awk "/GPT,$PARTUUID/"' {print $1}'
    done
}


efi_get_bootorder()
{
    # update cache
    efi_update_cache

    cat $efibootcache | awk -F: '/^BootOrder:/ {sub(" ","");print $2}'
}


efi_get_bootcurrent()
{
    # update cache
    efi_update_cache

    cat $efibootcache | awk -F: '/^BootCurrent:/ {sub(" ","");print $2}'
}


efi_set_bootorder_first()
{
    count=1
    stem=$1
    while : ; do
        if [ $count -eq 1 ]; then
            name=$stem
        else
            name=$stem$count
        fi
        bn=$(efi_get_bootnum $name)
        [ -n "$bn" ] || break
        decho2 "EFI bootnum for $name: $bn"
        order=$(efi_get_bootorder)
        decho2 "EFI bootorder: $order"
        efibootmgr -v -o $bn,$order > $efibootcache
        count=$((count+1))
    done

    # now remove duplicates
    efibootmgr -v --remove-dups > $efibootcache
}


sysroot_mount_vfs()
{
    mount proc -t proc /sysroot/proc
    mount sysfs -t sysfs /sysroot/sys
    mount --rbind /dev /sysroot/dev
    mount --make-rslave /sysroot/dev
    mount devpts -t devpts /sysroot/dev/pts
    mount tmpfs -t tmpfs /sysroot/dev/shm
    mount tmpfs -t tmpfs /sysroot/tmp

    # attempt to mount efivars
    if [ -d /sysroot/sys/firmware/efi ]; then
        decho "mounting efivars"
        mount efivarfs -t efivarfs /sysroot/sys/firmware/efi/efivars || echo "WARNING: Failed to mount efivars. Cannot manage UEFI settings."
    else
        decho "system doesn't support EFI, not mounting efivars"
    fi
}


sysroot_umount_vfs()
{
    for x in sysroot/{proc,sys{/firmware/efi/efivars,},dev{/pts,/shm,},tmp}; do
        if (grep -q $x /proc/mounts); then
            umount $x
        fi
    done
}
