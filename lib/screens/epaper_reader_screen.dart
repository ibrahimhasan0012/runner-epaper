import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../data/newspapers_data.dart';
import '../models/newspaper.dart';
import '../services/ad_blocker_service.dart';
import '../services/storage_and_share_service.dart';

class EpaperReaderScreen extends StatefulWidget {
  final Newspaper initialNewspaper;
  final bool adBlockerEnabledByDefault;

  const EpaperReaderScreen({
    super.key,
    required this.initialNewspaper,
    this.adBlockerEnabledByDefault = true,
  });

  @override
  State<EpaperReaderScreen> createState() => _EpaperReaderScreenState();
}

class _EpaperReaderScreenState extends State<EpaperReaderScreen> {
  late Newspaper _currentNewspaper;
  late WebViewController _controller;

  bool _isLoading = true;
  double _progress = 0.0;
  bool _adBlockEnabled = true;
  bool _nightReadingMode = false;
  int _blockedAdsCount = 0;
  bool _isDesktopMode = false;
  bool _isFullScreen = false;
  String _currentUrl = '';
  DateTime _selectedDate = DateTime.now();

  static const String _mobileUserAgent =
      'Mozilla/5.0 (Linux; Android 14; Pixel 8) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/126.0.0.0 Mobile Safari/537.36';
  static const String _desktopUserAgent =
      'Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/126.0.0.0 Safari/537.36';

  @override
  void initState() {
    super.initState();
    _currentNewspaper = widget.initialNewspaper;
    _adBlockEnabled = widget.adBlockerEnabledByDefault;
    _isDesktopMode = _currentNewspaper.preferDesktopViewport;
    _currentUrl = _currentNewspaper.epaperUrl;
    _initWebView();
  }

  void _initWebView() {
    final controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..enableZoom(true)
      ..setUserAgent(_isDesktopMode ? _desktopUserAgent : _mobileUserAgent)
      ..setNavigationDelegate(
        NavigationDelegate(
          onProgress: (int progress) {
            if (mounted) {
              setState(() {
                _progress = progress / 100.0;
              });
            }
          },
          onPageStarted: (String url) {
            if (mounted) {
              setState(() {
                _isLoading = true;
                _currentUrl = url;
              });
            }
          },
          onPageFinished: (String url) async {
            if (_adBlockEnabled) {
              await _controller.runJavaScript(AdBlockerService.cleanReaderJs);
            }
            if (_nightReadingMode) {
              await _controller.runJavaScript(AdBlockerService.enableNightModeJs);
            }
            if (mounted) {
              setState(() {
                _isLoading = false;
                _currentUrl = url;
              });
            }
          },
          onNavigationRequest: (NavigationRequest request) {
            if (_adBlockEnabled && AdBlockerService.shouldBlockUrl(request.url)) {
              if (mounted) {
                setState(() {
                  _blockedAdsCount++;
                });
              }
              return NavigationDecision.prevent;
            }
            return NavigationDecision.navigate;
          },
        ),
      )
      ..loadRequest(Uri.parse(_currentNewspaper.epaperUrl));

    _controller = controller;
  }

  void _switchNewspaper(Newspaper paper) {
    HapticFeedback.lightImpact();
    setState(() {
      _currentNewspaper = paper;
      _blockedAdsCount = 0;
      _isLoading = true;
      _currentUrl = paper.epaperUrl;
    });
    _controller.loadRequest(Uri.parse(paper.epaperUrl));
  }

  void _toggleDesktopMode() {
    HapticFeedback.lightImpact();
    setState(() {
      _isDesktopMode = !_isDesktopMode;
      _isLoading = true;
    });
    _controller.setUserAgent(
      _isDesktopMode ? _desktopUserAgent : _mobileUserAgent,
    );
    _controller.reload();
  }

  void _toggleNightMode() async {
    HapticFeedback.lightImpact();
    setState(() {
      _nightReadingMode = !_nightReadingMode;
    });
    if (_nightReadingMode) {
      await _controller.runJavaScript(AdBlockerService.enableNightModeJs);
    } else {
      await _controller.runJavaScript(AdBlockerService.disableNightModeJs);
    }
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          _nightReadingMode ? 'নাইট রিডিং মোড চালু হয়েছে' : 'ডে রিডিং মোড চালু হয়েছে',
          style: GoogleFonts.hindSiliguri(),
        ),
        duration: const Duration(seconds: 1),
      ),
    );
  }

  void _toggleFullScreen() {
    HapticFeedback.lightImpact();
    setState(() {
      _isFullScreen = !_isFullScreen;
    });
    if (_isFullScreen) {
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    } else {
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    }
  }

  void _zoomIn() {
    HapticFeedback.selectionClick();
    _controller.runJavaScript(AdBlockerService.zoomInJs);
  }

  void _zoomOut() {
    HapticFeedback.selectionClick();
    _controller.runJavaScript(AdBlockerService.zoomOutJs);
  }

  void _resetZoom() {
    HapticFeedback.selectionClick();
    _controller.runJavaScript(AdBlockerService.resetZoomJs);
  }

  Future<void> _pickArchiveDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      helpText: 'আর্কাইভ থেকে পত্রিকা পড়ার তারিখ নির্বাচন করুন',
      confirmText: 'দেখুন',
      cancelText: 'বাতিল',
    );

    if (picked != null) {
      setState(() {
        _selectedDate = picked;
      });
      // Construct common date query patterns for e-papers
      final dateStr =
          '${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}';
      final uri = Uri.parse(_currentNewspaper.epaperUrl);
      final newUrl = uri.replace(queryParameters: {'date': dateStr}).toString();
      _controller.loadRequest(Uri.parse(newUrl));
    }
  }

  @override
  void dispose() {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  void _showQuickSwitcher() {
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'অন্য পত্রিকা পড়ুন (Quick Switch)',
                      style: GoogleFonts.hindSiliguri(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  physics: const BouncingScrollPhysics(),
                  itemCount: banglaNewspapers.length,
                  itemBuilder: (context, index) {
                    final paper = banglaNewspapers[index];
                    final isSelected = paper.id == _currentNewspaper.id;
                    return ListTile(
                      leading: Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: paper.brandColor,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          paper.nameBn.characters.first,
                          style: GoogleFonts.hindSiliguri(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ),
                      title: Text(
                        paper.nameBn,
                        style: GoogleFonts.hindSiliguri(
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                        ),
                      ),
                      subtitle: Text(
                        paper.nameEn,
                        style: GoogleFonts.hindSiliguri(fontSize: 12),
                      ),
                      trailing: isSelected
                          ? Icon(
                              Icons.check_circle_rounded,
                              color: Theme.of(context).colorScheme.primary,
                            )
                          : const Icon(Icons.chevron_right_rounded),
                      onTap: () {
                        Navigator.pop(context);
                        if (!isSelected) {
                          _switchNewspaper(paper);
                        }
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        if (await _controller.canGoBack()) {
          await _controller.goBack();
        } else if (context.mounted) {
          Navigator.of(context).pop();
        }
      },
      child: Scaffold(
        appBar: _isFullScreen
            ? null
            : AppBar(
                backgroundColor: _currentNewspaper.brandColor,
                foregroundColor: Colors.white,
                titleSpacing: 0,
                title: InkWell(
                  onTap: _showQuickSwitcher,
                  borderRadius: BorderRadius.circular(8),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Flexible(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Flexible(
                                    child: Text(
                                      _currentNewspaper.nameBn,
                                      style: GoogleFonts.hindSiliguri(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  const Icon(Icons.expand_more_rounded, size: 20),
                                ],
                              ),
                              Text(
                                _isDesktopMode
                                    ? 'ব্রডশিট পূর্ণ পাতা (Desktop)'
                                    : 'মোবাইল ই-পেপার ভিউ',
                                style: GoogleFonts.hindSiliguri(
                                  fontSize: 11,
                                  color: Colors.white.withValues(alpha: 0.8),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                actions: [
                  // Ad-blocker counter & toggle badge
                  IconButton(
                    tooltip: _adBlockEnabled
                        ? 'অ্যাড-ব্লকার সক্রিয় ($_blockedAdsCount টি বিজ্ঞাপন ব্লকড)'
                        : 'অ্যাড-ব্লকার বন্ধ',
                    onPressed: () {
                      setState(() {
                        _adBlockEnabled = !_adBlockEnabled;
                      });
                      _controller.reload();
                    },
                    icon: Badge(
                      isLabelVisible: _adBlockEnabled && _blockedAdsCount > 0,
                      label: Text('$_blockedAdsCount'),
                      child: Icon(
                        _adBlockEnabled ? Icons.shield_rounded : Icons.shield_outlined,
                        color: _adBlockEnabled ? Colors.amberAccent : Colors.white70,
                      ),
                    ),
                  ),
                  // Night Reading Mode Toggle
                  IconButton(
                    tooltip: _nightReadingMode
                        ? 'ডে মোডে ফিরে যান'
                        : 'নাইট রিডিং মোড চালু করুন',
                    onPressed: _toggleNightMode,
                    icon: Icon(
                      _nightReadingMode ? Icons.bedtime_rounded : Icons.bedtime_outlined,
                      color: _nightReadingMode ? Colors.amberAccent : Colors.white,
                    ),
                  ),
                  // Broadsheet / Mobile View switch
                  IconButton(
                    tooltip: _isDesktopMode
                        ? 'মোবাইল ভিউতে যান'
                        : 'ব্রডশিট ডেস্কটপ ভিউতে যান',
                    onPressed: _toggleDesktopMode,
                    icon: Icon(
                      _isDesktopMode
                          ? Icons.phone_android_rounded
                          : Icons.newspaper_rounded,
                    ),
                  ),
                  // Fullscreen toggle
                  IconButton(
                    tooltip: 'ফুলস্ক্রিন ভিউ',
                    onPressed: _toggleFullScreen,
                    icon: const Icon(Icons.fullscreen_rounded),
                  ),
                  // Context Menu
                  PopupMenuButton<String>(
                    onSelected: (value) async {
                      if (value == 'archive') {
                        await _pickArchiveDate();
                      } else if (value == 'reload') {
                        _controller.reload();
                      } else if (value == 'share') {
                        await StorageAndShareService.shareText(
                          '${_currentNewspaper.nameBn} (${_currentNewspaper.nameEn}) আজকের ই-পেপার পড়ুন: $_currentUrl',
                          subject: '${_currentNewspaper.nameBn} ই-পেপার',
                        );
                      } else if (value == 'browser') {
                        final uri = Uri.parse(_currentUrl);
                        if (await canLaunchUrl(uri)) {
                          await launchUrl(uri, mode: LaunchMode.externalApplication);
                        }
                      }
                    },
                    itemBuilder: (context) => [
                      PopupMenuItem(
                        value: 'archive',
                        child: ListTile(
                          leading: const Icon(Icons.calendar_month_rounded),
                          title: Text(
                            'আর্কাইভ ও পুরনো সংখ্যা',
                            style: GoogleFonts.hindSiliguri(),
                          ),
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                      PopupMenuItem(
                        value: 'reload',
                        child: ListTile(
                          leading: const Icon(Icons.refresh_rounded),
                          title: Text(
                            'পাতা রিলোড করুন',
                            style: GoogleFonts.hindSiliguri(),
                          ),
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                      PopupMenuItem(
                        value: 'share',
                        child: ListTile(
                          leading: const Icon(Icons.share_rounded),
                          title: Text(
                            'পত্রিকার লিংক শেয়ার করুন',
                            style: GoogleFonts.hindSiliguri(),
                          ),
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                      PopupMenuItem(
                        value: 'browser',
                        child: ListTile(
                          leading: const Icon(Icons.open_in_browser_rounded),
                          title: Text(
                            'বাইরের ব্রাউজারে খুলুন',
                            style: GoogleFonts.hindSiliguri(),
                          ),
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
        body: Stack(
          children: [
            WebViewWidget(controller: _controller),
            if (_isLoading)
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: LinearProgressIndicator(
                  value: _progress > 0 && _progress < 1 ? _progress : null,
                  minHeight: 3.5,
                  color: Colors.amberAccent,
                  backgroundColor: Colors.black26,
                ),
              ),
            // Floating Zoom Control Bar
            Positioned(
              right: 14,
              bottom: _isFullScreen ? 20 : 16,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.92),
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.15),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                  border: Border.all(
                    color: Theme.of(context).dividerColor.withValues(alpha: 0.2),
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      visualDensity: VisualDensity.compact,
                      tooltip: 'জুম ইন (+)',
                      onPressed: _zoomIn,
                      icon: const Icon(Icons.zoom_in_rounded, size: 20),
                    ),
                    IconButton(
                      visualDensity: VisualDensity.compact,
                      tooltip: 'সাধারণ আকার (1x)',
                      onPressed: _resetZoom,
                      icon: const Icon(Icons.fit_screen_rounded, size: 18),
                    ),
                    IconButton(
                      visualDensity: VisualDensity.compact,
                      tooltip: 'জুম আউট (-)',
                      onPressed: _zoomOut,
                      icon: const Icon(Icons.zoom_out_rounded, size: 20),
                    ),
                    if (_isFullScreen) ...[
                      const Divider(height: 8),
                      IconButton(
                        visualDensity: VisualDensity.compact,
                        tooltip: 'ফুলস্ক্রিন বন্ধ করুন',
                        onPressed: _toggleFullScreen,
                        icon: const Icon(Icons.fullscreen_exit_rounded, size: 20),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
        bottomNavigationBar: _isFullScreen
            ? null
            : BottomAppBar(
                height: 56,
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      tooltip: 'আগের পাতায় যান',
                      onPressed: () async {
                        if (await _controller.canGoBack()) {
                          await _controller.goBack();
                        }
                      },
                      icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
                    ),
                    IconButton(
                      tooltip: 'পরের পাতায় যান',
                      onPressed: () async {
                        if (await _controller.canGoForward()) {
                          await _controller.goForward();
                        }
                      },
                      icon: const Icon(Icons.arrow_forward_ios_rounded, size: 18),
                    ),
                    TextButton.icon(
                      onPressed: () {
                        HapticFeedback.selectionClick();
                        _controller.loadRequest(
                          Uri.parse(_currentNewspaper.epaperUrl),
                        );
                      },
                      icon: const Icon(Icons.first_page_rounded, size: 20),
                      label: Text(
                        'প্রথম পাতা',
                        style: GoogleFonts.hindSiliguri(fontWeight: FontWeight.bold),
                      ),
                    ),
                    FilledButton.tonalIcon(
                      onPressed: _showQuickSwitcher,
                      icon: const Icon(Icons.swap_horiz_rounded, size: 18),
                      label: Text(
                        'অন্য পত্রিকা',
                        style: GoogleFonts.hindSiliguri(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}
