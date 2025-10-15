<h1 align="center">ReactOS<br />
<div align="center">
<a href="https://github.com/erkinalp/reactose"><img src="https://upload.wikimedia.org/wikipedia/commons/thumb/b/b7/ReactOS_logo.svg/512px-ReactOS_logo.svg.png" title="Logo" style="max-width:100%;" width="128" /></a>
</div>
<div align="center">

[![Build]][build_url]
[![Version]][tag_url]
[![Size]][tag_url]
[![Package]][pkg_url]
[![Pulls]][hub_url]

</div></h1>

ReactOS inside a Docker container.

## Features ✨

 - ISO downloader
 - KVM acceleration
 - Web-based viewer

## Video 📺

[![Youtube](https://img.youtube.com/vi/xhGYobuG508/0.jpg)](https://www.youtube.com/watch?v=xhGYobuG508)

## Usage 🐳

##### Via Docker Compose:

```yaml
services:
  reactos:
    image: erkinalp/reactose
    container_name: reactos
    environment:
      VERSION: "0.4.15"
    devices:
      - /dev/kvm
      - /dev/net/tun
    cap_add:
      - NET_ADMIN
    ports:
      - 8006:8006
      - 3389:3389/tcp
      - 3389:3389/udp
    volumes:
      - ./reactos:/storage
    restart: always
    stop_grace_period: 2m
```

##### Via Docker CLI:

```bash
docker run -it --rm --name reactos -p 8006:8006 --device=/dev/kvm --device=/dev/net/tun --cap-add NET_ADMIN -v "${PWD:-.}/reactos:/storage" --stop-timeout 120 erkinalp/reactose
```

##### Via Kubernetes:

```shell
kubectl apply -f https://raw.githubusercontent.com/erkinalp/reactose/refs/heads/master/kubernetes.yml
```

##### Via Github Codespaces:

[![Open in GitHub Codespaces](https://github.com/codespaces/badge.svg)](https://codespaces.new/erkinalp/reactose)

## FAQ 💬

### How do I use it?

  Very simple! These are the steps:
  
  - Start the container and connect to [port 8006](http://127.0.0.1:8006/) using your web browser.

  - Sit back and relax while the magic happens, the whole installation will be performed fully automatic.

  - Once you see the desktop, your ReactOS installation is ready for use.
  
  Enjoy your brand new machine, and don't forget to star this repo!

### How do I select the ReactOS version?

  By default, ReactOS 0.4.15 will be installed. You can add the `VERSION` environment variable to your compose file to specify a version:

  ```yaml
  environment:
    VERSION: "0.4.15"
  ```

  Select from the values below:
  
  | **Value** | **Version**        | **Size** | **Type** |
  |---|---|---|---|
  | `0.4.15`  | ReactOS 0.4.15     | ~150 MB  | Boot CD  |
  | `0.4.14`  | ReactOS 0.4.14     | ~140 MB  | Boot CD  |
  | `0.4.13`  | ReactOS 0.4.13     | ~130 MB  | Boot CD  |
  | `live`    | ReactOS 0.4.15 Live| ~150 MB  | Live CD  |
  | `nightly` | ReactOS Nightly    | ~70 MB   | Boot CD  |
  | `nightly-live` | ReactOS Nightly Live | ~75 MB | Live CD |

> [!NOTE]
> The nightly builds are automatically fetched from the latest available build on the ReactOS build server. These builds are updated frequently and may contain experimental features or bugs. Use stable releases for production use.

### How do I change the storage location?

  To change the storage location, include the following bind mount in your compose file:

  ```yaml
  volumes:
    - ./reactos:/storage
  ```

  Replace the example path `./reactos` with the desired storage folder or named volume.

### How do I change the size of the disk?

  To expand the default size of 64 GB, add the `DISK_SIZE` setting to your compose file and set it to your preferred capacity:

  ```yaml
  environment:
    DISK_SIZE: "256G"
  ```
  
> [!TIP]
> This can also be used to resize the existing disk to a larger capacity without any data loss. However you will need to [manually extend the disk partition](https://learn.microsoft.com/en-us/windows-server/storage/disk-management/extend-a-basic-volume?tabs=disk-management) since the added disk space will appear as unallocated.

### How do I share files with the host?

  After installation there will be a folder called `Shared` on your desktop, which can be used to exchange files with the host machine.
  
  To select a folder on the host for this purpose, include the following bind mount in your compose file:

  ```yaml
  volumes:
    -  ./example:/shared
  ```

  Replace the example path `./example` with your desired shared folder, which then will become visible as `Shared`.

### How do I change the amount of CPU or RAM?

  By default, ReactOS will be allowed to use 2 CPU cores and 4 GB of RAM.

  If you want to adjust this, you can specify the desired amount using the following environment variables:

  ```yaml
  environment:
    RAM_SIZE: "2G"
    CPU_CORES: "2"
  ```

### How do I configure the username and password?

  By default, a user called `Docker` is created and its password is `admin`.

  If you want to use different credentials during installation, you can configure them in your compose file:

  ```yaml
  environment:
    USERNAME: "reactos"
    PASSWORD: "password"
  ```

### How do I install a custom image?

  You can skip the download and use a local ReactOS ISO file by binding it in your compose file:
  
  ```yaml
  volumes:
    - ./reactos.iso:/boot.iso
  ```

  Replace the example path `./reactos.iso` with the filename of your desired ISO file. The value of `VERSION` will be ignored in this case.

### How do I perform a manual installation?

  It's recommended to stick to the automatic installation, as it adjusts various settings to prevent common issues when running ReactOS inside a virtual environment.

  However, if you insist on performing the installation manually at your own risk, add the following environment variable to your compose file:

  ```yaml
  environment:
    MANUAL: "Y"
  ```

### How do I connect using RDP?

  The web-viewer is mainly meant to be used during installation. For a better experience you can connect using any RDP client to the IP of the container.

  There is a RDP client for [Android](https://play.google.com/store/apps/details?id=com.microsoft.rdc.androidx) available from the Play Store and one for [iOS](https://apps.apple.com/nl/app/microsoft-remote-desktop/id714464092?l=en-GB) in the Apple Store. For Linux you can use [FreeRDP](https://www.freerdp.com/) and on Windows just type `mstsc` in the search box.

### How do I assign an individual IP address to the container?

  By default, the container uses bridge networking, which shares the IP address with the host. 

  If you want to assign an individual IP address to the container, you can create a macvlan network as follows:

  ```bash
  docker network create -d macvlan \
      --subnet=192.168.0.0/24 \
      --gateway=192.168.0.1 \
      --ip-range=192.168.0.100/28 \
      -o parent=eth0 vlan
  ```
  
  Be sure to modify these values to match your local subnet. 

  Once you have created the network, change your compose file to look as follows:

  ```yaml
  services:
    windows:
      container_name: windows
      ..<snip>..
      networks:
        vlan:
          ipv4_address: 192.168.0.100

  networks:
    vlan:
      external: true
  ```
 
  An added benefit of this approach is that you won't have to perform any port mapping anymore, since all ports will be exposed by default.

> [!IMPORTANT]  
> This IP address won't be accessible from the Docker host due to the design of macvlan, which doesn't permit communication between the two. If this is a concern, you need to create a [second macvlan](https://blog.oddbit.com/post/2018-03-12-using-docker-macvlan-networks/#host-access) as a workaround.

### How can Windows acquire an IP address from my router?

  After configuring the container for [macvlan](#how-do-i-assign-an-individual-ip-address-to-the-container), it is possible for Windows to become part of your home network by requesting an IP from your router, just like a real PC.

  To enable this mode, in which the container and Windows will have separate IP addresses, add the following lines to your compose file:

  ```yaml
  environment:
    DHCP: "Y"
  devices:
    - /dev/vhost-net
  device_cgroup_rules:
    - 'c *:* rwm'
  ```

### How do I add multiple disks?

  To create additional disks, modify your compose file like this:
  
  ```yaml
  environment:
    DISK2_SIZE: "32G"
    DISK3_SIZE: "64G"
  volumes:
    - ./example2:/storage2
    - ./example3:/storage3
  ```

### How do I pass-through a disk?

  It is possible to pass-through disk devices or partitions directly by adding them to your compose file in this way:

  ```yaml
  devices:
    - /dev/sdb:/disk1
    - /dev/sdc1:/disk2
  ```

  Use `/disk1` if you want it to become your main drive (which will be formatted during installation), and use `/disk2` and higher to add them as secondary drives (which will stay untouched).

### How do I pass-through a USB device?

  To pass-through a USB device, first lookup its vendor and product id via the `lsusb` command, then add them to your compose file like this:

  ```yaml
  environment:
    ARGUMENTS: "-device usb-host,vendorid=0x1234,productid=0x1234"
  devices:
    - /dev/bus/usb
  ```

  If the device is a USB disk drive, please wait until after the installation is fully completed before connecting it. Otherwise the installation may fail, as the order of the disks can get rearranged.

### How do I verify if my system supports KVM?

  First check if your software is compatible using this chart:

  | **Product**  | **Linux** | **Win11** | **Win10** | **macOS** |
  |---|---|---|---|---|
  | Docker CLI        | ✅   | ✅       | ❌        | ❌ |
  | Docker Desktop    | ❌   | ✅       | ❌        | ❌ | 
  | Podman CLI        | ✅   | ✅       | ❌        | ❌ | 
  | Podman Desktop    | ✅   | ✅       | ❌        | ❌ | 

  After that you can run the following commands in Linux to check your system:

  ```bash
  sudo apt install cpu-checker
  sudo kvm-ok
  ```

  If you receive an error from `kvm-ok` indicating that KVM cannot be used, please check whether:

  - the virtualization extensions (`Intel VT-x` or `AMD SVM`) are enabled in your BIOS.

  - you enabled "nested virtualization" if you are running the container inside a virtual machine.

  - you are not using a cloud provider, as most of them do not allow nested virtualization for their VPS's.

  If you did not receive any error from `kvm-ok` but the container still complains about a missing KVM device, it could help to add `privileged: true` to your compose file (or `sudo` to your `docker` command) to rule out any permission issue.

### How do I run macOS in a container?

  You can use [dockur/macos](https://github.com/dockur/macos) for that. It shares many of the same features, except for the automatic installation.

### How do I run Windows in a container?

  You can use [dockur/windows](https://github.com/dockur/windows) for that. This project is based on that work.

### How do I run a Linux desktop in a container?

  You can use [qemus/qemu](https://github.com/qemus/qemu) in that case.

### Is this project legal?

  Yes, this project contains only open-source code and does not distribute any copyrighted material. ReactOS is an open-source operating system licensed under GNU GPL 2.0. This project simply provides a convenient Docker container to run ReactOS.

## Disclaimer ⚖️

*ReactOS is a registered trademark of the ReactOS Foundation. This project is not officially affiliated with, sponsored, or endorsed by the ReactOS Foundation. This is an independent community project based on the dockur/windows project.*

[build_url]: https://github.com/erkinalp/reactose/
[hub_url]: https://hub.docker.com/r/erkinalp/reactose/
[tag_url]: https://hub.docker.com/r/erkinalp/reactose/tags
[pkg_url]: https://github.com/erkinalp/reactose/pkgs/container/reactose

[Build]: https://github.com/erkinalp/reactose/actions/workflows/build.yml/badge.svg
[Size]: https://img.shields.io/docker/image-size/erkinalp/reactose/latest?color=066da5&label=size
[Pulls]: https://img.shields.io/docker/pulls/erkinalp/reactose.svg?style=flat&label=pulls&logo=docker
[Version]: https://img.shields.io/docker/v/erkinalp/reactose/latest?arch=amd64&sort=semver&color=066da5
[Package]: https://img.shields.io/badge/dynamic/json?url=https%3A%2F%2Fipitio.github.io%2Fbackage%2Ferkinalp%2Freactose%2Freactose.json&query=%24.downloads&logo=github&style=flat&color=066da5&label=pulls
