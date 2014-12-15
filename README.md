spookyops
=========

deployment files for spark and spookystuff

###Automated Installation

Ansible is the easiest installation method. It will install and configure the recommended stack of third-party dependencies on any number of remote machines with minimal effort.
 
First, download/git-clone this project, create and configure the following files from their templates in ansible/inventories.template dir:

```
ansible/<name-of-inventory>/spark-master
ansible/<name-of-inventory>/spark-worker
```

public IP/DNS of Spark master and workers are the only things you need to define. You can specify multiple workers or create a disk image from any worker's VM and replicate it to scale on cloud.

Second, invoke ansible-playbook on the main deployment scripts against your master and workers:

```
cd ansible
ansible-playbook deploy-master.yml -i ./<name-of-inventory> --private-key=<path-to-ssh-private-key>
ansible-playbook deploy-worker.yml -i ./<name-of-inventory> --private-key=<path-to-ssh-private-key>
```

Reboot each remote machine after its installation process is finished. Master should be rebooted prior to workers.

The main deployment scripts do many things upon one tap, namely:

1. install the following packages on all machines
  - oracle-java 7
  - curl
  - python-pip
  - libzmq3
  - python-zmq
  - tor
  - git
  - maven
2. install Spark 1.1.1 (with Hadoop 2.4 support) to /opt/spark on all machines
3. add startup script to /etc/init/ to launch Spark master on master node
4. add startup script to launch Spark worker on worker nodes
5. install PhantomJS 1.9.8 to /usr/lib/phantomjs/bin on all machines
6. specify the following environment variables on login shell startup by adding them into .profile
  - export JAVA_HOME="/usr/lib/jvm/java-7-oracle"
  - export SPARK_HOME="{{spark_home}}"
  - export PHANTOMJS_PATH="/usr/lib/phantomjs/bin/phantomjs"

####WARNING

It is only tested on Ubuntu, support for other platforms will be added upon request.

Ansible can't be used to deploy locally (against the machine running the deployment script). This feature is deliberately omitted to discourage changing environment of terminals.