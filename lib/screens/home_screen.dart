import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';

import '../data/newspapers_data.dart';
import '../main.dart';
import '../models/newspaper.dart';
import '../services/storage_and_share_service.dart';
import 'epaper_reader_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String _searchQuery = '';
  String _selectedCategory = 'all'; // 'all', 'জাতীয় দৈনিক', 'অর্থনীতি ও বাণিজ্য', 'ইংরেজি দৈনিক', 'favorites'
  Set<String> _favoriteIds = {};
  String? _lastReadPaperId;

  @override
  void initState() {
    super.initState();
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    final favs = await StorageAndShareService.getFavorites();
    final lastRead = await StorageAndShareService.getLastRead();
    if (!mounted) return;
    setState(() {
      _favoriteIds = favs;
      _lastReadPaperId = lastRead;
    });
  }

  Future<void> _toggleFavorite(String id) async {
    HapticFeedback.selectionClick();
    setState(() {
      if (_favoriteIds.contains(id)) {
        _favoriteIds.remove(id);
      } else {
        _favoriteIds.add(id);
      }
    });
    await StorageAndShareService.setFavorites(_favoriteIds);
  }

  Future<void> _openPaper(Newspaper paper) async {
    HapticFeedback.lightImpact();
    await StorageAndShareService.setLastRead(paper.id);
    setState(() {
      _lastReadPaperId = paper.id;
    });
    if (!mounted) return;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => EpaperReaderScreen(initialNewspaper: paper),
      ),
    );
  }

  void _toggleTheme() {
    HapticFeedback.lightImpact();
    final current = themeModeNotifier.value;
    final next = current == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
    themeModeNotifier.value = next;
    StorageAndShareService.setThemeMode(next == ThemeMode.dark ? 'dark' : 'light');
  }

  String _getFormattedBanglaDate() {
    final now = DateTime.now();
    // English to Bangla numeral mapping
    const enToBn = {
      '0': '০', '1': '১', '2': '২', '3': '৩', '4': '৪',
      '5': '৫', '6': '৬', '7': '৭', '8': '৮', '9': '৯'
    };
    final dayNamesBn = [
      'সোমবার', 'মঙ্গলবার', 'বুধবার', 'বৃহস্পতিবার', 'শুক্রবার', 'শনিবার', 'রবিবার'
    ];
    final monthNamesBn = [
      'জানুয়ারি', 'ফেব্রুয়ারি', 'মার্চ', 'এপ্রিল', 'মে', 'জুন',
      'জুলাই', 'আগস্ট', 'সেপ্টেম্বর', 'অক্টোবর', 'নভেম্বর', 'ডিসেম্বর'
    ];

    final dayName = dayNamesBn[now.weekday - 1];
    final monthName = monthNamesBn[now.month - 1];
    var dayStr = now.day.toString();
    var yearStr = now.year.toString();
    enToBn.forEach((k, v) {
      dayStr = dayStr.replaceAll(k, v);
      yearStr = yearStr.replaceAll(k, v);
    });

    return '$dayName, $dayStr $monthName $yearStr';
  }

  List<Newspaper> get _filteredPapers {
    return banglaNewspapers.where((paper) {
      final matchesSearch = _searchQuery.isEmpty ||
          paper.nameBn.contains(_searchQuery) ||
          paper.nameEn.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          paper.taglineBn.contains(_searchQuery);

      if (!matchesSearch) return false;

      if (_selectedCategory == 'favorites') {
        return _favoriteIds.contains(paper.id);
      } else if (_selectedCategory != 'all') {
        return paper.category.contains(_selectedCategory) ||
            (_selectedCategory == 'ইংরেজি দৈনিক' && paper.category == 'ইংরেজি দৈনিক');
      }
      return true;
    }).toList();
  }

  Widget _buildAccessBadge(AccessType type) {
    switch (type) {
      case AccessType.freeDirect:
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
          decoration: BoxDecoration(
            color: const Color(0xFFE8F5E9),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(0xFF2E7D32).withValues(alpha: 0.3)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.verified_rounded, size: 12, color: Color(0xFF2E7D32)),
              const SizedBox(width: 4),
              Flexible(
                child: Text(
                  'সরাসরি ফ্রি',
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.hindSiliguri(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF1B5E20),
                  ),
                ),
              ),
            ],
          ),
        );
      case AccessType.freeWithLogin:
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
          decoration: BoxDecoration(
            color: const Color(0xFFFFF8E1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(0xFFF57F17).withValues(alpha: 0.3)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.lock_open_rounded, size: 12, color: Color(0xFFE65100)),
              const SizedBox(width: 4),
              Flexible(
                child: Text(
                  'ফ্রি লগইন',
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.hindSiliguri(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFFE65100),
                  ),
                ),
              ),
            ],
          ),
        );
      case AccessType.freemium:
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
          decoration: BoxDecoration(
            color: const Color(0xFFECEFF1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            'অফিশিয়াল পোর্টাল',
            style: GoogleFonts.hindSiliguri(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF455A64),
            ),
          ),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final papers = _filteredPapers;
    final lastReadPaper = _lastReadPaperId == null
        ? null
        : banglaNewspapers.where((p) => p.id == _lastReadPaperId).firstOrNull;

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 14,
        title: Row(
          children: [
            // Typographic 'র' Brand Monogram
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF00382E), Color(0xFF005B4D)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: Colors.amberAccent.withValues(alpha: 0.4),
                  width: 1.2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.2),
                    blurRadius: 4,
                    offset: const Offset(0, 1.5),
                  ),
                ],
              ),
              alignment: Alignment.center,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Text(
                    'র',
                    style: GoogleFonts.hindSiliguri(
                      color: const Color(0xFFFAF8F5),
                      fontWeight: FontWeight.w900,
                      fontSize: 22,
                      height: 1.0,
                    ),
                  ),
                  Positioned(
                    bottom: 7.5,
                    left: 11.5,
                    child: Container(
                      width: 5,
                      height: 5,
                      decoration: const BoxDecoration(
                        color: Colors.amberAccent,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      'রানার',
                      style: GoogleFonts.hindSiliguri(
                        fontWeight: FontWeight.w800,
                        fontSize: 21,
                        letterSpacing: 0.2,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Runner',
                      style: GoogleFonts.outfit(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ),
                Text(
                  _getFormattedBanglaDate(),
                  style: GoogleFonts.hindSiliguri(
                    fontSize: 11.5,
                    color: Colors.white.withValues(alpha: 0.8),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: isDark ? 'লাইট মোড চালু করুন' : 'ডার্ক মোড চালু করুন',
            onPressed: _toggleTheme,
            icon: Icon(
              isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
              color: isDark ? Colors.amberAccent : Colors.white,
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.shield_rounded, size: 14, color: Colors.amberAccent),
                  SizedBox(width: 4),
                  Text(
                    'Ad-Block',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Pinned Search & Category Strip
          Container(
            color: isDark ? const Color(0xFF1E1E1E) : const Color(0xFF004D40),
            padding: const EdgeInsets.fromLTRB(16, 6, 16, 14),
            child: Column(
              children: [
                TextField(
                  onChanged: (value) => setState(() => _searchQuery = value),
                  style: TextStyle(
                    color: isDark ? Colors.white : Colors.black87,
                    fontSize: 14,
                  ),
                  decoration: InputDecoration(
                    hintText: 'পত্রিকা খুঁজুন (যুগান্তর, Prothom Alo, Daily Star)...',
                    hintStyle: TextStyle(
                      fontSize: 13,
                      color: isDark ? Colors.white54 : Colors.black45,
                    ),
                    prefixIcon: Icon(
                      Icons.search_rounded,
                      color: isDark ? Colors.white70 : const Color(0xFF004D40),
                    ),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            onPressed: () => setState(() => _searchQuery = ''),
                            icon: const Icon(Icons.clear_rounded),
                          )
                        : null,
                    filled: true,
                    fillColor: isDark ? const Color(0xFF2C2C2C) : Colors.white,
                    contentPadding: const EdgeInsets.symmetric(vertical: 10),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  child: Row(
                    children: [
                      _CategoryFilterChip(
                        label: 'সব (${banglaNewspapers.length})',
                        icon: Icons.newspaper_rounded,
                        selected: _selectedCategory == 'all',
                        onTap: () => setState(() => _selectedCategory = 'all'),
                      ),
                      const SizedBox(width: 8),
                      _CategoryFilterChip(
                        label: 'জাতীয় দৈনিক',
                        icon: Icons.public_rounded,
                        selected: _selectedCategory == 'জাতীয় দৈনিক',
                        onTap: () => setState(() => _selectedCategory = 'জাতীয় দৈনিক'),
                      ),
                      const SizedBox(width: 8),
                      _CategoryFilterChip(
                        label: 'ইংরেজি (English)',
                        icon: Icons.language_rounded,
                        selected: _selectedCategory == 'ইংরেজি দৈনিক',
                        onTap: () => setState(() => _selectedCategory = 'ইংরেজি দৈনিক'),
                      ),
                      const SizedBox(width: 8),
                      _CategoryFilterChip(
                        label: 'পছন্দের (${_favoriteIds.length})',
                        icon: Icons.favorite_rounded,
                        selected: _selectedCategory == 'favorites',
                        onTap: () => setState(() => _selectedCategory = 'favorites'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Continue Reading Section
          if (lastReadPaper != null && _searchQuery.isEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
              child: InkWell(
                onTap: () => _openPaper(lastReadPaper),
                borderRadius: BorderRadius.circular(14),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF24221A) : const Color(0xFFFFF9E6),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: isDark ? Colors.amber.withValues(alpha: 0.3) : Colors.amber.shade300,
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: lastReadPaper.brandColor.withValues(alpha: 0.15),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.history_rounded,
                          color: lastReadPaper.brandColor,
                          size: 18,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'সর্বশেষ পড়েছেন:',
                              style: GoogleFonts.hindSiliguri(
                                fontSize: 11,
                                color: isDark ? Colors.white60 : Colors.black54,
                              ),
                            ),
                            Text(
                              '${lastReadPaper.nameBn} (${lastReadPaper.nameEn})',
                              style: GoogleFonts.hindSiliguri(
                                fontWeight: FontWeight.bold,
                                fontSize: 13.5,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: lastReadPaper.brandColor,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          'পুনরায় পড়ুন →',
                          style: GoogleFonts.hindSiliguri(
                            fontSize: 11.5,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ).animate().fadeIn(duration: 300.ms),

          // Main Newspaper Cards Grid
          Expanded(
            child: papers.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.newspaper_rounded,
                          size: 54,
                          color: isDark ? Colors.white24 : Colors.black26,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'কোনো পত্রিকা পাওয়া যায়নি',
                          style: GoogleFonts.hindSiliguri(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white70 : Colors.black54,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'অনুগ্রহ করে অন্য শব্দ দিয়ে অনুসন্ধান করুন',
                          style: GoogleFonts.hindSiliguri(
                            fontSize: 13,
                            color: isDark ? Colors.white38 : Colors.black38,
                          ),
                        ),
                      ],
                    ),
                  )
                : GridView.builder(
                    padding: const EdgeInsets.fromLTRB(14, 12, 14, 20),
                    gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                      maxCrossAxisExtent: 260,
                      mainAxisExtent: 175,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                    ),
                    itemCount: papers.length,
                    itemBuilder: (context, index) {
                      final paper = papers[index];
                      final isFav = _favoriteIds.contains(paper.id);

                      return Card(
                        clipBehavior: Clip.antiAlias,
                        child: InkWell(
                          onTap: () => _openPaper(paper),
                          child: Container(
                            decoration: BoxDecoration(
                              border: Border(
                                top: BorderSide(color: paper.brandColor, width: 3.5),
                              ),
                            ),
                            padding: const EdgeInsets.all(12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    // Masthead Logo Monogram Badge
                                    Container(
                                      width: 36,
                                      height: 36,
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          colors: [
                                            paper.brandColor,
                                            paper.brandColor.withValues(alpha: 0.8),
                                          ],
                                          begin: Alignment.topLeft,
                                          end: Alignment.bottomRight,
                                        ),
                                        borderRadius: BorderRadius.circular(10),
                                        boxShadow: [
                                          BoxShadow(
                                            color: paper.brandColor.withValues(alpha: 0.25),
                                            blurRadius: 6,
                                            offset: const Offset(0, 2),
                                          ),
                                        ],
                                      ),
                                      alignment: Alignment.center,
                                      child: Text(
                                        paper.nameBn.characters.first,
                                        style: GoogleFonts.hindSiliguri(
                                          color: Colors.white,
                                          fontSize: 19,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                    IconButton(
                                      visualDensity: VisualDensity.compact,
                                      tooltip: isFav ? 'পছন্দ থেকে সরান' : 'পছন্দে যোগ করুন',
                                      onPressed: () => _toggleFavorite(paper.id),
                                      icon: AnimatedSwitcher(
                                        duration: const Duration(milliseconds: 200),
                                        transitionBuilder: (child, anim) =>
                                            ScaleTransition(scale: anim, child: child),
                                        child: Icon(
                                          isFav
                                              ? Icons.favorite_rounded
                                              : Icons.favorite_border_rounded,
                                          key: ValueKey(isFav),
                                          color: isFav ? Colors.redAccent : Colors.grey,
                                          size: 21,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  paper.nameBn,
                                  style: GoogleFonts.hindSiliguri(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w800,
                                    height: 1.15,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  paper.nameEn,
                                  style: GoogleFonts.hindSiliguri(
                                    fontSize: 11.5,
                                    color: isDark ? Colors.white60 : Colors.black54,
                                    fontWeight: FontWeight.w500,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const Spacer(),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(child: _buildAccessBadge(paper.accessType)),
                                    const SizedBox(width: 4),
                                    Icon(
                                      Icons.arrow_forward_ios_rounded,
                                      size: 13,
                                      color: isDark ? Colors.white30 : Colors.black26,
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      )
                          .animate()
                          .fadeIn(
                            duration: 250.ms,
                            delay: (index * 35).clamp(0, 400).ms,
                          )
                          .slideY(
                            begin: 0.08,
                            end: 0,
                            duration: 250.ms,
                            delay: (index * 35).clamp(0, 400).ms,
                          );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _CategoryFilterChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  const _CategoryFilterChip({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      borderRadius: BorderRadius.circular(20),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6.5),
        decoration: BoxDecoration(
          color: selected ? Colors.amberAccent : Colors.white.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 14,
              color: selected ? Colors.black87 : Colors.white,
            ),
            const SizedBox(width: 5),
            Text(
              label,
              style: GoogleFonts.hindSiliguri(
                color: selected ? Colors.black87 : Colors.white,
                fontWeight: selected ? FontWeight.bold : FontWeight.w600,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
