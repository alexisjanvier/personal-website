+++
title="Managing State in React: Redux or not Redux?"
slug="managing-state-in-react-redux-or-not-redux"
marmelab="https://marmelab.com/blog/2018/06/27/redux-or-not-redux.html"
date = 2018-06-27
description="Redux is a fantastic tool for managing state in React.js, but is it suitable for all situations? Probably not."
tags = ["react"]
+++

At Marmelab we really like to manage the state of React apps using [Redux](https://redux.js.org/). Its emergence has transformed the way we code our applications: immutability, functional programming, asynchronous API call management with Redux-Saga generators... So much that we sometimes tend to "de facto" integrate Redux into our project start stack.  
But is that a good idea? Not sure...

## An Example: Managing Meetups With React

Let's take a straightforward meetup management application. It should be able to display:

* a list of proposals,
* a wish list of talks,
* a list of meetup members.

The data comes from a REST API. A login/password protects both the application and the API.

The application is bootstrapped with [Create React App](https://github.com/facebook/create-react-app) and upgraded with:

* [Redux](https://redux.js.org/)
* [Redux-Saga](https://redux-saga.js.org/)
* [react-router-redux](https://github.com/reactjs/react-router-redux)

This is what the project looks like:

<iframe src="https://codesandbox.io/embed/m5n2xjl6pj?fontsize=12&module=%2Fsrc%2FApp.js&view=editor" style="width:100%; height:500px; border:0; border-radius: 4px; overflow:hidden;" sandbox="allow-modals allow-forms allow-popups allow-scripts allow-same-origin"></iframe>

The application reflects the typical redux architecture. It starts with an `<App />` component that mounts the redux store (`<Provider store={store}>`) and the router (`<ConnectedRouter history={history}>`):

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

Redux users will be comfortable with the file structure that I chose. I grouped all the code related to a feature into a directory. An example with the `talks` page:

``` bash
├── talks
│   ├── actions.js
│   ├── reducer.js
│   ├── sagas.js
│   └── Talks.js
 ```

The `<Talks>` page component is a straightforward "connected component":

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
    isLoading: talks.isLoading,
    talks: talks.data,
});

// passing {} as the second's connect argument prevents it to pass dispatch as prop
const mapDispatchToProps = {};

export default connect(mapStateToProps, mapDispatchToProps)(Talks);
```

The data for the talks is not fetched on `componentWillMount`, but through a saga listening to route changes:

```js
// in talks/sagas.js
import { put, select, takeLatest } from 'redux-saga/effects';
import { LOCATION_CHANGE } from 'react-router-redux';

import { loadTalks } from './actions';

const hasData = ({ talks }) => !!talks.data;

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

When the route changes and corresponds to the talks section (`action.type === LOCATION_CHANGE && action.payload.pathname === '/talks'`), my application triggers an action with the `loadTalks` function:

```js
// in talks/actions.js
export const LOAD_TALKS = 'LOAD_TALKS';

export const loadTalks = payload => ({
    type: 'LOAD_TALKS',
    payload,
    meta: {
        request: {
            url: '/talks',
        },
    },
});
```

This action, containing the url to get data for talks inside its **meta**, will be intercepted by a generic fetch **saga** `action => !!action.meta && action.meta.request`:

```js
// in /services/fetch/fetchSagas.js
import { call, put, takeEvery, select } from 'redux-saga/effects';

import { appFetch as fetch } from './fetch';

export const fetchError = (type, error) => ({
    type: `${type}_ERROR`,
    payload: error,
    meta: {
        disconnect: error.code === 401,
    },
});

export const fetchSuccess = (type, response) => ({
    type: `${type}_SUCCESS`,
    payload: response,
});

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

Once the fetch is successful, the saga triggers a final action indicating the success of the data recovery (`createAction('${type}_SUCCESS')(response)`). This action is used by the talks **reducer**:

```js
// in talks/reducers.js
export const reducer = (state = defaultState, action) => {
    switch (action.type) {
        case LOAD_TALKS:
            return {
                ...state,
                loading: true,
            };
        case LOAD_TALKS_ERROR:
            return {
                ...state,
                loading: false,
                error: action.payload,
            };
        case LOAD_TALKS_SUCCESS:
            return {
                ...state,
                loading: false,
                data: action.payload,
            };
        case LOGOUT:
            return defaultState;
        default:
            return state;
    }
};
```

It works well. That's pretty smart, even elegant! The use of action's **meta** allows sharing generic behaviours within the application (data fetching but also error handling or logout).

## It's Smart, But It's Complex

It's not easy to find your way around when you discover the application, some behaviours are so magical. To summarize, the app fetch the data with a redux-saga connected to the router, which sends a fetch action intercepted by another generic saga, which in case of success emits another action, action intercepted by the reducer of the page having emitted the very first action of the chain...

Some might say that it's an abusive use of redux, but it's mostly the result of several projects done on this stack, with the experience of rewriting actions and reducers.

Added to this complexity, there is also a significant amount of *plumbing*, i.e. many files repeated for each feature (actions, reducers and other sagas).

Let's analyse the example application with its three pages, its home and its login page:

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

**31 files, 819 lines of code**, it's already a lot for a straightforward application. This code could be simplified a little bit, with the risk of making it less generic.

**It's certainly time to ask ourselves if Redux is necessary here?**

> Redux is a predictable state container for JavaScript apps.

But do different parts of the application modify the same data, requiring a predictable state for this data? No, I just need to display data from the API. Are there components buried in the DOM that can modify the data? No, user interactions are pretty limited.

So I probably don't need Redux.

## Fetching Data Without Redux

Let's try fetching data without Redux, or more precisely without **Redux-Saga** (since it is not directly redux' job to perform the data fetching). I could implement all this fetch logic on each page. However, that would be setting up very repetitive mechanics and a lot of duplicated code. So I have to find a generic way to fetch data from the API without introducing too much duplication and complexity.  

The [**render prop**](https://cdb.reacttraining.com/use-a-render-prop-50de598f11ce) pattern is an excellent candidate for this kind of problem!

Let's create a `DataProvider` component:

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

This component fetches data from the prop `url` during the `componentDidMount`. It manages error and missing data. If it gets data, it delegates the rendering to the function passed as `render` prop (`this.props.render({ data })`).  

Let's implement this component on the talk page:

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

I now have two components:

* the `TalksView` component, that only displays data, no matter where it comes from,
* the `Talks` component, using the `DataProvider` to get the data and `TalksView` to display it `render={({ data }) => <TalksView talks={data} />}`.

It's simple, effective and readable!

<div class="tips">
There is an excellent library implementing this type of DataProvider : <a href="https://github.com/jamesplease/react-request">react-request: Declarative HTTP requests for React</a>
</div>

I am now ready to remove Redux from the application.

<iframe src="https://codesandbox.io/embed/o77qv75rmq?module=%2Fsrc%2FApp.js&view=editor" style="width:100%; height:500px; border:0; border-radius: 4px; overflow:hidden;" sandbox="allow-modals allow-forms allow-popups allow-scripts allow-same-origin"></iframe>

Let's relaunch the analysis of our project:

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

So I went from 819 lines of code to **442 lines**, almost half as much. Not bad!

## Replacing The Redux Store By React State

In the current state, each page gets data using the DataProvider. However, my application requires authentication to obtain user information through a **json-web-token**.  

How will this user information be transmitted to the individual components without the Redux store? Well, by using the **state** of the higher level component (`App.js`), and passing the `user` as a prop to the child components that need it (`PrivateRoute.js`, `Header.js`).

**In short, let's make React code again!**

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

**Note**: I know: storing the `token` in `window.sessionStorage` is a [**bad practice**](https://www.rdegges.com/2018/please-stop-using-local-storage/). But this allows me to quickly set up authentication for the sake of this example. This has nothing to do with the removal of Redux.

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

My application being relatively simple, the transmission of the `user` as a **prop** to the children is not really a problem.

Let's say I want to make my navigation bar prettier, with a real logout menu displaying the user's name. I'll have to pass this `user` to the `Navigation` component.

```javascript
<Navigation onLogout={onLogout} user={user}/>
```

Moreover, if the `<UserMenu>` component uses another component to display the user, I'll have to transmit my user again:

```javascript
const UserMenu = ({ onLogout, user }) => {
    <div>
        <DisplayUser user={user} />
        <UserSubMenu onLogout={onLogout} />
    </div>
}
```

The `user` has been passed through 4 components before being displayed...

What about a more complex and/or heavier application? This can become very painful. It's one of the situations where it becomes legitimate to ask the question of the use of Redux!

However, there is now a straightforward solution to transmit data from one component to others that are deeper in the React tree: the [**React Context**](https://reactjs.org/docs/context.html).

### Passing The State Down Using React Context

The `React.createContext` method generates two components:

```javascript
const {Provider, Consumer} = React.createContext(defaultValue);
```

* a `Provider` responsible for *distributing* the data,
* a `Consumer` that's able to read the provider data.

Let's go back to the three previous components.

```javascript
// in App.js
import React, { Component } from 'react';
import { BrowserRouter as Router, Route, Switch } from 'react-router-dom';
import styled from 'styled-components';
import { decode } from 'jsonwebtoken';

...

const UserContext = React.createContext({
    user: null,
    onLogout: () => true,
});

export const UserConsumer = UserContext.Consumer;
const UserProvider = UserContext.Provider;

export class App extends Component {
    ...

    render() {
        const { user } = this.state;
        return (
            <UserProvider
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

import { UserConsumer } from './App';

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
        <UserConsumer>
            {({ user }) => (
                <PrivateRouteWithoutContext user={user} {...props} />
            )}
        </UserConsumer>
    );
};

```

<div class="tips">
Note that the <code>Consumer</code> uses the <strong>render prop</strong> pattern.
</div>


```javascript
// in components/Header.js
import React from 'react';
import PropTypes from 'prop-types';

import { UserConsumer } from '../App';
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
        <UserConsumer>
            {({ user, onLogout }) => (
                <HeaderWithoutContext user={user} onLogout={onLogout} />
            )}
        </UserConsumer>
    );
};
```

React Context is a simple way to *teleport* data directly from a level N component of the application to any level N-x children component.

## So, Redux or Not Redux ?

Redux becomes interesting as soon as a project reaches a certain level of complexity. However, it's rarely a good idea to prejudge the degree of complexity of your code! I prefer to keep things simple to say to myself: "*Great! I'm going to make something complex*" afterwards. It reminds me of a few years ago, when Symfony was systematically used to start a PHP project, while Silex made it much more comfortable and faster to get started.  

Nevertheless, just like Symfony, using Redux can become a very wise choice.  
**Using it at the beginning of the project is just a premature decision.**

It's not really fresh news 😄

<blockquote class="twitter-tweet" data-lang="fr"><p lang="en" dir="ltr">You Might Not Need Redux.</p>&mdash; Dan Abramov (@dan_abramov) <a href="https://twitter.com/dan_abramov/status/777983404914671616">19 septembre 2016</a></blockquote>
<script async src="https://platform.twitter.com/widgets.js" charset="utf-8"></script>

Also, beyond these somewhat theoretical considerations, it seems that there are also beneficial effects to the fact of going away from Redux.

First, I focus more on React! By coding the second example in this post, I rediscovered the pleasure of building an application only from bricks of components: it's like playing Lego. The use of **render prop** allows code re-use throughout the project while maintaining this logic of nesting React components. It is a powerful pattern, less magical than the [HOC](https://reactjs.org/docs/higher-order-components.html).  Furthermore, it will adapt to the possible implementation of Redux when the time comes. The proof of this is [react-admin 2.0](https://marmelab.com/blog/2018/05/18/react-admin-2-0.html) which dissociate the [UI part](https://github.com/marmelab/react-admin/tree/master/packages/ra-ui-materialui) from the [application logic](https://github.com/marmelab/react-admin/tree/master/packages/ra-core), thanks to a render prop.

Finally, this seems the direction taken by the React team. With the new **Context API**, they offer the possibility to set up a global store easily shareable without adopting Redux.
