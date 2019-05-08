## 1.0.0

This is the very first release of locate flutter plugin. It simply fetches android location data using either Google Play Service based Location Service or android.location.LocationManager. It can continously report device location using callback mechanism, which might be used to update UI.

This plugin only works for **Androd** Platform. Built with latest version of SDK(28).

## 1.1.0

Very happy to release a new version of this plugin.

In this release *locate*, tries to leverage the power of Asynchronous Programming, based on Future<T> and Stream<T>, to a great level.

If you've been using it, we'll this might be a bad situttion, but it's a breaking update.

API has been updated, for ease of usability. No callbacks anymore for receiving location data feed, a Stream<MyLocation>, will be returned on request and can also be stopped if required.


Hope it'll be helpful.
