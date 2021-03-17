+++
title="React Router v4, SSR, Redux Saga et Code Splitting sont dans un bateau"
slug="rr4-ssr-redux-code-splitting-dans-un-bateau"
date = 2017-10-22
description="React est rapide, pour peu que l'on y applique les bonnes optimisations. Le code splitting et le server side rendering sont deux pistes permettant d'atteindre cet objectif. Utilisons-les toutes les deux sur une application s'appuyant sur Redux, Saga et React Router V4."
tags = ["SSR"]
+++

![splitting.jpg](/images/code-splitting/splitting.jpg)

Nous travaillons actuellement chez Marmelab sur un projet client pour lequel nous avons progressivement migré depuis une application Symfony avec un peu de React côté client vers une application full React intégralement rendue côté serveur. Cette migration s’est faite petit à petit, en partant d’une stack familière incluant React Router V3, Redux et Saga. Mais les features s’enchainant, le code est devenu de plus en plus lourd et le routing s’est complexifié. À l’occasion de la trêve d’été sont donc apparus dans notre backlog les deux tickets suivant : « migration en React Router 4" et « mise en place du code splitting ».

Si la migration du routeur s’annonçait un peu longue (voir [React Router v4 Unofficial Migration Guide] [https://codeburst.io/react-router-v4-unofficial-migration-guide-5a370b8905a]) mais possible, nous voulions avant d’entamer ces 2 taches valider avec un POC le fonctionnement d’une stack incluant React Router v4 (RRV4), Redux Saga, fournissant du code splitting et compatible avec du *server side rendering* (SSR). Ce post documente la réalisation de ce POC !

## On repart de zero
L'opération de migration de l'application du client en RRV4 s'annonçant un peu longue, il était plus simple dans le cadre du POC de reprendre une application de zéro, mais possédant les mêmes contraintes de routing que celles rencontrées dans l'application *"mère"*.
Vous trouverez ici le code de cette application de départ (n'incluant pas encore Redux et ne réalisant pas d'appels asynchrones pour récupérer de la donnée) : [bootstrap de l'application](https://github.com/alexisjanvier/universal-react/releases/tag/step-1).

On va trouver quelques dépendances à des librairies externes :

```json
// in package.json
"dependencies": {
  "date-fns": "^1.28.5",
  "lodash.debounce": "^4.0.8",
  "material-ui": "^1.0.0-alpha.21",
  "material-ui-icons": "^1.0.0-alpha.19",
  "prop-types": "^15.5.10",
  "query-string": "^4.3.4",
  "react": "^15.6.1",
  "react-dom": "^15.6.1",
  "react-router-dom": "^4.1.1",
  "typeface-roboto": "0.0.31"
},

```

Et un routing simple en RRV4:

```js
// in src/shared/app/index.js
<Switch>
  <Route exact path="/" component={HomePage} />
  <Route path="/playlists/:playlistId(pl-[a-z]{0,4})" component={PlaylistPage} />
  <Route path="/playlists" component={PlayListsPage} />
  <Route path="/search-album" component={SearchAlbumPage} />
  <Route path="/albums/:albumSlug" component={AlbumPage} />
</Switch>

```

### Visualiser le gain

L'objectif de tout cela est bien d'optimiser notre code en générant des fichiers Javascript plus petits.
Il faut donc s'outiller pour analyser les fichiers générés par Webpack et pour cela [webpack-bundle-analyzer](https://www.npmjs.com/package/webpack-bundle-analyzer) s'annonce comme un excellent candidat.

Pour le moment Webpack ne génère qu'un seul fichier pour toute l'application:

```js
// in webpack.config.js
  entry: {
    client: `${srcPath}/client/index.js`,
  },

  output: {
    path: distPath,
    filename: '[name].js',
    publicPath: '/assets/',
  },
```

Pour visualiser la composition de ce fichier avec `webpack-bundle-analyzer`, il suffit d'ajouter le plugin à la configuration de webpack,

```js
// in webpack.config.js
if (process.env.NODE_ENV  ===  'analyse') {
  plugins.push(new BundleAnalyzerPlugin());
}
```

et de le lancer dans le bon environnement:

```bash
    NODE_ENV=analyse ./node_modules/.bin/webpack --config webpack.config.js -p
```

Le résultat: un gros fichier 274Kb (gzipped) dans lequel on trouve les nodes modules et notre code (la petite bande verticale à droite de l'image!).

![startingApplicationBundle.png](/images/code-splitting/startingApplicationBundle.png)
Nous allons donc nous appliquer à découper ce fichier pour pouvoir n’appeler que le code dont on a besoin là ou l’on en a besoin. C’est le code splitting.

## Première découpe

La première étape va consister à séparer dans 2 fichiers distincts (2 ***chunks***) le code des nodes modules utilisé dans toute l'application (`vendors.js`), et le code "métier" (`clients.js`).


```js
// in webpack.config.js
entry: {
  client: `${srcPath}/client/index.js`,
  vendor: ['react', 'react-dom', 'react-router-dom'],
},
output: {
  path: distPath,
  filename: '[name].js',
  publicPath: '/assets/',
},
```

Analysons ces maintenant 2 fichiers générés par Webpack:

![Capture d'écran de 2017-09-14 18-28-48.png](/images/code-splitting/console1.png)

![vendorChunkStep1.png](/images/code-splitting/vendorChunkStep1.png)

On retrouve bien `react`, `react-dom` et `react-router-dom` dans le fichier `vendors.js`. Par contre, on les retrouve aussi dans `clients.js`. C'est logique: Webpack a bien créé le `vendors.js` comme nous lui avons demandé, mais il a également créé le `client.js` incluant tous les `import`, `react` y compris. Nous avons donc presque doublé le poids du Javascript :(

Pour y remédier, nous allons utiliser [CommonsChunkPlugin](https://webpack.js.org/plugins/commons-chunk-plugin/) qui en gros va être capable de dédoublonner les modules spécifiés dans le `vendors.js` en ne les incluant plus dans `client.js`.

Voici le configuration finale de Webpack :

```js
// in webpack.config.js
const { BundleAnalyzerPlugin } =  require('webpack-bundle-analyzer');
const  path  =  require('path');
const  webpack  =  require('webpack');
const  srcPath  =  path.resolve(__dirname, 'src');
const  distPath  =  path.resolve(__dirname, 'dist');

const  plugins  = [
  new webpack.optimize.CommonsChunkPlugin({
    name: 'vendor',
    minChunks: Infinity,
  }),
];

if (process.env.NODE_ENV  ===  'analyse') {
  plugins.push(new BundleAnalyzerPlugin());
}

module.exports = {
  context: srcPath,
  target: 'web',

  entry: {
    client: `${srcPath}/client/index.js`,
    vendor: ['react', 'react-dom', 'react-router-dom'],
  },

  output: {
    path: distPath,
    filename: '[name].js',
    publicPath: '/assets/',
  },

  resolve: {
    modules: ['node_modules', 'src'],
    extensions: ['*', '.js', '.json'],
  },

  module: {
    rules: [
      {
        test:  /\.js$/,
        exclude:  /(node_modules)/,
        loader: 'babel-loader',
        query: { compact: false },
      },
    ],
  },

  plugins,
  devtool: 'source-map',
};
```

Et le résultat final :

![vendorChunkStep2.png](/images/code-splitting/vendorChunkStep2.png)

![vendorChunkStep3.png](/images/code-splitting/vendorChunkStep3.png)
C'est déjà beaucoup mieux. `CommonsChunkPlugin` fait encore beaucoup de choses permettant d'optimiser son code. Je vous renvoie à la lecture de [webpack bits: Getting the most out of the CommonsChunkPlugin](https://medium.com/webpack/webpack-bits-getting-the-most-out-of-the-commonschunkplugin-ab389e5f318) si vous voulez approfondir le sujet.

(*Le code de cette étape est disponible sur le tag [step-2](https://github.com/alexisjanvier/universal-react/releases/tag/step-2)*)

Il faut maintenant s'occuper de la découpe du `client.js`. Mais avant cela, nous allons mettre en place le SSR de notre application.

## Mise en place du server side rendering

Ici, rien de très compliqué, l'un des avantages de React étant d'avoir le SSR "out of the box". Ceci grâce à la méthode `renderToString` permettant de rendre notre application React dans un string avec Node.

Ce qui nous intéresse dans le cadre du POC, c'est le comportement du React Router. Tout repose sur l'utilisation d'un routeur spécifique, le [`<StaticRouter>`](https://reacttraining.com/web/api/StaticRouter) que l'on utilisera à la place du [`<BrowserRouter>`](https://reacttraining.com/web/api/BrowserRouter)

![Capture d'écran de 2017-09-15 09-10-43.png](/images/code-splitting/Capture d'écran de 2017-09-15 09-10-43.png)
On organise le code dans trois dossiers distincts.

#### Le code commun (shared)
C'est ici que l'on trouve toute notre application, avec la mise en place des routes.

```js
// in src/shared/app/index.js
const App = () => (
  <div>
    <MainMenu />
    <Switch>
      <Route  exact  path="/"  component={HomePage} />
      <Route  path="/playlists/:playlistId(pl-[a-z]{0,4})"  component={PlaylistPage} />
      <Route  path="/playlists"  component={PlayListsPage} />
      <Route  path="/search-album"  component={SearchAlbumPage} />
      <Route  path="/albums/:albumSlug"  component={AlbumPage} />
    </Switch>
  </div>
);
```

#### Le code navigateur (client)
C'est ici que l'on assure le rendu côté navigateur. Il s'agit pour le moment d'appeler notre application dans le routeur dédié aux navigateurs.

```js
// in src/client/index.js
import { render } from 'react-dom';
import { BrowserRouter as Router } from 'react-router-dom';

import App from '../shared/app';

class Main extends Component {
    render() {
        return (
            <Router>
                <App {...this.props} />
            </Router>
        );
    }
}

```

#### Le code serveur (server)
C'est un serveur `express` dont une route servira à générer le code html de l'application au sein du router `<StaticRouter>`. Cette string sera injectée dans un template html afin de générer la réponse finale du serveur. Le client utilisera alors le code client présent dans cette réponse pour redevenir une application React classique.

```js
// in src/server/index.js
import express from 'express';
import React from 'react';
import ReactDOMServer from 'react-dom/server';
import { StaticRouter } from 'react-router-dom';

import App from '../shared/app';
// render is used to inject html in a globale template
import render from './render';

const app = express();
// Serve client.js and vendor.js
app.use('/assets', express.static('./dist'));

app.get('*', (req, res) => {
    const context = {};

    const appWithRouter = (
        <StaticRouter location={req.url} context={context}>
            <App />
        </StaticRouter>
    );

    if (context.url) {
        res.redirect(context.url);
        return;
    }

    const html = ReactDOMServer.renderToString(appWithRouter);

    res.status(200).send(render(html));
});

app.listen(3000, () => console.log('Demo app listening on port 3000'));

```

Et tout cela marche plutôt bien. Le manière la plus simple de le tester, c'est de désactiver le javascript sur son navigateur.

![testSSR.gif](/images/code-splitting/testSSR.gif)

(*Le code de cette étape est disponible sur le tag [step-3](https://github.com/alexisjanvier/universal-react/releases/tag/step-3)*)


## Code splitting, phase 2

Et encore une fois, c'est par webpack que cela passe. Si l'on se réfère à la [documentation](https://webpack.js.org/guides/code-splitting/), le code splitting repose sur 3 approches :

>
>*   Entry Points: Manually split code using [`entry`](https://webpack.js.org/configuration/entry-context) configuration.
>*   Prevent Duplication: Use the [`CommonsChunkPlugin`](https://webpack.js.org/plugins/commons-chunk-plugin) to dedupe and split chunks.
>*   Dynamic Imports: Split code via inline function calls within modules.
>

Bonne nouvelle, nous avons déjà appliqué les deux premières approches. Reste donc l'approche de l'import dynamique. En gros, le code appelé de manière dynamique (asynchrone) sera isolé dans un chunk par Webpack qui se chargera également de générer le code permettant d'appeler le bon chunk au bon moment.

Pour appeller du code de manière dynamique et reconnu par webpack, on va devoir utiliser la syntaxe [`import()`](https://webpack.js.org/api/module-methods#import-) (methode recommandée car conforme à l'ECMAScript) ou bien la syntaxe [`require.ensure`](https://webpack.js.org/api/module-methods#require-ensure) spécifique à WebPack.

Ce qui donnerait pour un composant React

```js
import React from 'react'

class Home extends React.Component {
  state = { Component: null }

  componentWillMount() {
    import('./Home').then(Component => {
      this.setState({ Component })
    })
  }

  render() {
    const { Component } = this.state
    return Component ? <Component {...props} /> : null
  }
}
```
*(cet exemple provient du post de blog [Introducing loadable-components](https://medium.com/smooth-code/introducing-loadable-components-%EF%B8%8F-646dd3ab0aa6))*

Afin de ne pas avoir à transformer tous nos composants on va utiliser un [HOC](https://facebook.github.io/react/docs/higher-order-components.html), le [loadable-components](https://www.npmjs.com/package/loadable-components).

Ainsi, nous n'appellerons plus nos composants de page de manière synchrone dans le routing, mais de manière asynchrone en les mappant dans ce HOC. Ainsi Webpack pourra créer un chunk par route.

Notre `src/shared/app/index.js` ne vas pas changer.

```js
// in src/shared/app/index.js
import React from 'react';
import { Route, Switch } from 'react-router-dom';

import * as Routes from './routes';
import MainMenu from './mainMenu';

const App = () => (
    <div>
        <MainMenu />
        <Switch>
            <Route exact path="/" component={Routes.HomePage} />
            <Route path="/playlists/:playlistId(pl-[a-z]{0,4})" component={Routes.PlaylistPage} />
            <Route path="/playlists" component={Routes.PlayListsPage} />
            <Route path="/search-album" component={Routes.SearchAlbumPage} />
            <Route path="/albums/:albumSlug" component={Routes.AlbumPage} />
        </Switch>
    </div>
);
export default App;
```

Mais tout se passse au niveu de `src/shared/app/routes.js`:

```js
// src/shared/app/routes.js
import loadable from 'loadable-components';

export const AlbumPage = loadable(() => import('../albums/AlbumPage'));
export const HomePage = loadable(() => import('../home/HomePage'));
export const PlaylistPage = loadable(() => import('../playlists/PlaylistPage'));
export const PlayListsPage = loadable(() => import('../playlists/ListPage'));
export const SearchAlbumPage = loadable(() => import('../albums/SearchPage'));
```

Il faut également penser à rendre Babel compatible avec la syntaxe `import()` en ajoutant le plugin [dynamic-import-webpack](https://github.com/airbnb/babel-plugin-dynamic-import-webpack)

```json
// in .babelrc
{
    "plugins": ["dynamic-import-webpack"],
    "presets": [
        "react",
        [
            "env",
            {
                "targets": {
                    "browsers": ["last 1 version", "ie >= 11"]
                }
            }
        ]
    ]
}

```

Et il est maintenant temps de voir le résultat final :

```bash
NODE_ENV=analyse ./node_modules/.bin/webpack --config webpack.client.config.js -p
Hash: 6ab25e3738d87ca6f2d5
Version: webpack 3.3.0
Time: 5715ms
     Asset       Size  Chunks             Chunk Names
      0.js    36.5 kB       0  [emitted]
      1.js    36.9 kB       1  [emitted]
      2.js    11.6 kB       2  [emitted]
      3.js    20.7 kB       3  [emitted]
      4.js  747 bytes       4  [emitted]
 client.js     102 kB       5  [emitted]  client
 vendor.js     191 kB       6  [emitted]  vendor
index.html  409 bytes          [emitted]

```

![vendorChunkWithCodeSpliting.png](/images/code-splitting/vendorChunkWithCodeSpliting.png)
Et voilà, notre code est divisé en autant de chunks que de pages, plus un `client.js` et un `vendor.js` utilisés par toutes les pages de l'application !

![codeSplitting.gif](/images/code-splitting/codeSplitting.gif)

(*Le code de cette étape est disponible sur le tag [step-4](https://github.com/alexisjanvier/universal-react/releases/tag/step-4)*)

Mais est-ce que cela marche avec le SSR ?

![CS-SSR-KO.gif](/images/code-splitting/CS-SSR-KO.gif)

Eh bien non, pas encore :(

Cela s'explique assez bien: le code de nos composants de pages est maintenant appelé de manière asynchrone. Or, la route côté serveur est elle synchrone. On retrouve donc bien tout le code appelé de manière classique (la barre de menu), mais pas le contenu des pages.

Pour que cela fonctionne, on va utiliser la méthode `getLoadableState` fournie par `loadable-components` qui va nous permettre de réaliser un pré rendu de l'application côté serveur (dont les appels asynchrones) et d'extraire les références des chunks nécessaires au rendu de la page demandée. Nous allons aussi devoir rendre la route de rendu asynchrone (avec `async` et `await`).

```js
// in src/server/index.js
import express from 'express';
import React from 'react';
import ReactDOMServer from 'react-dom/server';
import { StaticRouter } from 'react-router-dom';
import { getLoadableState } from 'loadable-components/server';

import App from '../shared/app';
import render from './render';


const app = express();
app.use('/assets', express.static('./dist'));

app.get('*', async (req, res) => {
    const context = {};

    const appWithRouter = (
        <StaticRouter location={req.url} context={context}>
            <App />
        </StaticRouter>
    );

    if (context.url) {
        res.redirect(context.url);
        return;
    }

    const loadableState = await getLoadableState(appWithRouter);
    const html = ReactDOMServer.renderToString(appWithRouter);

    res.status(200).send(render(html, loadableState));
});

app.listen(3000, () => console.log('Demo app listening on port 3000'));

```

Les références aux chunks utilés sont injectées dans le template global de la page via la méthode `getScriptTag()` de l'objet `loadableState` généré lors de pré-rendu:

```js
// in src/server/render.js
export default (html, loadableState) => `
    <!DOCTYPE html>
    <html lang="en">
        <head>
            <meta charset="UTF-8">
            <title>Get real playlists to share with Spotify</title>
            <link href="https://fonts.googleapis.com/icon?family=Material+Icons" rel="stylesheet">
            <link rel="icon" type="image/png" href="/assets/favicon.ico" />
        </head>
        <body>
            <div id="root">${html}</div>
            <script src="/assets/vendor.js"></script>
            <script src="/assets/client.js"></script>
            ${loadableState.getScriptTag()}
        </body>
    </html>
`;
```

`loadableState.getScriptTag()` va permettre d'inserer la balise `<script>window.__LOADABLE_COMPONENT_IDS__ = [1];</script>` (ici le `[1]`) correspond au numéro du chunk de la homepage). Au final, le code client va utiliser cette information pour charger le bon chunk grâce à l'utilisation de la méthode `loadComponents` fournie par le `loadable-components`.

```js
// in src/client/index.js
import { loadComponents } from  'loadable-components';
import { render } from 'react-dom';
import { BrowserRouter as Router } from 'react-router-dom';

import App from '../shared/app';

const Main = (props) => (
    <Router>
        <App {...props} />
    </Router>
);

loadComponents().then(() => {
    render(
        <Main />
        document.getElementById('root'),
    );
});

```

Re-testons après avoir appliquer ces modifications (*diponibles sur le tag [step-5](https://github.com/alexisjanvier/universal-react/releases/tag/step-5)*)

![CS-SSR-OK.gif](/images/code-splitting/CS-SSR-OK.gif)

**\o/**

## Implémentation de Redux et de Redux Saga

L'ajout de Redux n'est pas problématique vis-à-vis du Reactr Router V4 ni du code splitting. Par contre l'utilisation de Saga n'a pas été sans difficulté, principalement pour le server-side rendering.

On va réaliser un simple appel à l'API Github permettant d'obtenir une liste des derniers Gist public (cet appel API ne nécessite pas de clé personnelle, rendant le partage du code de ce POC plus simple). L'appel est fait via une saga depuis la home page. Toute la difficulté est d'attendre que la saga soit réalisée côté serveur avant de rendre le Html. On y arrive principalement avec :

* un premier prérendu asynchrone qui va lancer les sagas (c'est ce que nous faisons déjà avec le `const loadableState = await getLoadableState(appWithRouter)` mis en place pour rendre le code splitting fonctionnel en SSR),
* l'utilisation de l'évènement [`END`](https://github.com/redux-saga/redux-saga/issues/255) qui permet de résoudre toutes les sagas en écoute.

Je ne vais pas détailler ce point, car cela a déjà été fait par mon cher collègue [Julien](https://twitter.com/juliendemangeon?lang=fr) dans son post de blog [React Isomorphique en pratique](https://marmelab.com/blog/2016/12/21/react-isomorphique-en-pratique.html).

Mais voici à quoi ressemble le code final côté serveur :

```js
app.get('*', async (req, res) => {
    const store = configureStore();
    const context = {};

    const appWithRouter = (
        <Provider store={store}>
            <StaticRouter location={req.url} context={context}>
                <App />
            </StaticRouter>
        </Provider>
    );

    if (context.url) {
        res.redirect(context.url);
        return;
    }

    let loadableState = {};

    // .done is resolved when store.close() send an END event
    store.runSaga(sagas).done.then(() => {
        const html = ReactDOMServer.renderToString(appWithRouter);
        const preloadedState = store.getState();

        return res.status(200).send(render(html, loadableState, preloadedState));
    });

    // Trigger sagas for component to run
    // https://github.com/yelouafi/redux-saga/issues/255#issuecomment-210275959
    loadableState = await getLoadableState(appWithRouter);

    // Dispatch a close event so sagas stop listening after they're resolved
    store.close();
});

```

Le code complet est disponible sur le [master](https://github.com/alexisjanvier/universal-react) du dépot Github.

## Conclusion

L'objectif du POC est bien atteint : on a une application React, React Router V4, Redux, Saga qui fonctionne. Le code est bien découpé en plusieurs fichiers distincts et ces parties de code ne sont appelées qu'en cas de besoin (en fonction du routing). L'ensemble fonctionne en server side rendering.

Pour autant quelques réserves persistent. Le choix important du composant HOC permettant d'appeler des composants existants en asynchrone c'est fait sur la facilité. `loadable-components` répondant au cahier des charges. Mais il en existe beaucoup d'autres : # [react-universal-component](https://github.com/faceyspacey/react-universal-component), [react-loadable](https://github.com/thejameskyle/react-loadable)... Il faudrait tous les tester en condition de production pour être serein sur ce choix.

Ensuite, le server side rendering est une stratégie évidente dans le cadre de problématiques de SEO. Mais en ce qui concerne la performance, l'arrivée du [stream](https://www.youtube.com/watch?v=UhdGiVy3_Nk) dans la dernière version de React donne envie de poursuivre l'expérimentation plus en amont avant d'entamer un gros chantier d'optimisation.

Mais quand il s'agit d'optimisation, les pistes à suivre sont innombrables: web workers, lazyloading, pure component, preact ... Je vous invite par exemple à lire l'excellent article [A React And Preact Progressive Web App Performance Case Study: Treebo](https://medium.com/dev-channel/treebo-a-react-and-preact-progressive-web-app-performance-case-study-5e4f450d5299).

