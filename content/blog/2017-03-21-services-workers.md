+++
title="Découvrir les service workers"
slug="decouvrir-les-service-workers"
date = 2017-03-21
description="Un outil de plus dans la panoplie des développeurs web ? Les services workers offrent bien plus que la simple possibilité de rendre une application disponible hors-ligne. Voyons ça en pratique."
draft = false
in_search_index = true
[taxonomies]
categories = ["informatique"]
tags = ["javascript"]
[extra]
marmelab="https://marmelab.com/blog/2017/03/21/decouvrir-les-service-workers.html"
+++

<img class="responsive" src="/images/blog/serviceworkers/simple_schema-edited.jpg" alt="Image sourced by Google and modified by author." />

Il y a quelque temps, nous nous sommes confrontés à un nouveau besoin client : un mode d'édition offline dans une application mobile. Si plusieurs solutions s'offraient à nous, l’idée des service workers semblait prometteuse. Elle s'apparente à un proxy : dans cette configuration, le mode offline est rendu possible par un script chargé indépendamment de l’application cliente elle-même, et capable de réagir aux requêtes réseau.

L'idée a été écartée en raison du rapport coût / bénéfice de ce mode développement pour le client, et d'une autre raison que vous découvrirez à la fin de ce billet. Néanmoins, nous avons poursuivi l'exploration lors de hack days, pour comprendre exactement les implications de cette nouvelle technologie.

Ce billet est notre retour d'expérience sur un prototype très simple, un gestionnaire de playlist, qui fonctionne en mode offline.

Le code des exemples à suivre est [disponible sur Github](https://github.com/marmelab/service-worker-demo).

## Première prise de contact

On commence avec une page statique très simple, comprenant deux fichiers CSS, deux images, un fichier de fonts et un fichier js.

<img class="medium" src="/images/blog/serviceworkers/appBootstraped-t00.png" />

Nous allons maintenant créer le fichier du service worker: `service-worker.js`,

``` js
const version = '01';

self.addEventListener('install', event => {
  console.log('First service worker log')
});
```

Pour l'appeler dans notre page HTML, on rajoute:

``` js
if ('serviceWorker' in navigator) {
    navigator.serviceWorker.register('service-worker.js', { scope: '/' })
        .then(function(reg) {
            mainMessage('notify', 'Service worker is started');
        }).catch(function(error) {
            mainMessage('alert', 'Service worker registration failed with ' + error);
        });
} else {
    mainMessage('alert', 'Your browser do not support Service Worker');
}
```

Dans cet exemple, la fonction `mainMessage` affiche le message passé en paramètre dans le gros cartouche gris-vert à côté du lapin. Ca permet de voir ce qui se passe !

<img class="medium" src="/images/blog/serviceworkers/started.png" />

Remarque: Il est indispensable de **tester le support du service worker par le navigateur** (`'serviceWorker' in navigator`). En effet, l'un des problèmes, mais non des moindres, est que les services worker ne sont pas disponibles sur [tous les navigateurs](http://caniuse.com/#feat=serviceworkers). Pour faire court, on y a accès avec `Chrome`, `Firefox` et `Opera`, mais ni avec `IE` ni avec `Safari`. La bonne nouvelle, c'est que ces navigateurs supportant les services workers implémentent également bien l'ES2015.

Attention: **Le script s'exécute dans un thread séparé et vit ensuite en tâche de fond, que l'application soit ouverte ou pas** ! On remarque ainsi lorsque l'on recharge notre page que le `console.log('First service worker log')` n'affiche plus rien. Ce comportement s'explique par le cycle de vie du service.

Mais comment alors debugger ce service worker ? Les navigateurs offrent des outils dédiés pour cela:

* Firefox : `about:serviceworkers`
* Chrome : `chrome://serviceworker-internals/`

<img class="medium" src="/images/blog/serviceworkers/chromeDebug.png" />

## Le cycle de vie d'un service worker

Mettons à jour le fichier `service-worker.js`

``` js
const version = '02';

self.addEventListener('install', event => {
  console.log('Log from event "INSTALL" in service worker version ' + version);
});

self.addEventListener('fetch', event => {
  console.log('Log from event "FETCH" in service worker version ' + version);
});

self.addEventListener('activate', event => {
  console.log('Log from event "ACTIVATE" in service worker version ' + version);
});
```

L'ordre d'exécution des `console.log` illustre le cycle de vie du service worker :

<img class="medium" src="/images/blog/serviceworkers/sw-3events-t02.gif" />

On constate que les évènements `install` et `activate` ne sont exécutés qu'une fois, contrairement au `fetch` qui est appelé de nombreuses fois (à chaque appel réseau en fait). Cela s'explique très bien par le fonctionnement de notre service :

1. Le navigateur installe le service worker : c'est l'évènement `install`,

2. le navigateur active ce nouveau service worker (s'il le peut, comme nous allons le voir) : c'est l'évènement `activate`,

3. une fois activé, le service worker va pouvoir intercepter toutes les requêtes réseau des instances de l'application : c'est l'évènement `fetch`.

Si `install` et `fetch` sont simples à comprendre, `activate` m'a semblé moins évident. Cet événement est lié au fait qu'un service worker s'exécute en arrière-plan pour toutes les instances de l'application en cours, comme plusieurs onglets ouverts sur la même application. Le navigateur va pouvoir installer une nouvelle version du service worker dès qu'il la reçoit, mais il ne l'activera que lorsque **aucune session de l'application ne sera en cours d'exécution**.

Par exemple, mettons à jour `service-worker.js` :

``` js
 const version = '03';

```

Le navigateur est capable d'identifier tout changement au niveau du fichier du service worker, le mettant à jour en conséquence. Le navigateur va bien recevoir la nouvelle version et va l'installer.

**Conseil** : Comme tout fichier js, un fichier de service worker peut être mis en cache par le navigateur. Pensez donc à vos en-têtes HTTP de cache si vous voulez une mise à jour immédiate de votre service worker.

Par contre, cette nouvelle version ne sera *activée* que lorsque l'on aura quitté toutes les instances de l'application, pour ensuite la relancer.

 <img class="responsive" src="/images/blog/serviceworkers/sw-3events-t03.gif" />

Ce comportement potentiellement troublant peut être court-circuité via les évènements `install` et  `activate` de la manière suivante :

``` js
const version = '04';

self.addEventListener('install', event => {
  console.log('Log from event "INSTALL" in service worker version ' + version);
  return self.skipWaiting();
});

self.addEventListener('activate', event => {
  console.log('Log from event "ACTIVATE" in service worker version ' + version);
  return self.clients.claim();
});
```

## Premier bilan

Nous venons de voir plusieurs points fondamentaux si l'on veut se lancer dans l'utilisation des services workers:

* la **compatibilité** : les services workers ne sont pas disponibles sur tous les navigateurs. On va donc difficilement pouvoir baser le fonctionnement d'une application sur leur utilisation.

* le **cycle de vie dans un thread séparé**: un service worker va s'installer puis s'activer dans un processus indépendant. Ensuite, il pourra intercepter toutes les requêtes réseau effectuées par n'importe quelle instance de l'application au sein du navigateur.

* le fonctionnement **asynchrone** : ce point n'a pas encore été mis en avant, même s’il est apparu dans la version 2 du service worker d'exemple. Tout ce qui se passe au sein du service worker doit être asynchrone. En effet, il ne doit pas bloquer l'exécution de l'application.

* le **https est obligatoire** : toutes les requêtes réseau doivent être en https (sauf pour `localhost`, ce qui nous simplifie grandement le développement). Cela semble assez logique tant le pouvoir de nuisance d'un service worker redirigeant vers un site malintentionné semble grand.

## Un site hors ligne

Il est maintenant temps de configurer notre service worker afin de permettre la consultation "offline" de notre application.

### Phase 'install'

Lors de cette phase d'installation, vous allons pouvoir indiquer au service quels sont les éléments qui doivent être mis en cache. Pour faire simple au début, nous allons mettre en cache tous les fichiers de notre application, sauf le fichier de fonts.

```js
const version = '05';
const CACHE_NAME = 'sw-demo_1';

const urlsToCache = [
    '/index.html',
    '/playlist.html',
    '/css/normalize.css',
    '/css/sw-demo.css',
    '/images/catWorker.jpg',
    '/images/logo.png',
    '/covers/avecpasdcasque.jpg',
    '/covers/ryleywalker.jpg',
    '/covers/xeniaRubinos.jpg',
    '/js/sw-demo.js',
];

self.addEventListener('install', (event) => {
    event.waitUntil(
        caches.open(CACHE_NAME)
        .then(cache => cache.addAll(urlsToCache))
        .then(() => self.skipWaiting())
    );
});

// to be continued
```

Comme évoqué précédemment, tout est asynchrone:

* `event.waitUntil` est une fonction qui attend la résolution d'une promesse pour considérer l'évènement comme terminé.
* `caches.open` retourne un promesse lorsque le cache à utiliser est ouvert. En effet, le service worker va avoir accès à la méthode `caches` permettant de nommer plusieurs clés de cache au sein du service. On l'utilisera ici pour versionner le cache.
* `cache.addAll` va renvoyer une promesse lorsque l'ajout de tous les éléments sera terminé.

<img class="responsive" src="/images/blog/serviceworkers/sw-cache-storage.png" />

### Phase 'activate'

```js
self.addEventListener('activate',(event) => {
    event.waitUntil(
        caches.keys()
            .then(keys => {
                return Promise.all(keys
                    .filter(key => key !== CACHE_NAME)
                    .map(key => caches.delete(key))
                );
            })
            .then(() => self.clients.claim())
    );
});

// to be continued
```

Nous profitons de l’existence de la phase d'activation pour supprimer les éventuels caches créés par une précédente version du service worker.
Ce n'est pas obligatoire, et ceci n'est valable que parce que nous avons choisi de versionner ce cache...

### Phase 'fetch'

```js
self.addEventListener('fetch', (event) => {
    event.respondWith(
        fetch(event.request)
            .catch(() => {
                return caches.match(event.request);
            })
    );
});
```

Maintenant que notre service worker est installé et activé, nous pouvons profiter de sa capacité à intercepter les requêtes réseau.

Dans notre exemple, simplissime, nous allons juste répondre à l’événement `fetch` en retournant le résultat effectif de cette requête avec `fetch(event.request)`.

Jusque là, le service worker ne modifie pas le comportement attendu de l'application. Par contre, en ajoutant un `catch` pouvant correspondre à un retour en erreur du serveur - pour notre exemple on généralisera au cas "offline" - le service worker va pouvoir aller chercher dans son cache `caches.match(event.request)` si cette requête est présente. Si c'est le cas, c'est ce qui sera retourné au navigateur, rendant l’application disponible offline.

Vous pouvez tester ce comportement en vous rendant sur [l’application d'exemple](https://sw.alexisjanvier.space/), et en coupant votre connexion réseau.

## Conclusion

Bien qu'encore considérés comme expérimentaux, les services workers sont d’ores et déjà bien implémentés sur Chrome et Firefox. Leur non-prise en charge par IE ou Safari va sans doute limiter leur utilisation en production. Par exemple, l'application de notre client citée en introduction visait principalement les utilisateurs iOS, d'où l'abandon de cette technologie.

Leur relative simplicité laisse une grande liberté au développeur sur les comportements implémentés. Si l'exemple présenté dans ce post est vraiment très simple, on peut facilement envisager des stratégies de cache beaucoup plus complexes : adapter les réponses en fonction des médias demandés, adopter une politique de *"cache first"* et de prérequêtes afin d'accélérer l'affichage d'une application... Je pense même qu'un des risques est de pouvoir y coder trop de logique métier.

Son comportement transparent va également obliger à bien penser [l'interface utilisateur](https://developers.google.com/web/fundamentals/instant-and-offline/offline-ux) afin de ne pas rendre l'application déroutante (statut online/offline, données à jour, données synchronisées, ...).

Mais, et en évoquant d'autres possibilités annoncées dans la spécification des service workers, comme le [Push API](https://www.w3.org/TR/push-api/) ou le [Web Background Synchronization](https://wicg.github.io/BackgroundSync/spec/), c'est sans aucun doute une technologie à tester et à suivre dès que l'on s'intéresse aux applications web, mobiles ou non.
