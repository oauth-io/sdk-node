OAuth.io - Node.js SDK
======================

OAuth that just works !
This SDK eases the integration of OAuth.io's services on a Node.js backend.

Features
--------

- Server-side OAuth authentication flow
- Requests to API from the backend, including the unified "me" method
- Unified user information requests for available providers from the backend

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
    var token = OAuth.generateStateToken(req);
    
    res.send(200, {
        token:token
    });
});
```

**Creating an authentication endpoint**

When you launch the authentication flow from the front-end (that is to say when you show a popup to the user so that he can allow your app to use his/her data), you'll be given a code (see next section, "Integrating the front-end SDK" to learn how to get the code).

You'll have to give this code to your backend, so that it can retrieve an access token from oauth.io.

To do that, you have to create an authentication endpoint on your backend. This endpoint will make the access token request to oauth.io. You can use the same endpoint to perform local login/subscribe actions too.

```JavaScript
app.post('/api/signin', function (req, res) {
    OAuth.auth(JSON.parse(req.body).code, req)
    .then(function (result) {
        //result contains the access_token if OAuth 2.0
        //or the couple oauth_token,oauth_token_secret if OAuth 1.0
        
        //result also contains methods get|post|patch|put|delete|me
        result.get('/me')
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
                res.send(500, 'An error occured');
            });
    })
    .fail(function (e) {
        //handle errors here
        res.send(400, 'An error occured');
    });
});
```

**Use the authentication info in other endpoints**

Once a user is authenticaded on a service, the auth result object is stored
in the session. You can access it very easily from any other endpoint to use it. Let's say for example that you want to post something on your user's wall on Facebook :

```JavaScript
app.post('/api/wall_message', function (req, res){
    var data = JSON.parse(req.body);
    //data contains field "message", containing the message to post
    
    OAuth.create(req, 'facebook')
        .post('/me/feed', {
            message: data.message
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

**Using the front-end SDK for authentication**

The front-end SDK lets you use a popup method for authentication :

```JavaScript
OAuth.popup('facebook')
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
            })
            .fail(function (error) {
                //handle the error
            });
    })
    .fail(function (e) {
        //handle the error
    });
```


Detailed doc
------------

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