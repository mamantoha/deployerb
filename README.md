### Install MongoDB on Ubuntu

```
$ sudo apt-get install mongodb
```

### Install Node.js and npm on Ubuntu

```
$ sudo apt-get install nodejs-legacy npm
```

### Clone Deployerb from GiHub

```
$ git clone https://github.com/mamantoha/deployerb.git
$ cd deployerb
```

### Install missing dependencies

```
$ bundle install
```

### Install NPM dependencies

```
$ npm install
```

### Using subdomains in development

Network configuration for supporting subdomains in development:

/etc/hosts

```
127.0.0.1 deployerb-dev.com
127.0.0.1 api.deployerb-dev.com
```

On Windows, look for `C:\WINDOWS\system32\drivers\etc\hosts`

The following URLs now available on local machine:

* http://deployerb-dev.com:9292
* http://api.deployerb-dev.com:9292

### Run Deployerb server

```
$ bundle exec rackup
```
