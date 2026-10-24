class AdBlockerService {
  /// Common ad, popup, and tracker domains encountered on e-paper portals
  static const List<String> blockedDomains = [
    'doubleclick.net',
    'googlesyndication.com',
    'googleadservices.com',
    'adservice.google.com',
    'pagead2.googlesyndication.com',
    'securepubads.g.doubleclick.net',
    'tpc.googlesyndication.com',
    'taboola.com',
    'outbrain.com',
    'mgid.com',
    'adnxs.com',
    'criteo.com',
    'rubiconproject.com',
    'pubmatic.com',
    'openx.net',
    'popads.net',
    'propellerads.com',
    'eskimi.com',
    'purplepatch.online',
    'purplepatch4.com',
    'adpushup.com',
    'zergnet.com',
  ];

  /// Returns true if a URL belongs to an ad or tracker domain
  static bool shouldBlockUrl(String url) {
    final lower = url.toLowerCase();
    for (final domain in blockedDomains) {
      if (lower.contains(domain)) {
        return true;
      }
    }
    return false;
  }

  /// JavaScript injected into the WebView to hide intrusive ad containers,
  /// floating banners, and force pinch-to-zoom capability on the e-paper image canvas.
  static const String cleanReaderJs = '''
    (function() {
      // 1. Ensure viewport allows pinch-to-zoom up to 6x for reading fine broadsheet print
      var meta = document.querySelector('meta[name="viewport"]');
      if (!meta) {
        meta = document.createElement('meta');
        meta.name = 'viewport';
        document.head.appendChild(meta);
      }
      meta.content = 'width=device-width, initial-scale=1.0, maximum-scale=6.0, user-scalable=yes';

      // 2. Inject CSS rules to hide common ad slots, sticky overlays and video popups
      var styleId = 'bd-epaper-clean-reader-style';
      if (!document.getElementById(styleId)) {
        var style = document.createElement('style');
        style.id = styleId;
        style.innerHTML = `
          ins.adsbygoogle,
          .adsbygoogle,
          [id^="google_ads_iframe"],
          [id^="div-gpt-ad"],
          .ad-container,
          .ad-banner,
          .top-ad,
          .bottom-sticky-ad,
          .floating-ad,
          .popup-ad,
          .interstitial-ad,
          .ad-overlay,
          .fly-ad,
          iframe[src*="doubleclick.net"],
          iframe[src*="googlesyndication.com"],
          iframe[src*="eskimi.com"],
          iframe[src*="purplepatch"] {
            display: none !important;
            height: 0 !important;
            min-height: 0 !important;
            visibility: hidden !important;
            pointer-events: none !important;
          }
        `;
        document.head.appendChild(style);
      }

      // 3. Periodically sweep dynamically injected ad iframes
      setInterval(function() {
        var selectors = [
          'ins.adsbygoogle',
          '[id^="google_ads_iframe"]',
          '[id^="div-gpt-ad"]',
          '.floating-ad',
          '.bottom-sticky-ad',
          '.interstitial-ad'
        ];
        selectors.forEach(function(sel) {
          document.querySelectorAll(sel).forEach(function(el) {
            el.remove();
          });
        });
      }, 1500);
    })();
  ''';

  /// Inverts page for dark/night reading while preserving images and photos
  static const String enableNightModeJs = '''
    (function() {
      var id = 'bd-epaper-night-mode-style';
      var style = document.getElementById(id);
      if (!style) {
        style = document.createElement('style');
        style.id = id;
        style.innerHTML = `
          html {
            filter: invert(0.88) hue-rotate(180deg) !important;
            background-color: #121212 !important;
          }
          img, picture, video, canvas, svg, [style*="background-image"] {
            filter: invert(1) hue-rotate(180deg) !important;
          }
          body {
            background-color: #121212 !important;
          }
        `;
        document.head.appendChild(style);
      }
    })();
  ''';

  /// Removes the night mode inversion filter
  static const String disableNightModeJs = '''
    (function() {
      var style = document.getElementById('bd-epaper-night-mode-style');
      if (style) {
        style.remove();
      }
    })();
  ''';

  /// Zoom scripts to dynamically scale the document body
  static const String zoomInJs = '''
    (function() {
      var current = parseFloat(document.body.style.zoom || '1.0');
      document.body.style.zoom = (current + 0.25).toString();
    })();
  ''';

  static const String zoomOutJs = '''
    (function() {
      var current = parseFloat(document.body.style.zoom || '1.0');
      if (current > 0.5) {
        document.body.style.zoom = (current - 0.25).toString();
      }
    })();
  ''';

  static const String resetZoomJs = '''
    (function() {
      document.body.style.zoom = '1.0';
    })();
  ''';
}
