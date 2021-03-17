+++
title="Mocking an API with Polly.js"
slug="mocking-an-api-with-pollyjs"
marmelab="https://marmelab.com/blog/2020/01/23/mocking-an-api-with-pollyjs.html"
date = 2020-01-23
description="It is never easy to set up functional tests involving calls to an external API. Polly.js is a useful tool to know when you need to mock calls to an API."
tags = ["js"]
+++

We've had that problem several times: writing functional tests for an application that depends on calls to an API. 

## Using a Mock API With Fixtures

The usual and simplest solution, is to create fixtures, and set up a mock for the API, which will be in charge of returning the fixtures.

Here is a short example of API testing with [Jest](https://jestjs.io/), [supertest](https://github.com/visionmedia/supertest) and an [axios](https://github.com/axios/axios)-based API client.

Here is the system under test, which depends on an API:

```js
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

```js
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

Here is the functional test of this application, using a mock returning fixtures:

```js
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

```js
// in createRequest.js
import express from 'express';
import request from 'supertest';

export const createRequest = () => {
    const app = express();
    // The application router must be imported after the clients mocks
    const apiRouter = require('./router');
    app.use('/', apiRouter);

    return request(app);
};
```

This works fine, but it can quickly become tedious to create these fixtures, and especially to maintain them.

## Recording And Replaying API Calls With Polly.js - Initial Implementation

On one of our customer projects, we had an API that was functionally tested and dependent on two APIs. When a third API was implemented, we took the opportunity to change our mock strategy. We turned to [Polly.js](https://netflix.github.io/pollyjs/#/), a library maintained by Netflix, which allows to record all calls made to one or more APIs in `RECORD` mode, and replay them in `REPLAY` mode. It's like Jest snapshots for APIs. 

We won't focus on how to set up Polly - the project has [very good documentation](https://netflix.github.io/pollyjs/#/README) on that subject. Here is just a brief overview of our setup. As the tests concern an API written in javascript (running with [Node.js](https://nodejs.org/en/)), we used Polly's [adapter-node-http](https://www.npmjs.com/package/@pollyjs/adapter-node-http/v/1.4.1), and we chose to store the records on the filesystem of the test machine with the [persister-fs](https://www.npmjs.com/package/@pollyjs/persister-fs) adapter. The tests being managed by Jest, we also used the [setup-polly-jest](https://www.npmjs.com/package/setup-polly-jest) package.

Based on the Polly.js example, here is what the test setup looks like:

```js
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
```

We use a `POLLY_RECORD` environment variable when setting up the tests to start recording missing API calls. This environment variable will not exist on the continuous integration server. Indeed, all recordings are made during development, and the continuous integration server simply replay these recordings.

Now we can rewrite the functional test as follows:

```js
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

Polly has to be started during the tests. It is therefore logical to launch the setupPolly within a `describe`.

Polly saves its recordings (in [HTTP Archive format (.har)](https://en.wikipedia.org/wiki/HAR_(file_format)) format).

## Avoiding Directory Explosion 

Polly organizes recorded requests in directories that respect the interweaving of `describe` and `it` of tests. This is why we used the `describePolly` method in the example above. In the case of a test description in the form of an API url, it will transform the `/` into `-`. Otherwise, we end up with an infernal interweaving of directories... 

For example, for a test taking the form:

```js
describe('my test', () => {
    it('/domain/subdomain/api/object/id'), () => {
        // test
    });
});
```

We will have recordings organized in the following form:

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

Using pollyDescribe

```js
describe('my test', () => {
    it(pollyDescribe('/domain/subdomain/api/object/id')), () => {
        // test
    });
});
```

We will have recordings organized in the following structure:

```bash
.
├── my-test
│   └── domain-subdomaine-api-object-id
│       └── my-record.har
```

## Understanding The Importance Of The Request Signature

We first launched the test in record mode (`$ POLLY_RECORD=true yarn test`) and the recording went well - we could see the `.har` files in the recordings directory. But once we ran the tests in replay mode (`$ yarn test`), they failed randomly with the following error message:

```bash
PollyError: [Polly] [adapter:node-http] Recording for the following request is not found and `recordIfMissing` is `false`.
```

If the solution of this problem is simple, it took us a time to find it... It turns out Polly.js uses not only the URL to identify records, but also the port. When running in RECORD mode, if the server port changes between runs, Polly will save several records. This behavior is [configurable](https://netflix.github.io/pollyjs/#/configuration) in Polly.js, but by default, the `port` is used for the record signature. 

In addition, we use `supertest`. Without going into details of how it works, `supertest` launches a server instance each time we call the `getRequest()` function. However, to avoid the risk of opening two servers on the same port, for example if we run the tests in parallel, supertests runs the server on a random port!

This explains the instability of our tests: sometimes we are lucky and the server is launched on the same port as it was records (the test is green), sometimes not (the test is red).

It's therefore necessary to exclude the http port of records identifiers:

```js
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

Now, when run in replay mode, the tests are stable and green.

## Not Saving Confidential Data

This immersion in the documentation also drew our attention to the fact that headers may or may not be used as a record identifier.

And that's annoying, because to make calls to a real API during the record phase, we need a secret `token` transmitted through the HTTP `authorization` header!

And indeed, this is what we saw when opening our first HAR records: horror!

```json
{
  "log": {
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
            { ...  }
          ],
        },
      },
    ],
  },
}

```

There is a gotcha here, because excluding headers from the records IDs does not mean that headers are excluded from records. To really exclude them, we have to put our hands under the hood:

```js
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

Using this configuration, Polly records all http calls made during the tests, excluding any secret tokens from the records. 

## Do We Realy Want To Record API Responses?

The tests are stable. *Very* stable! In fact, **too much stable**.

We started a significant refactoring on the API, changing the signature of some responses. But the Polly.js tests for this API remained green throughout all this refactoring phase!

Incredible? No, disastrous!

> You should never trust a test that has never failed!

Indeed, we made another mistake when Polly was set up. In retrospect, it was a little bit silly. The `port` problem should have alerted us immediately! 

**We recorded the API response we wanted to test!** The tests were therefore very stable and therefore totally useless, because the API responses were frozen. Even when the API code was changed, the record of the response no longer varied.

When using Polly, the `NodeHttpAdapter` will wrap node's HTTP client, so every HTTP request made in node will call polly.js instead. During our tests, an http call is made on a server launched by `supertest` (a call on localhost). This call is therefore intercepted by Polly and thus automatically replayed instead of the real call if it exists. So even if the backend code evolves, inducing a change in the API return, we no longer see this change in the tests because this call has been recorded!

It's necessary to put your hands back under the hood to exclude calls to localhost (the http server started by `supertest` to perform the test) from records to capture only calls made by the backend to external APIs.

```js
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

Polly.js is undoubtedly a good library for recording and replaying API calls. The documentation is very clean, and it is maintained by a company that should last.

But its implementation is not without pitfalls, and therefore requires careful attention to the recordings made, even if their size makes their review not obvious on Github.

We would like such classic problems as the exclusion of some urls (especially localhost!) or the exclusion of some authentication headers to be more easily managed, for example from the configuration!

But it is also perhaps that Polly.js was not the right tool to answer our problem? While its use seems well suited to the mock of a single API, for example to test an application that uses the API like a web application, Polly is less suited when mocking multiple calls to different APIs. In this case, Polly requires a lot of configuration and hacks, with sometimes unexpected results... 

We would need a tool that is not located within the tests, but between our service and the APIs consumed. Our quest for the perfect tool continues...
