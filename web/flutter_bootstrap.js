{{flutter_js}}
{{flutter_build_config}}

// Flutter's own service worker is deprecated: the app registers sw.js
// itself (see index.html), so none is passed to the loader here.
_flutter.loader.load();
