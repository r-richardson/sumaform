include:
  - default

lftp:
  pkg.installed:
    - require:
      - sls: default

lftp_script:
  file.managed:
    - name: /root/mirror.lftp
    - source: salt://mirror/mirror.lftp

parted:
  pkg.installed

mozilla_certificates:
  pkg.installed:
    - name: ca-certificates-mozilla
    - require:
      - sls: default

scc_data_refresh_script:
  file.managed:
    - name: /root/refresh_scc_data.py
    - source: salt://mirror/refresh_scc_data.py
    - mode: 755

mirror_script:
  file.managed:
    - name: /root/mirror.sh
    - source: salt://mirror/mirror.sh
    - mode: 755
    - template: jinja
  cron.present:
    - name: /root/mirror.sh
    - identifier: MIRROR
    - user: root
    - hour: 20
    - minute: 0
    - require:
      - file: mirror_script
      - file: lftp_script
      - pkg: lftp

mirror_partition:
  cmd.run:
    - name: /usr/sbin/parted -s /dev/{{grains['data_disk_device']}} mklabel gpt && /usr/sbin/parted -s /dev//{{grains['data_disk_device']}} mkpart primary 2048 100% && /sbin/mkfs.ext4 /dev//{{grains['data_disk_device']}}1
    - unless: ls /dev//{{grains['data_disk_device']}}1
    - require:
      - pkg: parted

# http serving of mirrored packages

mirror_directory:
  file.directory:
    - name: /srv/mirror
    - user: wwwrun
    - group: users
    - mode: 755
    - makedirs: True
  mount.mounted:
    - name: /srv/mirror
    - device: /dev//{{grains['data_disk_device']}}1
    - fstype: ext4
    - mkmnt: True
    - persist: True
    - opts:
      - defaults
    - require:
      - cmd: mirror_partition

web_server:
  pkg.installed:
    - name: apache2
    - require:
      - sls: default
  file.managed:
    - name: /etc/apache2/vhosts.d/mirror.conf
    - source: salt://mirror/mirror.conf
    - require:
      - pkg: apache2
  service.running:
    - name: apache2
    - enable: True
    - require:
      - pkg: apache2
      - file: /etc/apache2/vhosts.d/mirror.conf
      - file: mirror_directory
    - watch:
      - file: /etc/apache2/vhosts.d/mirror.conf

# NFS serving of mirrored packages

exports_file:
  file.append:
    - name: /etc/exports
    - text: /srv/mirror *(ro,sync,no_root_squash)
    - require:
      - file: mirror_directory

rpcbind:
  service.running:
    - enable: True

nfs_kernel_support:
  pkg.installed:
    - name: nfs-kernel-server
    - require:
      - sls: default

nfs:
  service.running:
    - enable: True
    - require:
      - service: rpcbind
      - pkg: nfs-kernel-server

nfs_server:
  service.running:
    - name: nfsserver
    - enable: True
    - require:
      - file: exports_file
      - service: nfs
    - watch:
      - file: exports_file

# symlinks to mimic SMT's folder structure, which is used by the from-dir
# setting in SUSE Manager

/srv/mirror/repo/$RCE/SLES11-SP3-Pool/sle-11-x86_64:
  file.symlink:
    - target: ../../../mirror/SuSE/zypp-patches.suse.de/x86_64/update/SLE-SERVER/11-SP3-POOL/
    - makedirs: True
    - force: True

/srv/mirror/repo/$RCE/SLES11-SP3-Updates/sle-11-x86_64:
  file.symlink:
    - target: ../../../mirror/SuSE/build-ncc.suse.de/SUSE/Updates/SLE-SERVER/11-SP3/x86_64/update/
    - makedirs: True
    - force: True

/srv/mirror/repo/$RCE/SLES11-SP4-Pool/sle-11-x86_64:
  file.symlink:
    - target: ../../../mirror/SuSE/zypp-patches.suse.de/x86_64/update/SLE-SERVER/11-SP4-POOL/
    - makedirs: True
    - force: True

/srv/mirror/repo/$RCE/SLES11-SP4-Updates/sle-11-x86_64:
  file.symlink:
    - target: ../../../mirror/SuSE/build-ncc.suse.de/SUSE/Updates/SLE-SERVER/11-SP4/x86_64/update/
    - makedirs: True
    - force: True

/srv/mirror/repo/$RCE/SLE11-SDK-SP4-Pool/sle-11-x86_64:
  file.symlink:
    - target: ../../../mirror/SuSE/zypp-patches.suse.de/x86_64/update/SLE-SDK/11-SP4-POOL/
    - makedirs: True
    - force: True

/srv/mirror/repo/$RCE/SLE11-SDK-SP4-Updates/sle-11-x86_64:
  file.symlink:
    - target: ../../../mirror/SuSE/build-ncc.suse.de/SUSE/Updates/SLE-SDK/11-SP4/x86_64/update/
    - makedirs: True
    - force: True

/srv/mirror/repo/$RCE/SLES11-SP3-SUSE-Manager-Tools/sle-11-x86_64:
  file.symlink:
    - target: ../../../mirror/SuSE/build-ncc.suse.de/SUSE/Updates/SLE-SERVER/11-SP3-CLIENT-TOOLS/x86_64/update/
    - makedirs: True
    - force: True

/srv/mirror/repo/$RCE/SLES11-SP4-SUSE-Manager-Tools/sle-11-x86_64:
  file.symlink:
    - target: ../../../mirror/SuSE/build-ncc.suse.de/SUSE/Updates/SLE-SERVER/11-SP4-CLIENT-TOOLS/x86_64/update/
    - makedirs: True
    - force: True

/srv/mirror/repo/$RCE/SUSE-Manager-Server-2.1-Pool/sle-11-x86_64:
  file.symlink:
    - target: ../../../mirror/SuSE/zypp-patches.suse.de/x86_64/update/SUSE-MANAGER/2.1-POOL/
    - makedirs: True
    - force: True

/srv/mirror/repo/$RCE/SUSE-Manager-Server-2.1-Updates/sle-11-x86_64:
  file.symlink:
    - target: ../../../mirror/SuSE/build-ncc.suse.de/SUSE/Updates/SUSE-MANAGER/2.1/x86_64/update/
    - makedirs: True
    - force: True

/srv/mirror/repo/$RCE/SUSE-Manager-Proxy-2.1-Pool/sle-11-x86_64:
  file.symlink:
    - target: ../../../mirror/SuSE/zypp-patches.suse.de/x86_64/update/SUSE-MANAGER-PROXY/2.1-POOL/
    - makedirs: True
    - force: True

/srv/mirror/repo/$RCE/SUSE-Manager-Proxy-2.1-Updates/sle-11-x86_64:
  file.symlink:
    - target: ../../../mirror/SuSE/build-ncc.suse.de/SUSE/Updates/SUSE-MANAGER-PROXY/2.1/x86_64/update/
    - makedirs: True
    - force: True

/srv/mirror/SUSE:
  file.symlink:
    - target: mirror/SuSE/build.suse.de/SUSE
    - makedirs: True
    - force: True
