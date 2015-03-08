### Install MongoDB on Ubuntu

```
$ sudo apt-get install mongodb
```

### Install Node.js and npm on Ubuntu

```
$ sudo apt-get install nodejs-legacy npm
```

### Install Bower

```
sudo chown -R $USER /usr/local
```

```
$ npm install -g bower
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

### Install Bower dependencies

```
$ bower install jquery
$ bower install angular
$ bower install angular-resource
$ bower install angular-bootstrap
$ bower install bootstrap
$ bower install checklist-model
```

### Run Deployerb server
```
$ rackup
```
