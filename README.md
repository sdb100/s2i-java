# s2i-java

This is a generic s2i implementation designed to be used with the OpenShift Container Platform Container Development Kit (CDK). It provides a builder image that can be pushed in to OpenShift's Docker repo and used to build arbitrary Java fatjar applications, such as Spring Boot or vertx web apps. 

### How to use

#### Set up the CDK 

Get the CDK working as per the instructions [here](http://developers.redhat.com/products/cdk/get-started/). Take note of the versioning issues - I had a too-recent version of VirtualBox installed and I couldn't get the CDK VM image to work until I downgraded as instructed.

Fire up the VM and ssh into it as follows:
```
vagrant up
vagrant ssh
```
You might want to check the time and TZ the VM thinks it is, because otherwise you'll get screwy reporting of build times etc:

Set TZ:
```
sudo ln -s /usr/share/zoneinfo/GMT /etc/localtime
```
Set time:
```
sudo date -s "26 NOV 2016 11:20:00"
```
Check it:
```
timedatectl
```
And that's all you should need to do for setup.

#### Create a project
You can do this from the web console at http://10.1.2.2:8443/ or from the command line as follows (the login step will as for credentials, which default to admin/admin I believe). You can call the project anything, but instructions below assume you call it _test-project_:
```
oc login
oc new-project test-project 
```
If you create the project from the web console, don't add anything to it yet.

#### Build and install the s2i image
The CDK doesn't come with any kind of Java builder image, which is a bit odd, but Oracle don't help matters by making it difficult to download the JVM without accepting a licence agreement. They could provide an OpenJDK one, but don't seem to out of the box. I wanted an Oracle Java8 JVM basis for running vertx fatjars so I made my own, based on the work [here](https://github.com/jorgemoralespou/s2i-java). To build it and install in your CDK image, do the following:

```
oc new-app https://github.com/sdb100/s2i-java.git
```

This will create a failing deployment (there's probably some way to stop it doing this but I don't know what it is yet...) but this is a builder image so we don't actually want to deploy it. Therefore remove unwanted oc stuff (deployment config and service) as follows:
```
oc delete dc s2i-java
oc delete svc s2i-java
```

You want the builder image to appear in the list of available images in the UI (from "add to project"), but this requires an alteration to the image stream spec to mark it as a builder image. 
The easiest way to achieve this is to use the UI to browse to image streams, go to the s2i-java image stream and edit the yaml (from "actions" at top right). Add the section in _s2i-java-imagestream.yaml_ to the spec. The image should then appear as a builder image.

#### Build and run something
Use the web console and "add something" to your project. In the image list under "Java" you should see "s2i-java:latest" listed. Click it, choose a name, and point it to a Maven repo. You can use my vertx sample [here](https://github.com/sdb100/vertx-demo).

If your Maven repo builds a fatjar in the _target_ directory (NB it has to be the only jar file in there) this will build, run and deploy a single pod in your project. It will give you a default URL where you can access it from a browser.

This should be all you need, and it should work straight off. An issue I had on OSX was that when I went to the URL in the browser, OpenShift reported that the application wasn't available. I had to halt the VM, restart my laptop and then fire up the VM again before it would work. 



