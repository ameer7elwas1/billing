//
// Generated file. Do not edit.
//

// ignore_for_file: directives_ordering
// ignore_for_file: lines_longer_than_80_chars

import 'package:app_links/src/app_links_web.dart';
import 'package:geolocator_web/geolocator_web.dart';
import 'package:mapbox_gl_web/mapbox_gl_web.dart';
import 'package:url_launcher_web/url_launcher_web.dart';

import 'package:flutter_web_plugins/flutter_web_plugins.dart';

// ignore: public_member_api_docs
void registerPlugins(Registrar registrar) {
  AppLinksPluginWeb.registerWith(registrar);
  GeolocatorPlugin.registerWith(registrar);
  MapboxMapPlugin.registerWith(registrar);
  UrlLauncherPlugin.registerWith(registrar);
  registrar.registerMessageHandler();
}
