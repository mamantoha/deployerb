# Deployerb

## Installation

* Install MongoDB
* Install Ruby
* Install Node.js

### Clone Deployerb from GiHub

```console
git clone https://github.com/mamantoha/deployerb.git
cd deployerb
```

### Install Ruby dependencies

```console
cd ./backend
bundle install
```

### Install Yarn dependencies

```console
cd ./frontend
npm install
```

### Development

```console
cd ./backend
bundle exec rackup
```

```console
cd ./frontend
npm run dev
```

## Production

### Build the Vue 3 Frontend

```
cd ./frontend
npm install
npm run build
mv dist/* ../backend/public
```

## Configure Nginx

`/etc/nginx/sites-available/default`

```
server {
    listen 80;
    server_name localhost;

    root /path/to/deployerb/backend/public;
    index index.html;

    location / {
        try_files $uri /index.html;
    }

    location /api/ {
        proxy_pass http://127.0.0.1:9292/;
        rewrite ^/api/(.*)$ /$1 break;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    }
}
```

This setup serves:

- Frontend (Vue 3) → `/` (served as static files)
- Backend (Sinatra API) → `/api/` (proxied to Puma)

### Start the Sinatra Backend

```
cd ./backend
bundle install
RAILS_ENV=production bundle exec puma -C config/puma.rb
```
