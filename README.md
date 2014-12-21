spookyops
=========

deployment files for spark, spookystuff and ISpooky.

###Install Dependencies

#### 1-Line installation

The easiest way to install on a Ubuntu cluster is to use the provided Ansible script. It will install and configure the recommended stack of third-party dependencies on a remote cluster with minimal effort.

###### Setup a cluster and assure mutual connectivity

namely, they all need a public IP/DNS accessible from each other and from your local computer.
You also need to setup password-less SSH login on all cluster nodes (click me if don't know how to do this), a private key is required for this and for step 4.

###### download/git-clone this project into your local computer.

###### Create and edit inventory configuration files from their templates

they are provided in ```ansible/inventories.template```:

```bash
cd ansible
cp -R inventories.template <inventory-name>
vi <inventory-name>/spark-master
...fill Spark master's public IP/DNS...
vi <inventory-name>/spark-worker
...fill Spark workers' public IP/DNS...
```

You can specify multiple workers or create a disk image from any worker's VM and boot from it to scale on cloud.

###### run ansible-playbook on main deployment scripts respectively, this will remotely start the installation process on your nodes:

```bash
cd ansible
ansible-playbook deploy-master.yml -i ./<inventory-name> --private-key=<path-to-ssh-private-key>
ansible-playbook deploy-worker.yml -i ./<inventory-name> --private-key=<path-to-ssh-private-key>
```

After the installation is finished, you will see output like:

```
PLAY RECAP ******************************************************************** 
<target-node-public-ip/dns> : ok=20   changed=15   unreachable=0    failed=0
```

Reboot each node after its installation process is finished. Master should be rebooted prior to workers. Go to:

```
http://<Spark master's public IP/DNS>:8080/
```

If you see the following Spark-master UI indicating at least 1 worker, your installation is successful:

![Spark-master UI](http://i.imgur.com/T47cgf2.png)

Remember your Spark-master URL as you will use it to deploy all Spark applications.

######WARNING

The provided Ansible script is only tested on Ubuntu, support for other platforms will be added upon request.

Ansible can't be used to deploy locally (to the machine itself running the script). This feature is deliberately omitted to avoid catastrophic changes to your personal computer.

> The main deployment scripts do many things upon one tap, namely:

- [x] upgrade all packages to latest version
- [x] install utility packages on all machines
  - Oracle-Java 7 (can be substitute by (but not coexist with) openjdk 1.7, required by all Java applications including Apache Spark)
  - curl (required for downloading packages that are not distributed through Ubuntu central repository)
  - python-pip (required for installing python packages, namely IPython and IPython-notebook)
  - libzmq3 (required by IPython)
  - python-zmq (required by IPython)
  - tor (required for TOR proxy feature)
  - git (recommended if you want to build SpookyStuff and ISpooky from source code)
  - maven (same as git)
- [x] install Spark 1.1.1 (with Hadoop 2.4 support) to /opt/spark on all machines
- [x] add startup script to /etc/init/ to launch Spark master after rebooting master node (optional: can be done manually by executing start-master.sh)
- [x] add startup script to launch Spark worker to join the cluster after rebooting worker nodes (optional: can be done manually by executing start-worker.sh)
- [x] install PhantomJS 1.9.8 to /usr/lib/phantomjs/bin on all machines (required for parsing dynamic/AJAX pages)
- [x] install IPython and IPython-notebook package on master node from Python package index
- [x] export required environment variables on login shell startup by adding them into .profile (WARNING: this will overwrite settings in old .profile, please add them manually if not desirable)
  ```bash
  export JAVA_HOME="/usr/lib/jvm/java-7-oracle"
  export SPARK_HOME="{{spark_home}}"
  export PHANTOMJS_PATH="/usr/lib/phantomjs/bin/phantomjs"
  ```

#### Manual Installation

Dependencies can be installed manually on all machines by using your favorite package manager, installer and web clients. This gives you more flexibility but is more repetitive and tedious, particularly for large cluster.
Only recommended if:

1. Your cluster has OS other than Ubuntu.
2. Your cluster has packages and applications known to be in conflict with some dependencies. (We are trying to avoid this as much as possible, please submit an issue so we can cover your case) 
3. You prefer to install different packages with identical functionality (e.g. Java 8, OpenJDK, Anaconda)

The following commands and settings are compatible with Ubuntu, please use their counterparts for installation on other OS.

###### Upgrade and install utility packages on all machines

```bash
sudo apt-add-repository ppa:webupd8team/java'
sudo apt-get update
sudo apt-get upgrade
sudo apt-get install curl libzmq3 tor git maven
sudo apt-get install oracle-java7-installer #(interchangeable with: openjdk7, openjdk8, oracle-java8-installer)
sudo apt-get install python-pip python-zmq #(interchangeable with: anaconda)
```

###### Download Apache Spark o all machines

You can download `spark` from https://spark.apache.org/downloads.html and extract the file
```bash
wget http://d3kbcqa49mib13.cloudfront.net/spark-1.1.1-bin-hadoop1.tgz
tar -xf spark-1.1.1-bin-hadoop1.tgz
```
and add path to `.bash_profile` as follow `export SPARK_HOME=/home/ubuntu/spark-1.1.1-bin-hadoop1`

`This step can be omitted for single-node mode`: simply use 'local[*]' in place of Spark-master URL.

###### Download PhantomJS on all machines

Here is a link to download `phantomjs`: http://phantomjs.org/download.html,
first, extract the main executable file:
```bash
wget https://bitbucket.org/ariya/phantomjs/downloads/phantomjs-1.9.8-linux-x86_64.tar.bz2
tar -xf phantomjs-1.9.8-linux-x86_64.tar.bz2
```
then `bin/phantomjs` is ready to use and we will copy it to `/usr/lib`
```bash
sudo cp phantomjs-1.9.8-linux-x86_64/bin/phantomjs /usr/lib/
```
after that, adding a new path to `.profile` as `export PATH=${PATH}:/usr/lib`

###### Install IPython on master node

```bash
sudo pip install ipython[notebook] #(interchangeable with: conda update ipython)
```

Please submit an issue or contact a committer for any error you've encountered.

###Install SpookyStuff on master node

SpookyStuff JAR can be downloaded directly or built from source code:

a. to download pre-built JAR directly:
```curl -w...```

b. to build from source code:
```bash
git clone https://github.com/tribbloid/spookystuff
cd spookystuff
MAVEN_OPTS="-Xmx2g -XX:MaxPermSize=512M -XX:ReservedCodeCacheSize=512m" mvn install -DskipTests=true
```
This will generate 2 uber JARs under `spookystuff/shell/target/scala-2.10` and `spookystuff/example/target/scala-2.10` respectively.
  
  - if Maven ran out of heap space (this rarely happens before), consider increasing maximum allocated heap space to 3G:
  
  ```MAVEN_OPTS="-Xmx3g -XX:MaxPermSize=512M -XX:ReservedCodeCacheSize=512m" mvn install -DskipTests=true```

That's it! Now you have 4 options:
  - install ISpooky and write queries in browser `(See next section)`
  - launch spooky-shell and write queries in command line:
  ```bash
  ./bin/spooky-shell.sh
  ```
  - run examples:
  ```bash
  bin/submit-example.sh <class-name-of-example>
  ```
  - write your own application by including spookystuff-core in your maven/sbt dependencies.
    
###Install ISpooky on master node

(main project page: https://github.com/tribbloid/ISpooky)

ISpooky is an interactive query/visualization UI on top of SpookyStuff & IPython, it allows you to improvise queries and other Spark programs in your browser:

![ISpooky-notebook UI](http://i.imgur.com/gSQw6Ab.png)

ISpooky JAR can be downloaded directly or compiled from source code:

a. to download pre-built JAR directly:
```bash
curl -w...
```

b. to build from source code:
```bash
git clone https://github.com/tribbloid/spookystuff
git clone https://github.com/tribbloid/ISpark
git clone https://github.com/tribbloid/ISpooky
cd ISpark
MAVEN_OPTS="-Xmx2g -XX:MaxPermSize=512M -XX:ReservedCodeCacheSize=512m" mvn install
cd ../ISpooky
MAVEN_OPTS="-Xmx2g -XX:MaxPermSize=512M -XX:ReservedCodeCacheSize=512m" mvn install
```
This will generate an uber JAR under `ISPooky/shell/target/scala-2.10` which will serve as the backend server. A new IPython profile has to be created to enable it to be linked to IPython UI:

###### create a IPython profile

```bash
ipython profile create spooky
```

###### edit `~/.ipython/ipython_config.py`

```python
import os

os.environ['AWS_ACCESS_KEY_ID'] = '<your-aws-access-key>'
os.environ['AWS_SECRET_ACCESS_KEY'] = '<your-aws-private-key>'

SPARK_HOME = os.environ['SPARK_HOME']
MASTER = '<your-Spark-master-URL>'

c.KernelManager.kernel_cmd = [SPARK_HOME+"/bin/spark-submit",
 "--master", MASTER,
 "--class", "org.tribbloid.ispooky.SpookyMain",
 "--conf", "<other-Spark-property>", #see [https://spark.apache.org/docs/latest/configuration.html] for details
 "--conf", "<even-more-Spark-properties>",
 ...
 "--executor-memory", "<memory-allocated-to-ISpooky-on-each-worker>", #
 "--jars", "<path-to-SpookyStuff-uber-JAR>",
 "<path-to-ISpooky-uber-JAR>",
 "--profile", "{connection_file}",
 "--parent"]

c.NotebookApp.ip = '*'
c.NotebookApp.open_browser = False
#c.NotebookApp.password = u'sha1:5dbbfd03bc9a:7f18976f14c5022a67be766f408e07024eecd818'
c.NotebookApp.port = 8888
```

###### launch IPython UI that coordinates with ISpooky Server

```bash
ipython notebook --profile spooky
```

Then go to:

```
http://<Spark master's public IP/DNS>:8888/
```

And create a new notebook. If you can run examples without error in command line or browser, your installation is successful:

![ISpooky dir](http://i.imgur.com/BNGh1j8.png)

###Where to start from here?

...to be continue