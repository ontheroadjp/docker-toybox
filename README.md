# docker-toybox

Docker containers management by dynamic proxy.

## Requirements

* docker
* docker-compose

## Getting started

### Installation

* Download the latest release of docker-toybox.

```
$ cd /path/to/download
$ git clone https://github.com/ontheroadjp/docker-toybox.git
```

* Set environment variables in your ``~/.bash_profile``

```bash
$ export TOYBOX_HOME=/path/to/download/docker-toybox
$ export PATH=$TOYBOX_HOME/bin:$PATH
```

* If you set ``TOYBOX_DOMAIN`` optional environment valiable, you can access application with your own domain.

```bash
$ export TOYBOX_DOMAIN=yourdomain.com
```

### Usage

```bash
$ toybox <application> <command>
```

available applications are shown as below

* wordpress
* owncloud

available commands are shown as below

* ``start`` to boot the application.
* ``stop`` to shutdown the application.
* ``status`` to show the application status
* ``clear`` to shutdown the application and remove all of containers related.
* ``backup`` to save containers data.
* ``restore`` to restore containers data.

## Example

* By command as below to boot WordPress and you can access ``http://wordpress.docker-toybox.com``.
* If you set ``TOYBOX_DOMAIN`` environment valiable before, you can access ``http://wordpress.yourdomain.com``

```bash
$ toybox wordpress start
```

* Command to stop WordPress as below.

```bash
$ toybox wordpress stop
```

### Sub domain name

* You can use ``-s`` option to assign sub domain name you like when booting application and you can access ``http://blog.docker-toybox.com``.
* If you set ``TOYBOX_DOMAIN`` environment valiable before, you can access ``http://blog.yourdomain.com``

```bash
$ toybox -s blog wordpress start
```

* Command to stop WordPress that sub domain name is specified.

```bash
$ toybox -s wp wordpress stop
```

* If you don't use ``-s`` option, application name will assign as sub domain name.

## License

* [jwilder/nginx-proxy](echo "<h1>Helo world!</h1>") - 
 MIT