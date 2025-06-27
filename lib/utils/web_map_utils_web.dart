// This file contains web-specific code for Google Maps
// It will only be imported on web platforms

import 'dart:html' as html;

// Web-specific implementation
void configureWebGoogleMaps() {
  // Ignore CORS for Google Maps
  final html.ScriptElement script = html.ScriptElement()
    ..type = 'text/javascript'
    ..innerHtml = '''
      window.addEventListener('load', function() {
        if (typeof google === 'object' && typeof google.maps === 'object') {
          console.log('Google Maps already loaded');
        } else {
          console.log('Waiting for Google Maps to load...');
          // Try to initialize Google Maps manually if needed
          if (typeof initGoogleMapsApi === 'function') {
            initGoogleMapsApi();
          }
        }
      });
    ''';
  html.document.head!.append(script);
}
