OAuth.io - Node.js SDK
======================

OAuth that just works !
This SDK eases the integration of OAuth.io's services on a Node.js backend.

Features
--------

- Server-side OAuth authentication flow
- Requests to API from the backend, including the unified "me" method
- Unified user information requests for available providers from the backend
- Access token renewal with the refresh_token when available

With this SDK, your OAuth flow is also more secure as the oauth token never
leaves your backend.

Common use-case
---------------
You don't want to use APIs directly from the front-end, but rather through web-services inside your Node.js backend.



The server-side flow
--------------------

In the server-side OAuth authentication flow, the oauth token never leaves your backend.

To authenticate a user, the flow follows these steps :

- Ask for a state token to the backend. This token will be used to communicate with oauth.io
- Show a popup or redirect your user to request his permission to use his/her account on the requested provider
- The latter gives you a code, that you give to your backend
- The backend sends the code to oauth.io with other information like the oauth.io app's public key and secret.
- oauth.io responds with the access_token, that you can then store on your backend as long as it's valid.
- You can then make requests to the API using that access token, directly from your backend.

Getting Started Tutorial
-------------------

**Installation**

You just need to configure the provider OAuth.io as a server-side OAuth flow, install the front-end SDK to help you handle the popup/redirect, and install this SDK on your server.

**1. Configuring the provider on oauth.io**

The first thing you need to do is to create an account (if you don't have one yet) on [oauth.io](https://oauth.io), create an app in the [key-manager](https://oauth.io/key-manager) and add a provider to that app.

You'll have to go on the provider's website to register a new app, and copy its keys on oauth.io.

**2. Using the Nodejs SDK**

Here I'll assume you're using Expressjs or Restify to create web-services
on your server. You need a per user session system, and both provide one that
respect approximately the same interface.

They store their session in the req object, which is passed as an argument to
every endpoint callback, like the following :

```JavaScript
var app = express();

//Here's an endpoint that says hello
app.get('/my/endpoint', function (req, res) {
    
    //Here you can use the session :
    req.session.firstname = req.body.firstname || req.session.firstname;
    
    res.send(200, 'Hello, ' + req.session.firstname + ' !');
});

app.listen(process.env.MY_APP_PORT || 3000);
```

**Installation**

To install the SDK, run the following command in the folder of your Nodejs app :

```bash
myapp/folder$ npm install oauthio
```

Whenever you need to use the SDK, you can require it from one of your modules like this :

```JavaScript
var OAuth = require('oauthio');
```

**Initializing the SDK**

The first thing you need to do is to initialize the SDK with your OAuth.io's app's key and secret.

You can get these pieces of information from the [Key-manager][2] in oauth.io.

You can call the initialize method right after you initialized your express/restify app and included your middlewares :

```JavaScript
OAuth.initialize('your_app_key', 'your_app_secret');
```

**Publishing an endpoint to give state tokens**

You need to create an endpoint on your server so that the front-end can get a state token that will be stored server side, and used to communicate with oauth.io.

Every time you'll call this endpoint, a new token will be generated and stored.

Let's say your endpoint will be on /oauth/state_token :

```JavaScript
app.get('/oauth/state_token', function (req, res) {
    var token = OAuth.generateStateToken(req.session);
    
    res.send(200, {
        token:token
    });
});
```

**Authentication**

The SDK gives you an `auth` method that allows you to retrieve a `request_object`. That `request_object` allows you to make API calls, and contains the access token.

The `auth` method takes :

1. a provider name
2. the session array
3. (optional) an options object

It returns a promise to let you handle the callback and error management.

```
OAuth.auth('provider', req.session, {
    option_field: option_value,
    //...
});
```

The options object can contain the following fields :

- code: an OAuth code, that will be used to get credentials from the provider and build a request_object
- credentials: a credentials object, that will be used to rebuild a refreshed request_object
- force_refresh: forces the credentials refresh if a refresh token is available

If nothing is given in the options object, the auth method tries to build a request_object from the session.

*Authenticating the user for the first time*

When you launch the authentication flow from the front-end (that is to say when you show a popup to the user so that he can allow your app to use his/her data), you'll be given a code (see next section, "Integrating the front-end SDK" to learn how to get the code).

You'll have to give this code to your backend, so that it can retrieve an access token from oauth.io.

To do that, you have to create an authentication endpoint on your backend. This endpoint will make the access token request to oauth.io. You can use the same endpoint to perform local login/subscribe actions too.

```JavaScript
app.post('/api/signin', function (req, res) {
    var code = JSON.parse(req.body).code;

    // Here the auth method takes the field 'code'
    // in its options object. It will thus use that code
    // to retrieve credentials from the provider.
    OAuth.auth('facebook', req.session, {
        code: code
    })
    .then(function (request_object) {
        // request_object contains the access_token if OAuth 2.0
        // or the couple oauth_token,oauth_token_secret if OAuth 1.0
        
        // request_object also contains methods get|post|patch|put|delete|me
        return request_object.get('/me');
    })
    .then(function (info) {
        var user = {
            email: info.email,
            firstname: info.first_name,
            lastname: info.last_name
        };
        //login your user here.
        res.send(200, 'Successfully logged in');
    })
    .fail(function (e) {
        //handle errors here
        res.send(400, 'An error occured');
    });
});
```

*Authenticating a user from the session*

Once a user is authenticaded on a service, the credentials are stored
in the session. You can access it very easily from any other endpoint to use it. Let's say for example that you want to post something on your user's wall on Facebook :

```JavaScript
app.post('/api/wall_message', function (req, res){
    var data = JSON.parse(req.body);
    //data contains field "message", containing the message to post
    
    OAuth.auth('facebook', req.session)
        .then(function (request_object) {
            return request_object.post('/me/feed', {
                message: data.message
            });
        })
        .then(function (r) {
            //r contains Facebook's response, normaly an id
            if (r.id)
                res.send(200, 'Successfully posted message');
            else
                res.send(400, 'An error occured while posting the message');
        })
        .fail(function (e) {
            res.send(400, 'An error occured while posting the message');
        });
});
```

*Authenticating a user from saved credentials*

* Saving credentials
If you want to save the credentials to use them when the user is offline, (e.g. in a cron loading information), you can save the credentials in the data storage of your choice. All you need to do is to retrieve the credentials object from the request_object : 

```javascript
OAuth.auth('provider', req.session, {
    code: code
})
    .then(function (request_object) {
        var credentials = request_object->getCredentials();

        // Here you can save the credentials object wherever you want

    });
```

* Using saved credentials

You can then rebuild a request_object from the credentials you saved earlier :
```javascript
// Here you retrieved the credentials object from your data storage

OAuth.auth('provider', req.session, {
    credentials: credentials
})
    .then(function (request_object) {
        // Here request_object has been rebuilt from the credentials object
        // If the credentials are expired and contain a refresh token,
        // the auth method automatically refresh them.
    });

```

*Refreshing saved credentials*

Tokens are automatically refreshed when you use the `auth` method with the session or with saved credentials. The SDK checks that the access token is expired whenever it's called.

If it is, and if a refresh token is available in the credentials (you may have to configure the OAuth.io app in a specific way for some providers), it automatically calls the OAuth.io refresh token endpoint.

If you want to force a refresh from the `auth` method, you can pass the `force_refresh` field in the option object, like this :

```javascript
OAuth.auth('provider', req.session, {
    force_refresh: true
});
```

You can also refresh a credentials object manually. To do that, call the OAuth.refreshCredentials on the request_object or on a credentials object :

```javascript
OAuth.refreshCredentials(request_object, req.session)
    .then(function (request_object) {
        // Here request_object has been refreshed
    })
    .fail(function (e) {
        // Handle an error
    });
```

**3. Integrating Front-end SDK**

This SDK is available on our website : [Get it on oauth.io][1].

To install it, place a script tag pointing to it in your html page :


```html
<!DOCTYPE html>
<html>
    <head>
        <title>My Website</title>
        ...
        <script src="path/to/oauth.js"></script>
        ...
    </head>
    <body>
    ...
    </body>
</html>
```

**Initializing the front-end SDK**

To initialize the front-end SDK, you just need to do :

```JavaScript
OAuth.initialize('your_app_key');
```

The public key is available on your [Key manager on oauth.io][2].

**Getting the state token**

Now what you need to do first is to call the state token endpoint to get a token to communicate with oauth.io.

I'll assume you're using jQuery to perform the ajax calls.

```javascript
var state = '';
$.ajax({
    url: '/oauth/state_token',
    method: 'GET',
    success: function (data, status) {
        state = data.token;
    }
});
```

**Using the front-end SDK for authentication**
Once you've retrieved the state token and stored it in the `state` variable, you can perform the authentication.

What happens here is that we're going to call OAuth.io for a provider (which must be already configured on the [key-manager](https://oauth.io/key-manager), in the initialized app, with the *server-side* option flow selected).

OAuth.io will answer with a code that we're going to give to our backend through our `/api/signin` endpoint we created earlier. That endpoint will perform the authentication and retrieve the access_token from the provider, thanks to that code.

The front-end SDK lets you use a popup method for authentication :

```JavaScript
OAuth.popup('facebook', {
        state: state // the previously retrieved state token (see above)
    })
    .done(function (r) {
        //r.code is to be sent to your backend's authentication endpoint :
        $.ajax({
            url: '/api/signin',
            data: {
                code: code
            }
        })
            .done(function (data, status) {
                //Your user is authenticated here !
                //You can now call other endpoints that use the requests
                //to retrieve data from the provider.
            })
            .fail(function (error) {
                //handle the error
            });
    })
    .fail(function (e) {
        //handle the error
    });
```


Detailed documentation
----------------------

This part lists and describes all the available methods in this SDK.

**OAuth object**

Available methods :

*Version information*

```JavaScript
OAuth.getVersion();
```

Returns the version of the SDK.

*Initialization*

```JavaScript
OAuth.initialize('app_key', 'app_secret');
```

Initializes the SDK by storing your app key and secret inside its cache.

*State token generation*
```JavaScript
var token = OAuth.generateStateToken(req);
```
Returns a token and stores it in the session.

*Authentication*

```JavaScript
var promise = OAuth.auth(code, req);
```

Retrieves the access token from oauth.io by sending the code, which was sent by the front-end.

Returns a promise, that you can use like this :

```JavaScript
promise.then(success_callback).fail(error_callback);
```

`success_callback` takes the authentication object as argument, `error_callback` takes an error as argument.

*Getting a user's authentication object for a given provider*

```JavaScript
var authentication_object = OAuth.create(req, 'provider_name')
```

This returns an authentication object for the current user and the given provider.

**Authentication object**

The authentication object refers to what is returned by the `auth` and `create` methods.

It contains the following :

```Javascript
auth_obj.access_token // if the provider implements OAuth 2.0
```

```Javascript
auth_obj.oauth_token // if the provider implements OAuth 1.0
auth_obj.oauth_token_secret // if the provider implements OAuth 1.0
```

```Javascript
auth_obj.expires_in //the number of seconds to token expiration
```

**Requests methods in the authentication object**

*get*

```Javascript
var promise = auth_obj.get(url);
```
Returns a promise, and performs a GET request to the API. Use the promise like this :

```Javascript
promise.then(function (r) {
    //r is the API's response
})
.fail(function (e) {
    //handle the error
});
```
*post*

```Javascript
var promise = auth_obj.post(url, data)
```

Returns a promise and performs a POST request to the API. You can add a body to the request as the second parameter (litteral object). Use the promise like this :

```Javascript
promise.then(function (r) {
    //r is the API's response
})
.fail(function (e) {
    //handle the error
});
```

*put*

```Javascript
var promise = auth_obj.put(url, data)
```

Returns a promise and performs a PUT request to the API. You can add a body to the request as the second parameter (litteral object). Use the promise like this :

```Javascript
promise.then(function (r) {
    //r is the API's response
})
.fail(function (e) {
    //handle the error
});
```

*patch*

```Javascript
var promise = auth_obj.patch(url, data)
```

Returns a promise and performs a PATCH request to the API. You can add a body to the request as the second parameter (litteral object). Use the promise like this :

```Javascript
promise.then(function (r) {
    //r is the API's response
})
.fail(function (e) {
    //handle the error
});
```

*del*

```Javascript
var promise = auth_obj.del(url, data)
```

Returns a promise and performs a DELETE request to the API.

```Javascript
promise.then(function (r) {
    //r is the API's response
})
.fail(function (e) {
    //handle the error
});
```

*me*

```Javascript
var promise = auth_obj.me(filter)
```

This method gets a unified object representing the user. The fields' format always remain the same, regardless of the provider, so that you can handle several providers in an easier way.

You can provide a filter, which is an array of strings, containing the different fields you need. For example :

```JavaScript
var filter = ['email', 'firstname', 'lastname'];
```

Use the returned promise like this :

```Javascript
promise.then(function (r) {
    //r is the API's response
})
.fail(function (e) {
    //handle the error
});
```

Please refer to [this page][4] to know which fields are available and for more information about OAuth.io's "me" feature.


Contributing to this SDK
------------------------

**Issues**

Please discuss issues and features on Github Issues. We'll be happy to answer to your questions and improve the SDK based on your feedback.

**Pull requests**

You are welcome to fork this SDK and to make pull requests on Github. We'll review each of them, and integrate in a future release if they are relevant.

The SDK is written in Coffee Script, and uses Grunt To compile it, just run :

```sh
sdk/folder$ git clone therepo; cd therepo
sdk/folder$ npm install -g grunt-cli
sdk/folder$ npm install
sdk/folder$ grunt
```

Testing the SDK
---------------

We use jasmine-node to test the SDK. To test it, install jasmine-node 2.0 :

```bash
$ npm install -g jasmine-node@2.0
```

Then you can launch the test suite from the SDK folder :

```bash
sdk/folder$ jasmine-node tests/unit/spec --verbose
```

License
-------

The SDK is released under the Apache2 license.


Powered by [OAuth.io][3].

[1]: https://oauth.io/docs
[2]: https://oauth.io/key-manager
[3]: https://oauth.io
[4]: https://oauth.io/docs/me