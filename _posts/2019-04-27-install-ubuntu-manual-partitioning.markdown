---
layout: post
title:  "Install Ubuntu with manual partitioning for UEFI"
date:   2019-04-27 23:12:00 +0200
categories: jekyll update
---
I installed Ubuntu 19.04 today and I am so happy with my manual partitioning scheme I decided to make a tutorial on it. The scheme works with UEFI boot mode for my notebook. Tutorial requires a USB drive and a disk that both are going to be completely erased.

### I. Create a bootable USB device

First, a bootable USB stick is needed. Download latest DVD .iso file from [ubuntu site][ubuntu-site]. Some software may be used to write image to the stick, but I had other linux distribution already installed on my hardware, so I decided to use dd tool. Let's start with erasing all contents on USB drive, which is /dev/sdx in this example. Be very careful to find the device file which represents appropriate USB stick!

Use lsblk command to list all devices, then plug USB and check again:

{% highlight bash %}
sudo lsblk
{% endhighlight %}

Probably some partitions are present, unmount them if they are mounted:

{% highlight bash %}
sudo umount /dev/sdxy
# for each y number which is mounted
{% endhighlight %}

Clean the USB drive completely. Be very careful to erase the right drive:

{% highlight bash %}
sudo dd status=progress if=/dev/zero of=/dev/sdx bs=512 && sync
{% endhighlight %}

Write file containing ubuntu installation image (ie. isofile.iso) to the drive:

{% highlight bash %}
sudo dd status=progress if=isofile.iso of=/dev/sdx bs=512 && sync
{% endhighlight %}

### II. Disable secure boot in UEFI

At least for the time of installation. Modern notebooks may allow booting to the Ubuntu linux in secure mode.

### III. Create partitining scheme for UEFI

Boot into Ubuntu from the USB drive. Open terminal and locate the drive where Ubuntu is going to be installed. Assume it is /dev/sdz.

All data will be erased! Create a new GPT partition table:

{% highlight bash %}
sudo gdisk /dev/sdz
{% endhighlight %}

Gdisk tool is self-explanatory, remember to use '+' when defining size of partition.

The following partitions need to be created:
- sdz1, size: 550M, type: ef00 (EFI System, very important partition here),
- sdz2, size: 1000M, type: 8300 (Linux filesystem, for /boot mount),
- sdz3, size: amount of your RAM or google it, type: 8200 (Linux swap),
- sdz4, size: the rest of space (default), type 8e00 (Linux LVM).

There are four physical partitions. The last of them will be converted to logical partions. Mark sdz4 as physical volume for LVM:

{% highlight bash %}
sudo pvcreate /dev/sdz4
{% endhighlight %}

Create volume group named 'ubuntu':

{% highlight bash %}
sudo vgcreate ubuntu /dev/sdz4
{% endhighlight %}

When you have volume group, you can create logical volume in it. Create volumes for '/' and '/home' mounts. I would recommend giving at least 20G to '/' (most stuff installed with apt will go there by default, but if your space is 20G total, probably 10G '/' is going to be fine):

{% highlight bash %}
sudo lvcreate -n root -L 50G ubuntu
sudo lvcreate -n home -l 100%FREE ubuntu
{% endhighlight %}

### IV. Make filesystems

It is very important to make vfat filesystem on EFI partition:

{% highlight bash %}
sudo mkfs.vfat /dev/sdz1
{% endhighlight %}

Make ext4 on /dev/sdz2 and on logical volumes:

{% highlight bash %}
sudo mkfs.ext4 /dev/sdz2
sudo mkfs.ext4 /dev/ubuntu/root
sudo mkfs.ext4 /dev/ubuntu/home
{% endhighlight %}

You can make swap, but it is going to be formatted by installer anyway:

{% highlight bash %}
sudo mkswap /dev/sdz3
{% endhighlight %}

### V. Install Ubuntu

Run the installer and choose 'something else' when it comes to partitions. Use:
- sdz1 mounted as '/boot/efi' (efi boot partition),
- sdz2 mounted as '/boot',
- sdz3 mounted as 'swap',
- /dev/mapper/ubuntu-root mounted as '/',
- /dev/mapper/ubuntu-home mounted as '/home'.

### VI. Resolve issues with kworkers

Some notebooks will have problems with firmware interrupts (high cpu usage in idle state). If you can see high cpu usage by kworker process when running top command, you should run the following command:

{% highlight bash %}
grep -r . /sys/firmware/acpi/interrupts/
{% endhighlight %}

There, you need to find gpe numbers which generate unusual number of interrupts (hundreds is a lot, but it may be seen thousands). Those generating only few should be left untouched.

If you decide to block gpe13 and gpe17, add the following lines to root's crontab:

{% highlight bash %}
@reboot echo "disable" > /sys/firmware/acpi/interrupts/gpe13
@reboot echo "disable" > /sys/firmware/acpi/interrupts/gpe17
{% endhighlight %}

Reboot the system and now it should be quiet.

[ubuntu-site]: https://www.ubuntu.com/
