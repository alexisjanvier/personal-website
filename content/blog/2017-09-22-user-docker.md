+++
title="Associer un utilisateur à celui d'un container Docker"
slug="bind-user-on-docker-container"
date = 2017-09-22
description="L'un des problèmes très classiques lorsque l'on utilise Docker, c'est que l'utilisateur d'un container est root par défaut. Du coup, on peut rencontrer des problèmes de droits sur les répertoires générés au sein de ce container."
draft = false
in_search_index = true
[taxonomies]
categories = ["informatique"]
tags = ["devops"]
[extra]
+++

L'un des problèmes très classiques lorsque l'on utilise Docker, c'est que l'utilisateur d'un container est `root` par défaut. Du coup, on peut rencontrer des problèmes de droits sur les répertoires générés au sein de ce container.

Par exemple, imaginons que nous utilisions un container pour faire le build d'une application *create-react -app*: le répertoire `build` généré aura les droits de root au niveau du host. Si ce n'est pas dramatique, c'est parfois problématique, particulièrement si l'on veut automatiser une tâche sur ce répertoire au niveau du host (par exemple via une recette make).

```makefile
// in makefile
docker-build:
    NODE_ENV=production docker-compose run --no-deps --rm client npm run build
    NODE_ENV=production docker-compose run --no-deps --rm server npm run build
    mkdir -p server/build/public
    cp -rf client/build/* server/build/public/
```

Dans cette exemple, la commande `mkdir -p server/build/public` va échouer, car l'utilisteur du `host` ne va pas avoir les droits d'écriture au sein de `server/build/public`.

On veut donc faire en sorte que l'utilisateur du container soit le même (c'est à dire ayant le même UID) que l'utilisateur du `host`.

## Première méthode

On peut transmettre l'`uid/gid` d'un `user` lorsque l'on démarre un container:

```yaml
// in docker-compose.yml
version: '2'

services:
    node:
        image: node:8.5-alpine
        volumes:
            - .:/app
        ports:
            - 3000:3000
        working_dir: "/app"
        command: "npm start"
        user: "${UID}:${GID}"
```

```makefile
// in makefile
export UID = $(USER_ID)
export GID = $(GROUP_ID)

docker-build:
	docker-compose run --no-deps --rm node npm run build
```

Cela marche, mais ce n'est ni une méthode officielle ni une méthode très sécurisée.

## La bonne méthode

On peut configurer au niveau de Docker le mapping des utilisateurs de container grâce à *[l'espace de nom utilisateur](https://docs.docker.com/engine/security/userns-remap/)* et le flag `userns-remap`.

On va ainsi pouvoir indiquer à Docker un utilisateur qui sera mapper par défaut sur l'utilisateur des containers. Il faut que cet utilisateur soit un utilisateur déclaré sur le système hôte.

Pour un Docker lancé en `daemon`, il faut créer le fichier `/etc/docker/daemon.json` et déclarer l'utilisateur à mapper grâce au flag `userns-remap`

```yaml
//in /etc/docker/daemon.json
{
  "userns-remap": "VALIDE_USER"
}

```

Ensuite, il faut indiquer à Docker sur quels UID/GUID devront être attribués à cet utilisateur (par default 100000:10000, ce qui ne nous sera pas très utile).

```bash
❯ id -u VALIDE_USER
1000
❯ getent group VALIDE_USER
VALIDE_USER:x:1000:
```

```
// in /etc/subuid
VALIDE_USER:1000:1
```

```
// in /etc/subgid
VALIDE_USER:1000:1
```

Attention, l'utilisateur mappé doit aussi être `owner` des répertoires de stockage dans `/var/lib/docker/`.

Ne reste plus qu'à redemarrer le service docker :
```bash
sudo service docker restart
```
