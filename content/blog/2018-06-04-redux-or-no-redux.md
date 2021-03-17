+++
title="Avec ou sans Redux ?"
slug="avec-ou-sans-redux"
date = 2018-06-04
description="Redux est un outil fantastique, mais convient-t-il à toutes les situations ? Sans doute pas."
tags = ["react"]
+++

Chez Marmelab on aime beaucoup [Redux](https://redux.js.org/). Il faut dire que son arrivée a été un vrai moment d'évolution dans notre manière de penser nos applications : store immutable, sensibilisation à la programmation fonctionnelle, gestion asynchrone des call API avec les générateurs de Redux-Saga, ... À tel point que l'on a eu tendance à l'intégrer de facto dans notre stack en démarrage de projet.  
Mais est-ce vraiment une bonne idée ? Pas certain ...

## Un Exemple

Prenons une application très simple de gestion de meetup. L'objectif est de pouvoir visualiser :

* une liste des propositions de talks,
* une liste de souhaits de talks,
* une liste des membres du meetup.

Les données sont obtenues via une [API REST](https://expressserver-xsdtbkkhsf.now.sh) et l'application tout comme l'API sont protégées par un login/password.

L'application est bootstrappée avec [Create React App](https://github.com/facebook/create-react-app) auquel on rajoute :

* [Redux](https://redux.js.org/)
* [Redux-Saga](https://redux-saga.js.org/)
* [react-router-redux](https://github.com/reactjs/react-router-redux)

Voilà à quoi ressemble le projet :

<iframe src="https://codesandbox.io/embed/m5n2xjl6pj?autoresize=1&module=%2Fsrc%2FApp.js&moduleview=1&view=editor" style="width:100%; height:500px; border:0; border-radius: 4px; overflow:hidden;" sandbox="allow-modals allow-forms allow-popups allow-scripts allow-same-origin"></iframe>

Cette application commence donc par un composant principal `App.js` qui se charge de monter le store Redux `<Provider store={store}>` et les routes `<ConnectedRouter history={history}>` :

 ```js
// in App.js
...
 export const App = ({ store, history }) => (
    <Provider store={store}>
        <ConnectedRouter history={history}>
            <Container>
                <Header />
                <Switch>
                    <Route exact path="/" component={Home} />
                    <Route path="/talks" component={Talks} />
                    <Route path="/wishes" component={Wishes} />
                    <Route path="/members" component={Members} />
                    <Route path="/login" component={Authentication} />
                    <Route component={NoMatch} />
                </Switch>
            </Container>
        </ConnectedRouter>
    </Provider>
);
 ```

Tous les composants *métier* (ceux rendus par une route, comme `<Route path="/talks" component={Talks} />` sont organisés selon la structure bien connue des utilisateurs de Redux :

* les actions,
* les reducers,
* les sagas.

Par exemple pour la page des talks :

``` bash
├── talks
│   ├── actions.js
│   ├── reducer.js
│   ├── sagas.js
│   └── Talks.js
 ```

Le composant de page est très simple :

 ```js
 // in talks/Talks.js
export const Talks = ({ isLoading, talks }) => (
    <div>
        <h1>Talks</h1>
        {isLoading && <Spinner />}
        {talks && talks.map(talk => <h2 key={talk.id}>{talk.title}</h2>)}
    </div>
);

const mapStateToProps = ({  talks }) => ({
    isLoading: talks.isLoading),
    talks: talks.data,
});

const mapDispatchToProps = {};

export default connect(mapStateToProps, mapDispatchToProps)(Talks);
```

Les données `talks` ne sont pas appelées au `ComponentWillMount` comme on pourrait s'y attendre mais grâce à une saga à l'écoute du routeur :

```js
// in talks/sagas.js
import { put, select, takeLatest } from 'redux-saga/effects';
import { LOCATION_CHANGE } from 'react-router-redux';

import { loadTalks } from './actions';
import { hasData } from './reducer';

export function* handleTalksLoading() {
    if (yield select(hasData)) {
        return;
    }

    yield put(loadTalks());
}

export const sagas = function*() {
    yield takeLatest(
        action =>
            action.type === LOCATION_CHANGE &&
            action.payload.pathname === '/talks',
        handleTalksLoading,
    );
};
```

Au changement de route `action.type === LOCATION_CHANGE` - si la nouvelle route correspond à la section des talks `action.payload.pathname === '/talks'` et que les données ne sont pas déja présentes `if (yield select(hasData))` - on lance une action avec la fonction `loadTalks` :

```js
// in talks/actions.js
import { createAction } from 'redux-actions';

export const LOAD_TALKS = 'LOAD_TALKS';
export const loadTalks = createAction(
    LOAD_TALKS,
    payload => payload,
    () => ({
        request: {
            url: '/talks',
        },
    }),
);
```

Cette action contenant l'url permettant d'obtenir les données sur les talks dans ses **meta** va être interceptée par une **saga** générique de fetch `action => !!action.meta && action.meta.request`:

```js
// in /services/fetch/fetchSagas.js
import { call, put, takeEvery, select } from 'redux-saga/effects';
import { createAction } from 'redux-actions';

import { appFetch as fetch } from './fetch';

export const fetchError = (type, error) =>
    createAction(
        `${type}_ERROR`,
        payload => payload,
        () => ({
            disconnect: error.code === 401,
        }),
    )(error);

export const fetchSuccess = (type, response) =>
    createAction(`${type}_SUCCESS`)(response);

export function* executeFetchSaga({ type, meta: { request } }) {
    const token = yield select(state => state.authentication.token);
    const { error, response } = yield call(fetch, request, token);
    if (error) {
        yield put(fetchError(type, error));
        return;
    }

    yield put(fetchSuccess(type, response));
}

export const sagas = function*() {
    yield takeEvery(
        action => !!action.meta && action.meta.request,
        executeFetchSaga,
    );
};

```

Une fois le fetch réussi `fetchSuccess`, on lance une dernière action indiquant la réussite de la récupération des données `createAction('${type}_SUCCESS')(response)`, action utilisée au niveau du **reducer** des talks :

```js
// in talks/reducers.js
export const reducer = handleActions(
    {
        [LOAD_TALKS]: state => ({
            ...state,
            loading: true,
        }),
        [LOAD_TALKS_SUCCESS]: (state, { payload }) => ({
            ...state,
            loading: false,
            data: payload,
        }),
    },
    defaultState,
);
```

Et tout cela marche très bien. C'est plutôt malin, et pourquoi pas un peu élégant. L'utilisation des **meta** des actions permet de partager des comportements génériques au sein de l'application (le fetch, mais aussi la gestion des erreurs, la deconnexion).

> Vous pouvez trouver le code *complet* sur [GitHub](https://github.com/alexisjanvier/javascript-playground/releases/tag/cra-with-redux)

## C'est Malin, Mais c'est Surtout Très Complexe !

Pas facile de s'y retrouver en arrivant sur l'application tant un certain nombre de comportements relèvent de la *magie*. Car si on récapitule, on obtient les données des talks via une saga branchée sur le routeur qui envoi une action de type fetch interceptée par une autre saga générique qui en cas de succès émet une autre action, action interceptée par le reduceur de la page ayant émis la toute première action de la chaine ...  
Certains dirons peut-être qu'il s'agit ici d'une utilisation *hors des cloues de Redux*, mais c'est surtout le résultat de plusieurs projets réalisés sur cette stack, avec l'expérience d'écritures répetitives d'actions et de reducers.

Se rajoute à  cette complexité une *plomberie* non négligeable, c'est à dire beaucoup de fichiers répétés pour chaque feature (les actions, les reducers et autres sagas).

Analysons l'application d'exemple avec ses trois pages, sa home et sa page de login :

 ```bash
 ❯ cloc services/cra_webapp/src
      32 text files.
      32 unique files.
       0 files ignored.

github.com/AlDanial/cloc v 1.74  T=0.06 s (581.6 files/s, 17722.1 lines/s)
-------------------------------------------------------------------------------
Language                     files          blank        comment           code
-------------------------------------------------------------------------------
JavaScript                      31            150              1            819
CSS                              1              0              0              5
-------------------------------------------------------------------------------
SUM:                            32            150              1            824
-------------------------------------------------------------------------------
 ```

**31 fichiers, 819 lignes de code**, c'est déja beaucoup pour une application très simple. Le code pourrait sûrement être simplifié un peu mais au risque de le rendre moins générique.

**C'est certainement le moment de se poser la question de savoir si Redux est ici bien nécessaire ?**

> Redux is a predictable state container for JavaScript apps.

Différentes parties de l'application doivent-elles modifier les mêmes données, nécessitant de maintenir un état prédictible de nos données ? Non, on doit juste afficher des données provenant de l'API.  
A-t-on des composants enfouis dans le DOM dont l'interaction induit une modification des données ? Non plus.

On doit donc sûrement pouvoir se passer de Redux.

## Obtenir les Données Sans Redux

Ou plutôt sans utiliser **Redux-Saga**, chargé de rendre disponibles les données nécessaires à l'affichage de nos pages au niveau du **store** de Redux depuis l'API. On pourrait implémenter toute la logique de fetch au niveau de chaque page. Mais ce serait dupliquer une mécanique très répétitive. Il faut donc trouver une manière générique de réaliser ce fetch sans introduire trop de complexité.  
Et la pattern de [**render prop**](https://cdb.reacttraining.com/use-a-render-prop-50de598f11ce) est particulièrement adaptée à cela !

Nous allons créer un composant `DataProvider` :

```javascript
// in DataProvider.js
import React, { Component, Fragment } from 'react';
import { Redirect } from 'react-router';
import { appFetch } from './services/fetch';

export class DataProvider extends Component {
    static propTypes = {
        render: PropTypes.func.isRequired,
        url: PropTypes.string.isRequired,
    };

    state = {
        data: undefined,
        error: undefined,
    };

    fetchData = async props => {
        const token = window.sessionStorage.getItem('token');
        try {
            const data = await appFetch({ url }, token);
            this.setState({
                data: data.response,
                error: null,
            });
        } catch (error) {
            this.setState({
                error,
            });
        }
    };

    componentDidMount() {
        return this.fetchData(this.props);
    }

    render() {
        const { data, error } = this.state;
        const { location } = this.props;

        if (error) {
            return error.code >= 401 && error.code <= 403 ? (
                <Redirect to="/login" />
            ) : (
                <p>Erreur lors du chargement des données</p>
            );
        }


        return (
            <Fragment>
                {data ? (
                    <p>Aucune donnée disponible</p>
                ) : (
                    this.props.render({
                        data,
                    })
                )}
            </Fragment>
        );
    }
}
```

Ce composant réalise un fetch sur l'url qui lui est passé en prop au `componentDidMount`. Il va se charger de la gestion des erreurs et de l'absence de donnée. Et si il obtient des données, il *passe le main* à la fonction qui lui est donnée en prop `render` pour réaliser l'affichage `this.props.render({ data })`.

Implémentons ce composant sur notre page de talks :

```javascript
// in talks/Talks.js
import React from 'react';
import PropTypes from 'prop-types';

import { DataProvider } from '../DataProvider';

export const TalksView = ({ talks }) => (
    <div>
        <h1>Talks</h1>
        {talks && talks.map(talk => <h2 key={talk.id}>{talk.title}</h2>)}
    </div>
);

TalksView.propTypes = {
    talks: PropTypes.array,
};

export const Talks = () => (
    <DataProvider
        url="/talks"
        render={({ data }) => <TalksView talks={data} />}
    />
);

```

On a deux composants :

* le composant `TalksView` qui ne se charge que de l'affichage de données, peu lui importe d'ou elles proviennent,
* le composant `Talks` utilisant le `DataProvider` pour obtenir les données et `TalksView` pour l'     afficher `render={({ data }) => <TalksView talks={data} />}`.

C'est simple, efficace et lisible !

> Il existe une excellente librairie reprenant ce principe de data provider : [react-request: Declarative HTTP requests for React](https://github.com/jamesplease/react-request)

Sur cette base, nous pouvons supprimer Redux de notre application.

<iframe src="https://codesandbox.io/embed/o77qv75rmq?module=%2Fsrc%2FApp.js&view=editor" style="width:100%; height:500px; border:0; border-radius: 4px; overflow:hidden;" sandbox="allow-modals allow-forms allow-popups allow-scripts allow-same-origin"></iframe>

Relançons l'analyse de notre projet :

```bash
❯ cloc services/cra_webapp/src
      16 text files.
      16 unique files.
       0 files ignored.

github.com/AlDanial/cloc v 1.74  T=0.04 s (418.9 files/s, 13404.6 lines/s)
-------------------------------------------------------------------------------
Language                     files          blank        comment           code
-------------------------------------------------------------------------------
JavaScript                      15             64              1            442
CSS                              1              0              0              5
-------------------------------------------------------------------------------
SUM:                            16             64              1            447
-------------------------------------------------------------------------------
```

Nous sommes donc passés de 819 lignes de code à **442 lignes**, presque moitié moins. Pas mal !

## Se Passer du Store de Redux

En l'état, on obtient les données pour chaque page grâce au DataProvider. Mais notre application requière une authentification permettant d'obtenir les informations sur l'utilisateur via un **json-web-token**.  
Comment va-t-on pouvoir transmettre ces informations sur l'utilisateur aux différents composants sans le store Redux ?  
Et bien en utilisant le **state** de notre composant de plus haut niveau, le `App.js` et en transmettant le `user` comme une **prop** aux composants enfants qui en ont besoin (`PrivateRoute.js`, `Header.js`).

Bref, en faisant du React !

```javascript
// in App.js
import React, { Component } from 'react';
import { BrowserRouter as Router, Route, Switch } from 'react-router-dom';

import { Authentication } from './authentication/Authentication';
import { Header } from './components/Header';
import { PrivateRoute } from './PrivateRoute';
import { Talks } from './talks/Talks';


export class App extends Component {
    state = {
        user: null,
    };

    decodeToken = token => {
        const user = decode(token);
        this.setState({ user });
    };

    componentWillMount() {
        const token = window.sessionStorage.getItem('token');

        if (token) {
            this.decodeToken(token);
        }
    }

    handleNewToken = token => {
        window.sessionStorage.setItem('token', token);
        this.decodeToken(token);
    };

    handleLogout = () => {
        window.sessionStorage.removeItem('token');
        this.setState({ user: null });
    };

    render() {
        const { user } = this.state;
        return (
            <Router>
                <div>
                    <Header user={user} onLogout={this.handleLogout} />
                    <Switch>
                        <PrivateRoute
                            path="/talks"
                            render={() => (
                                <Talks />
                            )}
                            user={user}
                        />
                        <Route
                            path="/login"
                            render={({ location }) => (
                                <Authentication
                                    location={location}
                                    onNewToken={this.handleNewToken}
                                />
                            )}
                        />
                    </Switch>
                </div>
            </Router>
        );
    }
}

```

> C'est vrai, stocker le `token` dans le `window.sessionStorage` est une [**mauvaise pratique**](https://www.rdegges.com/2018/please-stop-using-local-storage/). Mais cela permet pour notre exemple de rapidement mettre en place l'authentification. Cela n'a rien à voir avec la suppression de Redux.

```javascript
// in PrivateRoute.js
import React from 'react';
import PropTypes from 'prop-types';
import { Redirect, Route } from 'react-router';

/**
 * This Route will redirect the user to the login page if needed.
 */
export const PrivateRoute = ({ user, ...rest }) =>
    user ? (
        <Route {...rest} />
    ) : (
        <Redirect
            to={{
                pathname: '/login',
                state: { from: rest.location },
            }}
        />
    );

PrivateRoute.propTypes = {
    user: PropTypes.object,
};
```

```javascript
// in components/Header.js
import React from 'react';
import PropTypes from 'prop-types';

import { Navigation } from './Navigation';

export const Header = ({ user, onLogout }) => (
    <header>
        <h1>JavaScript Playground: meetups</h1>
        {user && <Navigation onLogout={onLogout} />}
    </header>
);

Header.propTypes = {
    user: PropTypes.object,
    onLogout: PropTypes.func.isRequired,
};

```

L'application étant très simple, le passage du `user` en **prop** aux enfants n'est pas problématique. Le composant `Header` fait sans doute un peu le *passe-plat* mais ce n'est pas très pénalisant.

Qu'en est-il pour une application plus conséquente ? Cela peut devenir très pénible. C'est d'ailleur un des cas ou il devient légitime de se poser la question de l'utilisation de Redux !

Mais avant cela, il existe maintenant une solution très simple permettant de transmettre des informations depuis un composant vers un autre composant plus profond du DOM : le [**Context**](https://reactjs.org/docs/context.html) de React.

### React Context

La méthode `React.createContext` va nous permettre de générer un :

* `Provider` chargé de *distribuer* la donnée,
* `Consumer` qui sera capable de lire la donnée du provider.

> On peut noter au passage que le `Consumer` utilise la pattern de **render prop**.

Reprenons nos trois composants précédents.

```javascript
// in App.js
import React, { Component } from 'react';
import { BrowserRouter as Router, Route, Switch } from 'react-router-dom';
import styled from 'styled-components';
import { decode } from 'jsonwebtoken';

...

export const UserContext = React.createContext({
    user: null,
    onLogout: () => true,
});

export class App extends Component {
    ...

    render() {
        const { user } = this.state;
        return (
            <UserContext.Provider
                value={{
                    user,
                    onLogout: this.handleLogout,
                }}
            >
                <Router>
                    <Container>
                        <Header />
                        <Switch>
                            <PrivateRoute
                                exact
                                path="/"
                                render={({ location }) => (
                                    <Home location={location} />
                                )}
                            />
                        ...
```

```javascript
// in PrivateRoute.js
import React from 'react';
import PropTypes from 'prop-types';
import { Redirect, Route } from 'react-router';

import { UserContext } from './App';

const PrivateRouteWithoutContext = ({ user, ...rest }) =>
    user ? (
        <Route {...rest} />
    ) : (
        <Redirect
            to={{
                pathname: '/login',
                state: { from: rest.location },
            }}
        />
    );

PrivateRouteWithoutContext.propTypes = {
    user: PropTypes.object,
};

export const PrivateRoute = props => {
    return (
        <UserContext.Consumer>
            {({ user }) => (
                <PrivateRouteWithoutContext user={user} {...props} />
            )}
        </UserContext.Consumer>
    );
};

```

```javascript
// in components/Header.js
import React from 'react';
import PropTypes from 'prop-types';

import { UserContext } from '../App';
import { Navigation } from './Navigation';

export const HeaderWithoutContext = ({ user, onLogout }) => (
    <header>
        <h1>JavaScript Playground: meetups</h1>
        {user && <Navigation onLogout={onLogout} />}
    </header>
);

HeaderWithoutContext.propTypes = {
    user: PropTypes.object,
    onLogout: PropTypes.func.isRequired,
};

export const Header = () => {
    return (
        <UserContext.Consumer>
            {({ user, onLogout }) => (
                <HeaderWithoutContext user={user} onLogout={onLogout} />
            )}
        </UserContext.Consumer>
    );
};
```

Le **Context** de React est un moyen simple de *télétransporter* directement de la donnée d'un composant *N* de l'application à n'importe quel composant enfant *N-x*.

## Alors, Avec ou Sans Redux ?

Redux devient intéressant dès lors qu’un projet atteint un certain niveau de complexité. Mais par expérience, c’est rarement une bonne idée que de préjuger du degré d’intrication de son projet ! Et je préfère de loin garder les choses simples à me dire dès le début : «*Chouette, je vais faire un truc hyper compliqué*». Cela me rappelle il y a quelques années où pour démarrer un projet en Php, on utilisait systématiquement Symfony alors que Silex permettait de démarrer beaucoup plus simplement et rapidement.  

Il n’en reste pas moins que tout comme Symfony, l’utilisation de Redux peut devenir un choix très judicieux.  **C’est juste qu’il est prématuré de prendre cette décision au démarrage du projet.**

Ce n'est d'ailleurs pas une nouveauté 😄

<blockquote class="twitter-tweet" data-lang="fr"><p lang="en" dir="ltr">You Might Not Need Redux.</p>&mdash; Dan Abramov (@dan_abramov) <a href="https://twitter.com/dan_abramov/status/777983404914671616">19 septembre 2016</a></blockquote>
<script async src="https://platform.twitter.com/widgets.js" charset="utf-8"></script>

Au delà de ces considérations un peu théoriques, il me semble aussi qu’il existe des effets bénéfiques au fait de ce passer de Redux.

En premier lieu, on se concentre plus sur React ! En codant le second exemple de ce post, j’ai retrouvé le plaisir de construire une application uniquement à partir de briques de composants : c’est comme de jouer aux Lego. L’utilisation des **render prop** permet la re-utilisation de code au sein du projet tout en conservant cette logique d’imbrication de composants de React. C’est un pattern puissant, moins magique que les [HOC](https://reactjs.org/docs/higher-order-components.html), qui pourra le moment venu s’adapter à l’éventuelle implémentation de Redux. J’en veux pour preuve [react-admin 2.0](https://marmelab.com/blog/2018/05/18/react-admin-2-0.html) qui dissocie complètement [la partie UI](https://github.com/marmelab/react-admin/tree/master/packages/ra-ui-materialui) de [la logique applicative](https://github.com/marmelab/react-admin/tree/master/packages/ra-core) grâce aux render props.

Enfin, cela semble l’orientation prise par l’équipe de React qui avec la nouvelle version de l’API Context offre la possibilité de mettre en place un store global facilement partageable sans adopter Redux.
