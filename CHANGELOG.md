## v1.2.0

- Updated dependencies to latest version
- Updated build tools to _29.0.3_, with compile SDK to _29_
- Using Kotlin _1.3.72_
- Seperated Dart classes into different files
- Updated documentation, little more elaborative now ;)

## v1.1.0

**!!! This is a breaking update !!!**

- API has been updated, leveraging power of Asynchronous Programming
- No more callbacks for receiving location data feed
- Stream<MyLocation>, will be returned on request
- Which can also be stopped if required.

## v1.0.0

This is the very first release of locate flutter plugin. It simply fetches android location data using either Google Play Service based Location Service or android.location.LocationManager. It can continously report device location using callback mechanism, which might be used to update UI.

This plugin only works for **Android** Platform. Built with latest version of SDK(28).
