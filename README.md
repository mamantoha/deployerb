## Installation

* Install MongoDB
* Install Ruby
* Install Node.js
* Install Yarn

### Clone Deployerb from GiHub

```
$ git clone https://github.com/mamantoha/deployerb.git
$ cd deployerb
```

### Install Ruby dependencies

```
$ bundle install
```

### Install Yarn dependencies

```
$ yarn install
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

### Run Deployerb development server

```
$ bundle exec rackup
```

```
$ webpack -w
```
