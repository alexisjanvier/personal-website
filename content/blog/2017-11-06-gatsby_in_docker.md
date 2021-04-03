+++
title="Développer un site Gasby.js avec Docker"
slug="gasby-avec-docker"
date = 2017-11-06
description="En ce moment, j'utilise Gasby pour plusieurs sites (ce blog compris). Mais tous les contributeurs de ces sites ne veulent pas forcément installer Node sur leur machine. La solution évidente : Docker."
draft = false
in_search_index = true
[taxonomies]
categories = ["informatique"]
tags = ["javascript", "devops"]
[extra]
+++

Gatsby est un système de génération de site statique basé sur Node. En mode développement, il s'appuie sur le `webpack dev server` afin de se mettre à jours automatiquement.

Nous avons donc besoin d'une image docker permettant de lancer une commande node :

```yaml
// in docker-compose.yml
version: '3'
services:
  gatsby:
    image: node:8-alpine
    volumes:
      - .:/app
    working_dir: /app
    ports:
      - 8000:8000
    command: npm run develop
```

On va ensuite faciliter la vie des contributeurs avec un makefile

```make
// in makefile
.PHONY: build help

help:
	@grep -E '^[a-zA-Z0-9_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'

install: ## install dependencies with docker
	@docker-compose run --rm gatsby npm install

start: ## run gatsby in develop mode with docker
	@docker-compose up -d

stop: ## stop gatsby in docker
	@docker-compose down

logs: ## Display logs from docker
	@docker-compose logs

build: ## build site with docker
	@docker-compose run --rm gatsby npm run build
```

Ne reste donc plus qu'à lancer un `make start`. Mais là :

![Site inaccessible](/images/siteInaccessible.png)

En effet, le `webpack dev server` gère très mal le localhost au sein du docker. Il faut donc modifier un peu la commande `develop` dans le `package.json` en ajoutant `--host 0.0.0.0` pour que webpack accepte toutes les requêtes:

```json
    "scripts": {
        "develop": "gatsby develop --host 0.0.0.0",
        "build": "gatsby build",
        "serve": "gatsby serve",
    },
```

Et voilà.
