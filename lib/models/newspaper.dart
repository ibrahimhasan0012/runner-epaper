import 'package:flutter/material.dart';

enum AccessType {
  freeDirect,     // Instant public e-paper, no login needed
  freeWithLogin,  // Free daily edition with free publisher account
  freemium,       // Partial free preview / subscriber portal
}

class Newspaper {
  final String id;
  final String nameBn;
  final String nameEn;
  final String taglineBn;
  final String epaperUrl;
  final String category;
  final AccessType accessType;
  final String accessNote;
  final Color brandColor;
  final bool preferDesktopViewport;

  const Newspaper({
    required this.id,
    required this.nameBn,
    required this.nameEn,
    required this.taglineBn,
    required this.epaperUrl,
    this.category = 'জাতীয় দৈনিক',
    this.accessType = AccessType.freeDirect,
    this.accessNote = 'সরাসরি ফ্রি ই-পেপার (লগইন ছাড়াই পড়ুন)',
    required this.brandColor,
    this.preferDesktopViewport = false,
  });
}
