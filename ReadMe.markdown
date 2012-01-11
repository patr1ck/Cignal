Cignal
======

A prototype, Twitter-based, Parse-based, social polling app.


Building
========
Cignal uses a simple build script to load the api keys into the Info.plist at build time, so I don't have to store them in github.

You'll want to create a .api_keys file in your home directory, and list your keys like so:

```
PARSE_CIGNAL_PROD_APP_ID=foo
PARSE_CIGNAL_PROD_CLIENT_KEY=bar
PARSE_CIGNAL_DEV_APP_ID=baz
PARSE_CIGNAL_DEV_CLIENT_KEY=uhhh_the_thing_that_comes_after_baz
```