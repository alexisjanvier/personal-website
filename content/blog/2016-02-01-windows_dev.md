+++
title="Est-ce du snobisme que de vouloir une vraie console sous Windows ?"
slug="une_console_sous_windows"
date = 2016-02-01
description="Il arrive parfois que l’on doive coder sous Windows : que ce soit par challenge, parce que l’on a perdu un pari ou parce qu’on n’a pas le choix. Et cela peut être un peu douloureux lorsque l’on est habitué à sa console Mac ou Linux."
draft = false
in_search_index = true
[taxonomies]
categories = ["informatique"]
tags = ["console"]
[extra]
+++

Dans mon cas, c’est parce que l’environnement de travail du client ne pouvait être autre chose qu’un Windows 7 sur un VM (avec des droits d’administrateur tout de même), le tout derrière un firewall peu conciliant. La mission prévoyait un back en PHP 5.6 avec du Silex, et un peu de JavaScript sur la partie front.

# Pourquoi a-t-il fallu trouver une autre solution que les installateurs Windows

En tout premier lieu, j'ai installé Atom, par habitude, même si je ne l'ai pas encore utilisé pour du développement PHP.
Hormis un petit souci initial (pour installer Atom, j’ai eu besoin d'une version 4.5 de .net et de l'espace disque allant avec), l’installation officielle se passe bien.
Dans le cas ou l'on est derrière un Firewall, il faut juste penser à éditer ou à ajouter le fichier `.atom/.apmrc` si l'on veut installer quelques plug-ins (atom-beautify, linter, linter-php,…).

```
# $HOME/.atom/.apmrc

http-proxy = "http://LOGIN:PASSWORD@PROXY_URL:PROXY_PORT"
https-proxy = "http://LOGIN:PASSWORD@PROXY_URL:PROXY_PORT"
proxy = "http://LOGIN:PASSWORD@PROXY_URL:PROXY_PORT"
```

Je suis ensuite passé à l’environnement PHP. Ma vm était livrée avec un Xampp d’origine. Après avoir ajouté la Path, j’ai bien accès à PHP depuis le terminal, pardon, **l'invite de commande**.

![Add Php to your path](/images/windevPhpPath.png)

C'était donc confiant que je lançais l'installateur de **Composer**. Trop confiant peut-être.

![Composer windows installer](/images/erroComposerInstallExe_1.PNG)

Je suis donc passé par l'invite de commande, mais sans obtenir de meilleurs résultats :

![Composer install from cli](/images/composeurInvitCommande.PNG)

Je décidais de repousser à plus tard cette question de **Composer** pour me lancer dans l'installation de Git. Suivant mon idée initiale, je commençais par l’utilitaire officiel Github. Si l’installation elle-même fut sans problème, impossible ensuite de se connecter à Github. Ceci était sans aucun doute dû au Firewall.

Bref, la matinée commençait plutôt mal, et les bonnes vannes sur Windows me revenaient en tête au galop.

# Babun

Il me semblait pourtant me rappeler d'une possible solution à mon problème, une promesse de console sous Windows que j'avais dû noter quelque part... Grâce à [Raindrop](https://raindrop.io), j'ai retrouvé ce projet: [Babun](http://babun.github.io/).

Voici la description officielle du projet : "*Would you like to use a linux-like console on a Windows host without a lot of fuzz? Try out babun!*".

Une fois l'installation terminée sans problème, je lançais un premier test `badun check`, me rappelant que j'étais derrière un firewall.

![Babun check fail](/images/babunCheckFirewall.PNG)

Il a donc juste fallu configurer le proxy dans le fichier `~/.babunrc` pour que tout semble fonctionner.

```
export http_proxy=http://LOGIN:PASSWORD@PROXY_URL:PROXY_PORT
export https_proxy=$http_proxy
export ftp_proxy=$http_proxy
export no_proxy=localhost
```

![Babun check success](/images/babunCheckFirewallPROXY.PNG)

J'enchainais donc avec l'installation de PHP grâce au gestionnaire de package de Babun **Pact** (et à l'ajout d'un fichier ~/.wgetrc pour déclarer le proxy pour la commande `wget` parfois utilisée par Pact), puis Composer, le tout sans erreur. Reconnaissant envers [Tomek Bujok](https://twitter.com/tombujok), j'avais un environnement PHP fonctionnel et une console déjà bien configurée (git, zsh, ...). J'ai même récupéré quelques .dotfile (qu'il ne faut pas oublié de convertir en ISO 8859-1), installé **tmux**, et j'avais presque l'impression d'être sur mon Mac.

 ![Composer installer](/images/tmuxMakeServer.PNG)

# Oui, mais

Il était enfin temps de se mettre eu travail : je lançais un `composer requier silex`, et là, *badabun* :

 ![Composer installer](/images/fuckedBabun.PNG)

Je passe les détails des recherches effectuées sur ce qui était un nouveau type d'erreur dans ma vie de développeur PHP, mais la conclusion en fut que le problème provenait de la version de Cygwin utilisée par Babun : la version 32 bits sur mon Windows 64 bits sur lequel était installé Symantec Endpoint Protection en 64 bits ... Qu'à cela ne tienne, il suffisait de passer le Cygwin en 64 bit. Sauf que cette version n'est pas, et ne sera à priori pas, supporté par Babun.

Ne me restait plus qu'une solution logique : se passer de Babun, et n'utiliser que le [Cygwin](https://www.cygwin.com/). Et ce fut effectivement la bonne solution. Babun n'est au final qu'une surcouche de configuration et d'utilitaires au-dessus de Cygwin, qui lui ne dispose ni d'un gestionnaire de package (il faut repasser par l'installateur Windows si on a oublié quelque chose), ni d'une configuration simplifiée du proxy, et qui n'est pas directement livré avec zsh, oh-my-zsh, git, etc ...
Au final, et avec un peu de temps, j'ai installé un environnement PHP et un composer global cette fois-ci fonctionnels, git, zsh, tmux, ...

 ![Composer installer](/images/finalCygwin.PNG)

# Pour finir

Rien de bien révolutionnaire dans ce post de blog: Cygwin est un projet déjà ancien. Mais c'est sans aucun doute un outil à connaitre, que l'on soit habituellement sous Windows ou pas. Le projet Babun est aussi intéressant, et accélère grandement l'installation d'une console compléte ... tant que la version de Cygwin 32 n'est pas un problème.

Mais quel rapport a donc tout cela avec le snobisme ? Et bien, il se trouve que c'est une question (il s'agissait d'ailleurs plus d'une affirmation) qui m'a été posée lors de ma quête vers une console fonctionnelle. La réponse évidente était que sans Cygwin, je ne pouvais pas installer Composer. Alors certes oui, j'aurais pu installer les librairies Silex et autres dépendance à la main. Mais on est en 2016, et je ne suis pas certain que mon tarif horaire soit suffisamment bas pour se lancer dans une telle perte de temps. Et plus important, j'ai mieux à faire.

Mais j'aimerais pour terminer ce post donner une encore bien meilleure réponse, lue à la fin du chapitre **Orthogonality** du livre **The Pragmatic Programmer** de **Andrew Hunt et David Thomas** :

   > Challenges : " Consider the difference between large GUI-oriented tools typically found on Windows systems and small but combinable command line utilities used at shell prompts. Which set is more orthogonal, and why? Which set is easier to combine with other tools to meet new challenges ? "
