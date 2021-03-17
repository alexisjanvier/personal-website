+++
title="Bouchonner une API avec Polly.js"
slug="bouchonner-une-api-avec-pollyjs"
date = 2019-10-09
description="Ce n'est jamais simple de mettre en place des tests fonctionnels impliquant une base de données ou des appels à une API externe. Si Polly.js ne résout pas le problème de la base de données, c'est un outil utile à connaitre pour bouchonner des appels vers une API."
tags = ["javascript"]
+++

Une solution simple à mettre en place lors de la création de tests fonctionnels sur une API dépendant elle-même d'appels à une autre API consiste à créer des fixtures. Il suffit alors de mettre en place un mock du client à cette API, mock qui se chargera de renvoyer des fixtures. Un petit exemple avec [Jest](https://jestjs.io/), [supertest](https://github.com/visionmedia/supertest) et un client d'API basé sur [axios](https://github.com/axios/axios):

```javascript
// in apiClient.js
import axios from 'axios';

import config from '../path-to/config';

export const apiClientFactory = (httpClient, token)  =>  httpClient.create({
    baseURL: config.baseUrl,
    timeout: config.timeout,
    headers: {
        Authorization: `Bearer ${token}`,
        ...headers,
    },
});

export const apiClient = apiClientFactory(axios, config.token);
```

```javascript
// in router.js
import express from 'express';

import { apiClient } from './apiClient';

export const apiRouter = express.Router();

apiRouter.get('/:objectId', async (req, resp) => {
    const { objectId } = req.params;

    try {
        const { body: object } = await apiClient.get(`/object/${objectId}`);
        res.json(object);
    } catch (error) {
        res.status(404).send(`Object ${objectId} not found`);
    }
});

```

```javascript
// in createRequest.js
import express from 'express';
import request from 'supertest';


export const createRequest = () => {
    const app = express();
    // The application router must be importer after the clients mocks
    const apiRouter = require('./router');
    app.use('/', apiRouter);

    return request(app);
};
```

```javascript
// in router.spec.js
import axios from 'axios';

import { createRequest } from './createRequest';

jest.mock('axios');

const objectFixture = {
    id: 'uuid',
    name: 'object name',
};

describe('Object API endpoint', () => {
    describe('GET /objectId', () => {
        it('should return an object from external API', () => {
            axios.get.mockImplementation(() => Promise.resolve({ data: objectFixture }));
            const request = createRequest();
            return request.get('/uuid').expect(({ status, body }) => {
                expect(status).toBe(200);
                expect(body.title).toEqual('object name');
            });
        });
    });
});
```

Mais cela peut devenir rapidement fastidieux de créer ces fixtures et surtout de les maintenir. Sur l'un de nos projets client, nous avions une API testée fonctionnellement et dépendante de trois autres API. Lorsque une quatrième API a été implémenté, nous en avons profité pour changer notre stratégie de mock. Nous nous sommes tourné vers [Polly.js](https://netflix.github.io/pollyjs/#/), une librairie maintenue par Netflix, qui permet d'enregistrer tous les appels fait à une ou plusieurs API en mode `RECORD` et de les rejouer en mode `REPLAY`. Voici le retour d'expérience de cette implémentation.

## Première Mise en Place

Ce billet n'est pas un tutoriel, il ne s'attarde donc pas sur les modalités de mise en place de Polly. Et d'ailleurs, le projet possède une [très bonne documentation](https://netflix.github.io/pollyjs/#/README).

Les tests étant effectués sur une API réalisée en Node, nous avons utilisé l'[adapter-node-http](https://www.npmjs.com/package/@pollyjs/adapter-node-http), et nous avons choisi de stocker les enregistrements sur l'hôte de la machine avec le [persister-fs](https://www.npmjs.com/package/@pollyjs/persister-fs). Les tests étant gérés par Jest, nous avons aussi utilisé [setup-polly-jest](https://www.npmjs.com/package/setup-polly-jest). En repartant de l'exemple d'introduction, voila ce que cela donne :

```javascript
// in setupPolly.js
import path from 'path';
import NodeHttpAdapter from '@pollyjs/adapter-node-http';
import { Polly } from '@pollyjs/core';
import FSPersister from '@pollyjs/persister-fs';
import { MODES } from '@pollyjs/utils';
import { setupPolly } from 'setup-polly-jest';

Polly.register(NodeHttpAdapter);
Polly.register(FSPersister);

export const startPolly = () =>
    setupPolly({
        mode: MODES.REPLAY,
        recordIfMissing: process.env.POLLY_RECORD || false,
        adapters: ['node-http'],
        persister: 'fs',
        persisterOptions: {
            fs: {
                recordingsDir: path.resolve(__dirname, './recordings'),
            },
        },
    });

export const describePolly = string => string.replace(/\//g, '-');
```

```javascript
// in router.spec.js
import { createRequest } from './createRequest';
import { describePolly, setupPolly } from './setupPolly';

describe('Object API endpoint', () => {
    setupPolly();
    describe(describePolly('GET /objectId'), () => {
        it('should return an object from external API', () => {
            const request = createRequest();
            return request.get('/uuid').expect(({ status, body }) => {
                expect(status).toBe(200);
                expect(body.title).toEqual('real name from real api call');
            });
        });
    });
});
```

Tout d'abord, Polly doit-être lancer durant les tests. Il faut donc logiquement lancer le setupPolly à l'intérieur d'un `describe`.

Ensuite, Polly sauvegarde ses enregistrements (au format `.har`) en les organisant dans des répertoires respectant l'imbrication des `describe` et `it` des tests. C'est pour cela que l'on utilise la méthode `describePolly`, qui dans le cas d'une description de tests prenant la forme d'une url d'api, va transformer les `/` en `-`. Sans quoi, on se retrouve avec une infernale imbrication de répertoires ...

Par exemple, pour un test prenant la forme :

```javascript
describe('my test', () => {
    it('/domain/subdomain/api/object/id'), () => {
        // test
    });
});
```

On aura un enregistrement sous la forme :

```bash
.
├── my-test
│   └── domain
│       └── subdomain
│           └── api
│               └── object
│                   └── id
│                       └── my-record.har

```

En utilisant `pollyDescribe`

```javascript
describe('my test', () => {
    it(pollyDescribe('/domain/subdomain/api/object/id')), () => {
        // test
    });
});
```

On aura un enregistrement sous la forme :

```bash
.
├── my-test
│   └── domain-subdomaine-api-object-id
│       └── my-record.har

```

Et enfin, on utilise une variable d'environnement `POLLY_RECORD` pour lancer l'enregistrement des appels API manquant lors de la mise en place des tests. Cette variable d'environnement n'existera pas sur le serveur d'intégration continue.

## Premières Erreurs

Si les premiers enregistrements se passent bien (`POLLY_RECORD=true yarn test`) - on voit bien les fichiers `.har` dans le répertoire recordings - c'est moins convaincant en mode replay (`yarn test`). 

En effet, les tests semblent devenir aléatoires : un coup vert, un coup rouge avec cette erreur :

```bash
PollyError: [Polly] [adapter:node-http] Recording for the following request is not found and `recordIfMissing` is `false`.
```

Si la solution de ce problème est simple, nous avons tout de même mis un peu de temps à la trouver ... En se plongeant de la documentation de la [configuration de Polly](https://netflix.github.io/pollyjs/#/configuration), on se rend compte que l'on peut jouer sur beaucoup de paramètres permettant d'identifier un enregistrement. Et notamment, on peut identifier ou non un enregistrement selon le port de l'appel à l'API (ce qui est le cas d'une configuration par défault).

Hors, nous utilisons `supertest`. Sans rentrer dans les détails de son fonctionnement, `supertest` lance une instance de serveur à chaque appel à la fonction `getRequest()`. Pour ne pas risquer d'ouvrir deux serveurs sur le même port, par exemple si on lance les tests en parallèle, il lance les serveurs sur des ports aléatoire ! 

Ce qui explique l'instabilité des tests: parfois on a de la chance et le serveur est lancé sur le même port qu'un enregistrement - le test est vert - ; parfois non - le test est rouge -.

Il faut donc exclure le port des identifiants d'enregistrement :

```javascript
// in setupPolly.js
// [...]
export const startPolly = () =>
    setupPolly({
        mode: MODES.REPLAY,
        recordIfMissing: process.env.POLLY_RECORD || false,
        adapters: ['node-http'],
        persister: 'fs',
        persisterOptions: {
            fs: {
                recordingsDir: path.resolve(__dirname, './recordings'),
            },
        },
        matchRequestsBy: {
            method: true,
            headers: true,
            body: true,
            order: false,
            url: {
                protocol: true,
                username: false,
                password: false,
                hostname: true,
                port: false,
                pathname: true,
                query: true,
                hash: true,
            },
        },
    });
```

Cette plongé dans la documentation a également attiré notre attention sur le fait que les headers pouvaient ou non être utilisé comme identifiant d'enregistrement. 

Et c'est embêtant, car pour réaliser les appels à la vraie API, celle que nous enregistrons, nous avons besoins d'un `token` **secret** passé dans la paramètre `authorization` des en-têtes http ! Et effectivement, en regardant dans nos premiers fichiers d'enregistrements: horreur !

```json
{
  "log": {
    ...
    "entries": [
      {
        "_id": "6ae90598bd68b085105dc62620e42539",
        "_order": 0,
        "cache": {},
        "request": {
          "bodySize": 0,
          "cookies": [],
          "headers": [
            {
              "name": "accept",
              "value": "application/json, text/plain, */*"
            },
            {
              "name": "authorization",
              "value": "Bearer OURSUPERSUPERSECRETTOKEN"
            },
          ],
          ...
```

Et là où il faut être attentif, c'est qu'exlure les headers des identifiants d'enregistrement de Polly n'implique pas que les `headers` ne se retrouvent pas dans les enregistrements. Pour vraiment les y exlure, il faut un peu mettre les mains sous le capot :

```javascript
// in router.spec.js
import { createRequest } from './createRequest';
import { describePolly, setupPolly } from './setupPolly';

describe('Object API endpoint', () => {
    const { polly: { server } } = setupPolly();
    server.any().on('beforePersist', (req, recording) => {
        recording.request.headers = recording.request.headers.filter(({ name }) => name !== 'authorization');
    });

    describe(describePolly('GET /objectId'), () => {
        it('should return an object from external API', () => {
            const request = createRequest();
            return request.get('/uuid').expect(({ status, body }) => {
                expect(status).toBe(200);
                expect(body.title).toEqual('real name from real api call');
            });
        });
    });
});
```

Ainsi configuré, Polly permet maintenant d'enregistrer tous les appels http réalisés durant les tests, d'exclure les éventuels jetons secrets des enregistrements, et de rejouer de manière stable les enregistrements lors du passage des tests sur le serveur d'intégration continue.

## Second Piège

Les tests sont stables. En fait trop stables ! Nous les avons mis en place avant d'entamer un refactoring conséquent sur notre projet suite à l'introduction de la nouvelle API. Et les tests sont restés vert durant tous cette phase de refactoring.

Incroyable ? Non, désastreux !

> Il ne faut jamais faire confiance à un test qui n'a jamais échoué !

Et effectivement, nous avons fait une erreur, rétrospectivement idiote, lors de la mise en place de Polly. Le problème de port httpaurait dû nous alerter de suite ! 

**Nous avons enregistré la réponse de l'API que nous voulions tester !** Les tests étaient donc de fait très stable ...

Il faut donc remettre les mains sous le capot pour exclure les appels à localhost (notre serveur d'API) des enregistrements :

```javascript
// in router.spec.js
import { createRequest } from './createRequest';
import { describePolly, setupPolly } from './setupPolly';

describe('Object API endpoint', () => {
    const { polly: { server } } = setupPolly();
    server.any().on('beforePersist', (req, recording) => {
        recording.request.headers = recording.request.headers.filter(({ name }) => name !== 'authorization');
    });

    server
        .any()
        .filter(req => /^127.0.0.1:[0-9]+$/.test(req.headers.host))
        .passthrough();

    describe(describePolly('GET /objectId'), () => {
        it('should return an object from external API', () => {
            const request = createRequest();
            return request.get('/uuid').expect(({ status, body }) => {
                expect(status).toBe(200);
                expect(body.title).toEqual('real name from real api call');
            });
        });
    });
});
```

## Conclusion

Polly.js est sans aucun doute une bonne librairie pour enregistrer et rejouer des appels d'API. La documentation est très propre, et elle est maintenue par un boite qui devrait durer.

Mais sa mise en place n'est pas sans chausses-trappes, et demande donc d'être bien attentif aux enregistrements réalisés, même si de part leur taille, leur review n'est pas évidente sur Github.

On aurait aimé que des problématiques aussi classique que l'exclusion de certaines url (particulièrement le localhost !) ou l'exclusion de certain en-têtes d'authentification puissent être plus simplement géré, par exemple depuis la configuration ! 

Mais c'est peut-être aussi que Polly.js n'était le bon outil pour répondre à notre problématique ? Si son utilisation semble bien adaptée au mock d'une API frontale, par exemple pour tester une application consommatrice de l'API comme une application web, Polly s'en sort moins bien quand il s'agit de mocker de multiples appels à des API différentes. Dans ce cas, Polly nécessitte beaucoup de configuration et de hacks, avec des résultats parfois inattendus...
