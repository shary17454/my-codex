import 'dart:async';
import 'dart:convert';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'src/features/catalog/data/seed/patrol_generations_seed.dart';
import 'src/features/catalog/domain/models/patrol_generation.dart';
import 'src/platform/open_asset.dart';

void main() => runApp(const PatrolHubApp());

class PatrolHubApp extends StatelessWidget {
  const PatrolHubApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Patrol Hub',
      debugShowCheckedModeBanner: false,
      locale: const Locale('ar'),
      theme: ThemeData(
        brightness: Brightness.dark,
        useMaterial3: true,
        fontFamily: 'Arial',
        scaffoldBackgroundColor: const Color(0xFF080706),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFFF8A1E),
          brightness: Brightness.dark,
        ),
        cardTheme: CardThemeData(
          color: const Color(0xD9161716),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
            side: const BorderSide(color: Color(0x997C5A3B)),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: const Color(0xCC111111),
          prefixIconColor: const Color(0xFFE7C8A1),
          suffixIconColor: const Color(0xFFFF8A1E),
          hintStyle: const TextStyle(color: Color(0xFF8E8780)),
          labelStyle: const TextStyle(color: Color(0xFFFFB15C)),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: Color(0xFF8C5A2B)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: Color(0xFF61462F)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: Color(0xFFFF8A1E), width: 1.4),
          ),
        ),
      ),
      home: const Directionality(
        textDirection: TextDirection.rtl,
        child: HomePage(),
      ),
    );
  }
}

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final y60 = patrolGenerationsSeed.first;

    return Scaffold(
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF090706),
              Color(0xFF15100D),
              Color(0xFF070706),
            ],
          ),
        ),
        child: ListView(
          children: [
            const SiteHeader(),
            HeroSection(generation: y60),
            const SearchSection(),
            const DatabaseOverviewSection(),
            const AppCompletionSection(),
            const GlobalReferenceVisionSection(),
            const ImplementationGuideSection(),
            const CatalogPdfSection(),
            VehicleProfileSection(generation: y60),
            const CatalogSectionsGrid(),
            GenerationsSection(generations: patrolGenerationsSeed),
            const SiteFooter(),
          ],
        ),
      ),
    );
  }
}

class SiteHeader extends StatelessWidget {
  const SiteHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xF2110F0E),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1180),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final showActions = constraints.maxWidth >= 560;

                return Row(
                  children: [
                    const HeaderMenuButton(),
                    const SizedBox(width: 10),
                    const BrandMark(),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Patrol Hub',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          Text(
                            'منصة نيسان باترول Y60 ومرجع قطع قابل للتطوير',
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(color: Color(0xFFD8D2CC)),
                          ),
                        ],
                      ),
                    ),
                    if (showActions) ...const [
                      HeaderLink(label: 'الأقسام'),
                      SizedBox(width: 8),
                      HeaderLink(label: 'المواصفات'),
                    ],
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

class HeaderMenuButton extends StatelessWidget {
  const HeaderMenuButton({super.key});

  static const items = [
    HeaderMenuItem('home', 'الرئيسية', Icons.home),
    HeaderMenuItem('parts', 'القطع', Icons.manage_search),
    HeaderMenuItem('issues', 'الأعطال', Icons.report_problem),
    HeaderMenuItem('maintenance', 'الصيانة', Icons.build),
    HeaderMenuItem('photos', 'الصور', Icons.photo_library),
    HeaderMenuItem('catalogs', 'الكتالوجات', Icons.picture_as_pdf),
    HeaderMenuItem('database', 'قاعدة البيانات', Icons.storage),
    HeaderMenuItem('vision', 'الرؤية العالمية', Icons.public),
    HeaderMenuItem('guide', 'الشرح', Icons.menu_book),
    HeaderMenuItem('contact', 'تواصل معنا', Icons.mail),
  ];

  static void openItem(BuildContext context, String value) {
    if (value == 'home') {
      Navigator.of(context).popUntil((route) => route.isFirst);
      return;
    }

    if (value == 'parts') {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => const Directionality(
            textDirection: TextDirection.rtl,
            child: PartsCatalogPage(),
          ),
        ),
      );
      return;
    }

    final item = items.firstWhere((menuItem) => menuItem.value == value);
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => Directionality(
          textDirection: TextDirection.rtl,
          child: MenuContentPage(item: item),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      tooltip: 'المحتويات',
      icon: const Icon(Icons.menu, color: Colors.white),
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      onSelected: (value) => openItem(context, value),
      itemBuilder: (context) => items
          .map(
            (item) => PopupMenuItem<String>(
              value: item.value,
              child: Row(
                children: [
                  Icon(item.icon, color: const Color(0xFF7A1F2B)),
                  const SizedBox(width: 10),
                  Text(item.label),
                ],
              ),
            ),
          )
          .toList(growable: false),
    );
  }
}

class HeaderMenuItem {
  const HeaderMenuItem(this.value, this.label, this.icon);

  final String value;
  final String label;
  final IconData icon;
}

class BrandMark extends StatelessWidget {
  const BrandMark({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 44,
      height: 44,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFF8A1E), Color(0xFF7A1F2B)],
        ),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE7C8A1)),
      ),
      child: const Text(
        'Y60',
        style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800),
      ),
    );
  }
}

class HeaderLink extends StatelessWidget {
  const HeaderLink({super.key, required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: () {
        if (label == 'الأقسام') {
          HeaderMenuButton.openItem(context, 'parts');
          return;
        }
        HeaderMenuButton.openItem(context, 'database');
      },
      child: Text(label, style: const TextStyle(color: Colors.white)),
    );
  }
}

class HeroSection extends StatelessWidget {
  const HeroSection({super.key, required this.generation});

  final PatrolGeneration generation;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned.fill(
          child: Image.asset(
            'assets/hero/patrol_hub_mobile_mockup.png',
            fit: BoxFit.cover,
            alignment: Alignment.topCenter,
            filterQuality: FilterQuality.low,
          ),
        ),
        Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withValues(alpha: 0.32),
                  Colors.black.withValues(alpha: 0.70),
                  const Color(0xFF080706),
                ],
              ),
            ),
          ),
        ),
        PageShell(
          top: 28,
          bottom: 30,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth >= 820;
              final text = PremiumGlassPanel(child: HeroCopy(generation: generation));
              final image = VehicleHeroImage(
                label: generation.vehicleProfile?.nameEn ?? 'Nissan Patrol Y60',
              );

              if (isWide) {
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(flex: 6, child: text),
                    const SizedBox(width: 28),
                    Expanded(flex: 5, child: image),
                  ],
                );
              }

              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  text,
                  const SizedBox(height: 20),
                  image,
                ],
              );
            },
          ),
        ),
      ],
    );
  }
}

class PremiumGlassPanel extends StatelessWidget {
  const PremiumGlassPanel({super.key, required this.child, this.padding});

  final Widget child;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: padding ?? const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: const Color(0xB3121212),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(0xB8875A32)),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFFF8A1E).withValues(alpha: 0.18),
                blurRadius: 24,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: child,
        ),
      ),
    );
  }
}

class HeroCopy extends StatelessWidget {
  const HeroCopy({super.key, required this.generation});

  final PatrolGeneration generation;

  @override
  Widget build(BuildContext context) {
    final profile = generation.vehicleProfile;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'نيسان باترول Y60',
          style: TextStyle(
            color: Colors.white,
            fontSize: 36,
            height: 1.2,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          '${generation.code} • ${profile?.engineCode ?? 'TB42S'} • ${profile?.transmissionCode ?? 'FS5R50A'}',
          style: const TextStyle(
            color: Color(0xFFE6DBD0),
            fontSize: 19,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 16),
        const Text(
          'تطبيق وموقع Offline-first لإدارة كتالوج وقطع Nissan Patrol Safari Y60 SGL موديل 1991/1992، مبني بقاعدة JSON محلية ومرتبط بملفات PDF الأصلية من 1988 إلى 1997.',
          style: TextStyle(
            color: Color(0xFFD8D2CC),
            fontSize: 16,
            height: 1.65,
          ),
        ),
        const SizedBox(height: 18),
        const Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            HeroBadge(text: 'عربي و RTL'),
            HeroBadge(text: 'Offline-first'),
            HeroBadge(text: '5271 نتيجة'),
            HeroBadge(text: '11 ملف PDF'),
            HeroBadge(text: 'Web + Windows'),
          ],
        ),
        const SizedBox(height: 24),
        const Text(
          'الخدمات الرئيسية',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: const [
            HeroServiceButton(
              icon: Icons.add_box,
              title: 'إضافة القطع',
              subtitle: 'تسجيل القطع وربطها بالكتالوج',
              target: 'parts',
            ),
            HeroServiceButton(
              icon: Icons.report_problem,
              title: 'إضافة الأعطال',
              subtitle: 'جمع الأعطال وحلولها',
              target: 'issues',
            ),
            HeroServiceButton(
              icon: Icons.build,
              title: 'إضافة الصيانة',
              subtitle: 'جداول وملاحظات الصيانة',
              target: 'maintenance',
            ),
            HeroServiceButton(
              icon: Icons.picture_as_pdf,
              title: 'الكتالوجات',
              subtitle: 'التأكد من توفر الملفات',
              target: 'catalogs',
            ),
            HeroServiceButton(
              icon: Icons.storage,
              title: 'قاعدة البيانات',
              subtitle: 'مصادر الفهرسة والربط',
              target: 'database',
            ),
            HeroServiceButton(
              icon: Icons.menu_book,
              title: 'الشروحات',
              subtitle: 'شرح الاستخدام والأقسام',
              target: 'guide',
            ),
          ],
        ),
      ],
    );
  }
}

class HeroServiceButton extends StatelessWidget {
  const HeroServiceButton({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.target,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final String target;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 190,
      child: Material(
        color: const Color(0xFF2F2A27),
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: () => HeaderMenuButton.openItem(context, target),
          child: Container(
            constraints: const BoxConstraints(minHeight: 92),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFF6B625B)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(icon, color: const Color(0xFFE7C8A1), size: 24),
                const SizedBox(height: 8),
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFFD8D2CC),
                    fontSize: 12,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class HeroBadge extends StatelessWidget {
  const HeroBadge({super.key, required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF3A332F),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFF6B625B)),
      ),
      child: Text(
        text,
        style:
            const TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
      ),
    );
  }
}

class VehicleHeroImage extends StatelessWidget {
  const VehicleHeroImage({super.key, required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 0.70,
      child: PremiumGlassPanel(
        padding: const EdgeInsets.all(16),
        child: Stack(
          children: [
            Positioned.fill(
              child: CustomPaint(painter: EngineeringGridPainter()),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.account_tree,
                        color: Color(0xFFFF8A1E), size: 24),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                const Text(
                  'المخطط الهندسي • TB42S + FS5R50A',
                  style: TextStyle(color: Color(0xFFE7C8A1)),
                ),
                const Spacer(),
                Center(
                  child: Container(
                    width: 230,
                    height: 150,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      gradient: const LinearGradient(
                        colors: [Color(0xFF2B2A27), Color(0xFF0D0E0E)],
                      ),
                      border: Border.all(color: Color(0xFF8C5A2B)),
                    ),
                    child: Stack(
                      children: const [
                        Positioned(
                          right: 28,
                          top: 42,
                          child: Icon(Icons.settings,
                              size: 72, color: Color(0xFFE7C8A1)),
                        ),
                        Positioned(
                          left: 30,
                          top: 58,
                          child: Icon(Icons.precision_manufacturing,
                              size: 56, color: Color(0xFFFF8A1E)),
                        ),
                        Positioned(
                          right: 36,
                          bottom: 18,
                          child: Text(
                            'TB42S',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                        Positioned(
                          left: 22,
                          bottom: 18,
                          child: Text(
                            'FS5R50A',
                            style: TextStyle(
                              color: Color(0xFFFF8A1E),
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const Spacer(),
                const Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    EngineeringChip(text: '6 سلندر'),
                    EngineeringChip(text: 'ناقل يدوي 5 سرعات'),
                    EngineeringChip(text: 'كتالوج OEM'),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class EngineeringChip extends StatelessWidget {
  const EngineeringChip({super.key, required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0x991B1714),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFF6F4A2B)),
      ),
      child: Text(
        text,
        style: const TextStyle(color: Color(0xFFE7C8A1), fontSize: 12),
      ),
    );
  }
}

class EngineeringGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0x33E7C8A1)
      ..strokeWidth = 0.6;
    const step = 22.0;
    for (var x = 0.0; x <= size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (var y = 0.0; y <= size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class SearchSection extends StatefulWidget {
  const SearchSection({super.key});

  @override
  State<SearchSection> createState() => _SearchSectionState();
}

class _SearchSectionState extends State<SearchSection> {
  final _controller = TextEditingController();
  Timer? _searchDebounce;
  CatalogSearchIndex? _index;
  bool _isLoadingIndex = false;
  List<CatalogSearchEntry> _results = const [];

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _scheduleSearch(String rawQuery) {
    _searchDebounce?.cancel();
    setState(() {});
    _searchDebounce = Timer(
      const Duration(milliseconds: 280),
      () => _runSearch(rawQuery),
    );
  }

  Future<void> _runSearch(String rawQuery) async {
    final index = _index;
    final query = _normalize(rawQuery);
    setState(() {
      if (query.length < 2) {
        _results = const [];
        return;
      }
    });

    var loadedIndex = index;
    if (loadedIndex == null) {
      setState(() => _isLoadingIndex = true);
      loadedIndex = await CatalogSearchIndex.load();
      if (!mounted) return;
      setState(() {
        _index = loadedIndex;
        _isLoadingIndex = false;
      });
    }

    setState(() {
      final scored = <CatalogSearchScore>[];
      for (final entry in loadedIndex!.entries) {
        final score = entry.scoreFor(query, _normalize);
        if (score > 0) {
          scored.add(CatalogSearchScore(entry, score));
        }
      }
      scored.sort((a, b) => b.score.compareTo(a.score));
      _results = scored.take(25).map((item) => item.entry).toList();
    });
  }

  String _normalize(String value) {
    return normalizeCatalogQuery(value);
  }

  Future<void> _openHit(BuildContext context, CatalogSearchEntry hit) async {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => Directionality(
          textDirection: TextDirection.rtl,
          child: CatalogEntryDetailPage(entry: hit),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PageShell(
      top: 22,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth >= 760;
              final index = _index;
              final copy = Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'بحث الكتالوج',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(index == null
                      ? 'اكتب للبحث، وسيتم تحميل فهرس الكتالوج عند الحاجة.'
                      : 'بحث فعلي داخل ${index.entries.length} صفحة وبيان من كتالوجات Y60.'),
                ],
              );
                final field = TextField(
                controller: _controller,
                onChanged: _scheduleSearch,
                onSubmitted: _runSearch,
                textDirection: TextDirection.ltr,
                decoration: InputDecoration(
                  hintText:
                      'رقم القطعة / الاسم العربي / English / WGY60348567 / TB42S',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: _controller.text.isEmpty
                      ? null
                      : IconButton(
                          tooltip: 'مسح البحث',
                          onPressed: () {
                            _controller.clear();
                            _runSearch('');
                          },
                          icon: const Icon(Icons.close),
                        ),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8)),
                ),
              );

              final searchHeader = isWide
                  ? Row(
                      children: [
                        Expanded(child: copy),
                        const SizedBox(width: 16),
                        Expanded(child: field),
                      ],
                    )
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        copy,
                        const SizedBox(height: 14),
                        field,
                      ],
                    );

              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  searchHeader,
                  if (_controller.text.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    if (_isLoadingIndex)
                      const LinearProgressIndicator()
                    else if (_results.isEmpty)
                      const Text(
                        'لا توجد نتيجة مطابقة. جرّب رقم الهيكل بدون شرطة أو ابحث بكود القطعة.',
                        style: TextStyle(color: Color(0xFFFFB15C)),
                      )
                    else
                      ..._results.map(
                        (hit) => Card(
                          child: ListTile(
                            title: Text(hit.titleAr),
                            subtitle: Text(
                              '${hit.titleEn}\n${hit.subtitleAr}\n${hit.sectionTitleAr}${hit.snippet.isEmpty ? '' : ' - ${hit.snippet}'}',
                              maxLines: 3,
                              overflow: TextOverflow.ellipsis,
                            ),
                            leading: CircleAvatar(
                              backgroundColor: const Color(0xFF2A1D14),
                              foregroundColor: const Color(0xFFFF8A1E),
                              child: Text(hit.year),
                            ),
                            trailing: const Icon(Icons.chevron_left),
                            onTap: () => _openHit(context, hit),
                          ),
                        ),
                      ),
                  ],
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class CatalogSearchIndex {
  const CatalogSearchIndex({required this.entries});

  final List<CatalogSearchEntry> entries;
  static Future<CatalogSearchIndex>? _cachedFuture;

  static Future<CatalogSearchIndex> load() async {
    return _cachedFuture ??= _load();
  }

  static Future<CatalogSearchIndex> _load() async {
    final raw = await rootBundle
        .loadString('assets/catalog/search/catalog_search_index.json');
    final jsonMap = jsonDecode(raw) as Map<String, dynamic>;
    final entries = (jsonMap['entries'] as List<dynamic>)
        .map(
            (item) => CatalogSearchEntry.fromJson(item as Map<String, dynamic>))
        .toList(growable: false);
    return CatalogSearchIndex(entries: entries);
  }

  List<CatalogSectionSummary> sectionSummaries() {
    final counts = <String, int>{};
    final titles = <String, String>{};
    for (final entry in entries) {
      counts.update(entry.sectionId, (value) => value + 1, ifAbsent: () => 1);
      titles.putIfAbsent(entry.sectionId, () => entry.sectionTitleAr);
    }

    final summaries = <CatalogSectionSummary>[];
    for (final definition in catalogSectionDefinitions) {
      final count = counts[definition.id] ?? 0;
      summaries.add(
        CatalogSectionSummary(
          definition: definition,
          title: definition.titleAr,
          count: count,
        ),
      );
    }

    final knownIds = catalogSectionDefinitions.map((item) => item.id).toSet();
    for (final id in counts.keys.where((id) => !knownIds.contains(id))) {
      summaries.add(
        CatalogSectionSummary(
          definition: CatalogSectionDefinition(
            id: id,
            titleAr: titles[id] ?? id,
            descriptionAr: 'صفحات مفهرسة من قاعدة بيانات الكتالوج.',
            icon: Icons.folder,
          ),
          title: titles[id] ?? id,
          count: counts[id] ?? 0,
        ),
      );
    }

    summaries.sort((a, b) {
      final orderA = catalogSectionDefinitions
          .indexWhere((definition) => definition.id == a.definition.id);
      final orderB = catalogSectionDefinitions
          .indexWhere((definition) => definition.id == b.definition.id);
      final safeA = orderA < 0 ? 999 : orderA;
      final safeB = orderB < 0 ? 999 : orderB;
      return safeA.compareTo(safeB);
    });
    return summaries;
  }

  List<CatalogSearchEntry> entriesForSection(String sectionId) {
    final filtered = entries
        .where((entry) => entry.sectionId == sectionId)
        .toList(growable: false);
    return filtered.take(250).toList(growable: false);
  }
}

String normalizeCatalogQuery(String value) {
  return value
      .toLowerCase()
      .replaceAll(RegExp(r'[\u064B-\u065F\u0670]'), '')
      .replaceAll('أ', 'ا')
      .replaceAll('إ', 'ا')
      .replaceAll('آ', 'ا')
      .replaceAll('ى', 'ي')
      .replaceAll('ة', 'ه')
      .replaceAll('ؤ', 'و')
      .replaceAll('ئ', 'ي')
      .replaceAll(RegExp(r'[^a-z0-9\u0600-\u06FF]+'), '');
}

class PartsCatalogPage extends StatefulWidget {
  const PartsCatalogPage({super.key});

  @override
  State<PartsCatalogPage> createState() => _PartsCatalogPageState();
}

class _PartsCatalogPageState extends State<PartsCatalogPage> {
  final _controller = TextEditingController();
  Timer? _searchDebounce;
  late final Future<CatalogSearchIndex> _searchIndexFuture;
  late final Future<CatalogSectionIndex> _sectionIndexFuture;
  List<CatalogSearchEntry> _results = const [];
  CatalogSearchIndex? _loadedIndex;

  @override
  void initState() {
    super.initState();
    _searchIndexFuture = CatalogSearchIndex.load();
    _sectionIndexFuture = CatalogSectionIndex.load();
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _scheduleSearch(String rawQuery) {
    _searchDebounce?.cancel();
    setState(() {});
    _searchDebounce = Timer(
      const Duration(milliseconds: 280),
      () => _runSearch(rawQuery),
    );
  }

  String _normalize(String value) {
    return normalizeCatalogQuery(value);
  }

  Future<void> _runSearch(String rawQuery) async {
    final query = _normalize(rawQuery);
    if (query.length < 2) {
      setState(() => _results = const []);
      return;
    }

    final index = _loadedIndex ?? await _searchIndexFuture;
    _loadedIndex = index;
    final scored = <CatalogSearchScore>[];
    for (final entry in index.entries) {
      if (entry.type == 'vehicle') continue;
      final score = entry.scoreFor(query, _normalize);
      if (score > 0) scored.add(CatalogSearchScore(entry, score));
    }
    scored.sort((a, b) => b.score.compareTo(a.score));
    if (!mounted) return;
    setState(() {
      _results = scored.take(40).map((item) => item.entry).toList();
    });
  }

  void _openEntry(CatalogSearchEntry entry) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => Directionality(
          textDirection: TextDirection.rtl,
          child: CatalogEntryDetailPage(entry: entry),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('القطع')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'بحث القطع من فهرس الكتالوج',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'ابحث برقم القطعة، رقم النداء، اسم المجموعة، كود المحرك، أو رقم الهيكل. النتائج مرتبطة مباشرة بصفحات PDF الأصلية.',
                    style: TextStyle(color: Color(0xFFD8D2CC), height: 1.5),
                  ),
                  const SizedBox(height: 14),
                  FutureBuilder<CatalogSearchIndex>(
                    future: _searchIndexFuture,
                    builder: (context, snapshot) {
                      final loadedCount = snapshot.data?.entries.length;
                      return TextField(
                        controller: _controller,
                        onChanged: _scheduleSearch,
                        onSubmitted: _runSearch,
                        textDirection: TextDirection.ltr,
                        decoration: InputDecoration(
                          labelText: loadedCount == null
                              ? 'جاري تحميل فهرس القطع...'
                              : 'الفهرس جاهز: $loadedCount نتيجة',
                          hintText:
                              'مثال: WGY60348567 / TB42S / FS5R50A / 27500 / مفتاح / SWITCH',
                          prefixIcon: const Icon(Icons.manage_search),
                          suffixIcon: _controller.text.isEmpty
                              ? null
                              : IconButton(
                                  tooltip: 'مسح',
                                  onPressed: () {
                                    _controller.clear();
                                    _runSearch('');
                                  },
                                  icon: const Icon(Icons.close),
                                ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          if (_controller.text.isNotEmpty)
            _PartsSearchResults(
              results: _results,
              onOpen: _openEntry,
            )
          else
            FutureBuilder<CatalogSectionIndex>(
              future: _sectionIndexFuture,
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Card(
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: LinearProgressIndicator(minHeight: 3),
                    ),
                  );
                }

                final sections = snapshot.data!.sections
                    .where((section) => section.id != 'vehicle')
                    .toList(growable: false);
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                      'أقسام القطع من الفهرس',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 10),
                    ...sections.map(
                      (section) => Card(
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: const Color(0xFF2A1A12),
                            foregroundColor: const Color(0xFFFFB15C),
                            child: Text(section.count.toString()),
                          ),
                          title: Text(section.titleAr),
                          subtitle:
                              Text('${section.count} صفحة/نتيجة مفهرسة'),
                          trailing: const Icon(
                            Icons.chevron_left,
                            color: Color(0xFFFFB15C),
                          ),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => Directionality(
                                  textDirection: TextDirection.rtl,
                                  child: CatalogSectionPage(
                                    section: section.toSummary().title,
                                    entries: section.entries,
                                    totalCount: section.count,
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
        ],
      ),
    );
  }
}

class _PartsSearchResults extends StatelessWidget {
  const _PartsSearchResults({required this.results, required this.onOpen});

  final List<CatalogSearchEntry> results;
  final ValueChanged<CatalogSearchEntry> onOpen;

  @override
  Widget build(BuildContext context) {
    if (results.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Text(
            'لا توجد نتيجة مطابقة. جرّب رقم القطعة بدون شرطة أو ابحث باسم المجموعة.',
            style: TextStyle(color: Color(0xFFFFB15C), height: 1.5),
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'نتائج البحث: ${results.length}',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 10),
        ...results.map(
          (entry) => Card(
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: const Color(0xFF2A1A12),
                foregroundColor: const Color(0xFFFFB15C),
                child: Text(entry.year),
              ),
              title: Text(
                entry.titleAr,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              subtitle: Text(
                '${entry.titleEn}\n${entry.sectionTitleAr} - ${entry.subtitleAr}\n${entry.snippet}',
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
              trailing: const Icon(
                Icons.chevron_left,
                color: Color(0xFFFFB15C),
              ),
              onTap: () => onOpen(entry),
            ),
          ),
        ),
      ],
    );
  }
}

Future<void> openCatalogEntry(
  BuildContext context,
  CatalogSearchEntry entry,
) async {
  final baseUrl = Uri.base.resolve('assets/${entry.sourcePdfPath}').toString();
  final pageSuffix = entry.pageNumber > 0 ? '#page=${entry.pageNumber}' : '';
  await openAssetUrl('$baseUrl$pageSuffix');
  if (context.mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('تم فتح ${entry.titleAr}')),
    );
  }
}

class CatalogSearchScore {
  const CatalogSearchScore(this.entry, this.score);

  final CatalogSearchEntry entry;
  final int score;
}

class CatalogSectionIndex {
  const CatalogSectionIndex({
    required this.totalEntries,
    required this.sections,
  });

  final int totalEntries;
  final List<CatalogSectionData> sections;
  static Future<CatalogSectionIndex>? _cachedFuture;

  static Future<CatalogSectionIndex> load() async {
    return _cachedFuture ??= _load();
  }

  static Future<CatalogSectionIndex> _load() async {
    final raw = await rootBundle
        .loadString('assets/catalog/search/catalog_section_index.json');
    final jsonMap = jsonDecode(raw) as Map<String, dynamic>;
    final sections = (jsonMap['sections'] as List<dynamic>)
        .map((item) => CatalogSectionData.fromJson(
              item as Map<String, dynamic>,
            ))
        .toList(growable: false);
    return CatalogSectionIndex(
      totalEntries: jsonMap['totalEntries'] as int,
      sections: sections,
    );
  }
}

class CatalogSectionData {
  const CatalogSectionData({
    required this.id,
    required this.titleAr,
    required this.count,
    required this.entries,
  });

  final String id;
  final String titleAr;
  final int count;
  final List<CatalogSearchEntry> entries;

  factory CatalogSectionData.fromJson(Map<String, dynamic> json) {
    return CatalogSectionData(
      id: json['id'] as String,
      titleAr: json['titleAr'] as String,
      count: json['count'] as int,
      entries: (json['entries'] as List<dynamic>? ?? const [])
          .map((item) => CatalogSearchEntry.fromJson(
                item as Map<String, dynamic>,
              ))
          .toList(growable: false),
    );
  }

  CatalogSectionSummary toSummary() {
    final definition = catalogSectionDefinitions.firstWhere(
      (item) => item.id == id,
      orElse: () => CatalogSectionDefinition(
        id: id,
        titleAr: titleAr,
        descriptionAr: 'صفحات مفهرسة من قاعدة بيانات الكتالوج.',
        icon: Icons.folder,
      ),
    );
    return CatalogSectionSummary(
      definition: definition,
      title: definition.titleAr,
      count: count,
    );
  }
}

class CatalogSearchEntry {
  const CatalogSearchEntry({
    required this.id,
    required this.type,
    required this.year,
    required this.titleAr,
    required this.titleEn,
    required this.subtitleAr,
    required this.sectionId,
    required this.sectionTitleAr,
    required this.sourcePdfPath,
    required this.pageNumber,
    required this.keywords,
    required this.snippet,
    required this.queryText,
  });

  final String id;
  final String type;
  final String year;
  final String titleAr;
  final String titleEn;
  final String subtitleAr;
  final String sectionId;
  final String sectionTitleAr;
  final String sourcePdfPath;
  final int pageNumber;
  final List<String> keywords;
  final String snippet;
  final String queryText;

  factory CatalogSearchEntry.fromJson(Map<String, dynamic> json) {
    return CatalogSearchEntry(
      id: json['id'] as String,
      type: json['type'] as String,
      year: json['year'] as String,
      titleAr: json['titleAr'] as String,
      titleEn: json['titleEn'] as String? ?? json['titleAr'] as String,
      subtitleAr: json['subtitleAr'] as String,
      sectionId: json['sectionId'] as String,
      sectionTitleAr: json['sectionTitleAr'] as String,
      sourcePdfPath: json['sourcePdfPath'] as String,
      pageNumber: json['pageNumber'] as int,
      keywords: (json['keywords'] as List<dynamic>? ?? const [])
          .map((item) => item.toString())
          .toList(growable: false),
      snippet: json['snippet'] as String? ?? '',
      queryText: json['queryText'] as String? ?? '',
    );
  }

  int scoreFor(String normalizedQuery, String Function(String) normalize) {
    var score = 0;
    final title = normalize(titleAr);
    final englishTitle = normalize(titleEn);
    final subtitle = normalize(subtitleAr);
    final section = normalize(sectionTitleAr);
    final haystack = normalize('$queryText $snippet $titleEn');

    if (title == normalizedQuery) score += 120;
    if (englishTitle == normalizedQuery) score += 120;
    if (title.contains(normalizedQuery)) score += 80;
    if (englishTitle.contains(normalizedQuery)) score += 80;
    if (subtitle.contains(normalizedQuery)) score += 55;
    if (section.contains(normalizedQuery)) score += 35;

    for (final keyword in keywords) {
      final normalizedKeyword = normalize(keyword);
      if (normalizedKeyword == normalizedQuery) score += 130;
      if (normalizedKeyword.contains(normalizedQuery)) score += 65;
    }

    if (haystack.contains(normalizedQuery)) score += 25;
    if (type == 'vehicle') score += 20;
    return score;
  }
}

class CatalogPdfSection extends StatelessWidget {
  const CatalogPdfSection({super.key});

  static const catalogs = [
    CatalogPdf(
        'WGY',
        'ملف WGY60348567',
        'ملف السيارة الخاص General Asia LHD Wagon TB42S SGL',
        'assets/catalog/pdfs/wgy60348567_vehicle_catalog.pdf',
        '6.5 MB'),
    CatalogPdf('1988', 'Y60 1988', 'بداية جيل Y60',
        'assets/catalog/pdfs/y60_1988.pdf', '12.0 MB'),
    CatalogPdf('1989', 'Y60 1989', 'كتالوج سنة 1989',
        'assets/catalog/pdfs/y60_1989.pdf', '12.0 MB'),
    CatalogPdf('1990', 'Y60 1990', 'كتالوج سنة 1990',
        'assets/catalog/pdfs/y60_1990.pdf', '12.0 MB'),
    CatalogPdf('1991', 'Y60 1991', 'مناسب لبيانات WGY60 10/1991',
        'assets/catalog/pdfs/y60_1991.pdf', '13.7 MB'),
    CatalogPdf('1992', 'Y60 1992', 'كتالوج موديل الاستمارة 1992',
        'assets/catalog/pdfs/y60_1992.pdf', '13.4 MB'),
    CatalogPdf('1993', 'Y60 1993', 'كتالوج سنة 1993',
        'assets/catalog/pdfs/y60_1993.pdf', '13.4 MB'),
    CatalogPdf('1994', 'Y60 1994', 'كتالوج سنة 1994',
        'assets/catalog/pdfs/y60_1994.pdf', '12.0 MB'),
    CatalogPdf('1995', 'Y60 1995', 'كتالوج سنة 1995',
        'assets/catalog/pdfs/y60_1995.pdf', '11.8 MB'),
    CatalogPdf('1996', 'Y60 1996', 'كتالوج سنة 1996',
        'assets/catalog/pdfs/y60_1996.pdf', '11.7 MB'),
    CatalogPdf('1997', 'Y60 1997', 'آخر سنوات جيل Y60',
        'assets/catalog/pdfs/y60_1997.pdf', '11.7 MB'),
  ];

  @override
  Widget build(BuildContext context) {
    return PageShell(
      title: 'كتالوجات Y60 الرسمية',
      subtitle:
          'تم فرز الملفات حسب السنة وربطها كملفات PDF أصلية عالية الجودة.',
      child: LayoutBuilder(
        builder: (context, constraints) {
          final columns = constraints.maxWidth >= 980
              ? 3
              : constraints.maxWidth >= 640
                  ? 2
                  : 1;

          return GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: catalogs.length,
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: columns,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              mainAxisExtent: 176,
            ),
            itemBuilder: (context, index) =>
                CatalogPdfCard(catalog: catalogs[index]),
          );
        },
      ),
    );
  }
}

class CatalogPdf {
  const CatalogPdf(this.year, this.title, this.note, this.assetPath, this.size);

  final String year;
  final String title;
  final String note;
  final String assetPath;
  final String size;
}

class CatalogPdfCard extends StatelessWidget {
  const CatalogPdfCard({super.key, required this.catalog});

  final CatalogPdf catalog;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFFF8A1E), Color(0xFF7A1F2B)],
                    ),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFE7C8A1)),
                  ),
                  child: Text(
                    catalog.year,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        catalog.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            fontSize: 17, fontWeight: FontWeight.w900),
                      ),
                      Text(
                        catalog.size,
                        style: const TextStyle(
                            color: Color(0xFFFFB15C),
                            fontWeight: FontWeight.w700),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              catalog.note,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: Color(0xFFD8D2CC)),
            ),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: () => _openCatalog(context),
                icon: const Icon(Icons.picture_as_pdf),
                label: const Text('فتح PDF'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openCatalog(BuildContext context) async {
    final url = Uri.base.resolve('assets/${catalog.assetPath}').toString();
    await openAssetUrl(url);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('تم فتح ${catalog.title} في تبويب جديد.')),
      );
    }
  }
}

class DatabaseOverviewSection extends StatefulWidget {
  const DatabaseOverviewSection({super.key});

  @override
  State<DatabaseOverviewSection> createState() =>
      _DatabaseOverviewSectionState();
}

class _DatabaseOverviewSectionState extends State<DatabaseOverviewSection> {
  late final Future<CatalogSectionIndex> _sectionIndexFuture;

  @override
  void initState() {
    super.initState();
    _sectionIndexFuture = CatalogSectionIndex.load();
  }

  @override
  Widget build(BuildContext context) {
    return PageShell(
      title: 'قاعدة بيانات الموقع والتطبيق',
      subtitle:
          'نفس الفهرس يغذي البحث، أقسام الكتالوج، نسخة المتصفح، وتطبيق ويندوز.',
      child: FutureBuilder<CatalogSectionIndex>(
        future: _sectionIndexFuture,
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Card(
              child: Padding(
                padding: EdgeInsets.all(18),
                child: LinearProgressIndicator(minHeight: 3),
              ),
            );
          }

          final index = snapshot.data!;
          final stats = [
            DatabaseStat(
              'الأقسام',
              index.sections.length.toString(),
              Icons.dashboard_customize,
            ),
            DatabaseStat(
              'النتائج المفهرسة',
              index.totalEntries.toString(),
              Icons.manage_search,
            ),
            DatabaseStat(
              'ملفات PDF',
              CatalogPdfSection.catalogs.length.toString(),
              Icons.picture_as_pdf,
            ),
            const DatabaseStat(
              'النطاق',
              '1988 - 1997',
              Icons.date_range,
            ),
          ];

          final topSections = index.sections.take(6).toList(growable: false);

          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              LayoutBuilder(
                builder: (context, constraints) {
                  final columns = constraints.maxWidth >= 900
                      ? 4
                      : constraints.maxWidth >= 560
                          ? 2
                          : 1;
                  return GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: stats.length,
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: columns,
                      crossAxisSpacing: 10,
                      mainAxisSpacing: 10,
                      mainAxisExtent: 104,
                    ),
                    itemBuilder: (context, itemIndex) =>
                        DatabaseStatCard(stat: stats[itemIndex]),
                  );
                },
              ),
              const SizedBox(height: 12),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: topSections
                        .map(
                          (section) => Chip(
                            avatar: const Icon(
                              Icons.folder_open,
                              size: 18,
                              color: Color(0xFFFFB15C),
                            ),
                            label: Text(
                              '${section.titleAr} • ${section.count}',
                              overflow: TextOverflow.ellipsis,
                            ),
                            backgroundColor: const Color(0xFF211814),
                            side: const BorderSide(color: Color(0xFF7C5A3B)),
                            labelStyle:
                                const TextStyle(color: Color(0xFFEDE4DA)),
                          ),
                        )
                        .toList(growable: false),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              const Card(
                child: Padding(
                  padding: EdgeInsets.all(14),
                  child: Text(
                    'مصادر البيانات مركبة داخل التطبيق: catalog_search_index.json للبحث، catalog_section_index.json للأقسام، وملفات PDF الأصلية داخل assets/catalog/pdfs. التطبيق يعمل حالياً بدون تسجيل دخول وبدون Backend، لذلك يمكن تشغيله على الويب وويندوز مع قابلية نقله لاحقاً إلى Android و iOS.',
                    style: TextStyle(color: Color(0xFFD8D2CC), height: 1.55),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class DatabaseStat {
  const DatabaseStat(this.label, this.value, this.icon);

  final String label;
  final String value;
  final IconData icon;
}

class DatabaseStatCard extends StatelessWidget {
  const DatabaseStatCard({super.key, required this.stat});

  final DatabaseStat stat;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: const Color(0xFF2A1A12),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFF8C5A2B)),
              ),
              child: Icon(stat.icon, color: const Color(0xFFFF8A1E)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    stat.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Color(0xFFE7C8A1),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    stat.value,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textDirection: TextDirection.ltr,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class AppCompletionSection extends StatelessWidget {
  const AppCompletionSection({super.key});

  static const items = [
    AppCompletionItem(
      Icons.web,
      'تطبيق ويب',
      'واجهة Flutter Web جاهزة للتشغيل محلياً ومرتبطة بفهرس Y60.',
    ),
    AppCompletionItem(
      Icons.desktop_windows,
      'تطبيق ويندوز',
      'البنية نفسها تعمل كتطبيق Windows عند توفر بيئة Flutter المناسبة.',
    ),
    AppCompletionItem(
      Icons.storage,
      'Offline-first',
      'البيانات الأساسية داخل assets: JSON للفهارس وPDF للكتالوجات.',
    ),
    AppCompletionItem(
      Icons.search,
      'بحث فعلي',
      'يدعم رقم القطعة، العربي، الإنجليزي، WGY60348567، TB42S، وFS5R50A.',
    ),
    AppCompletionItem(
      Icons.description,
      'تفاصيل قبل PDF',
      'كل نتيجة تفتح صفحة تفاصيل تعرض المصدر، الصفحة، الأرقام، والملاحظات.',
    ),
    AppCompletionItem(
      Icons.phone_iphone,
      'جاهز للتوسع',
      'البنية مهيأة لاحقاً لأندرويد و iOS وقاعدة بيانات قابلة للتحرير.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return PageShell(
      title: 'حالة التطبيق المتكامل',
      subtitle:
          'ملخص تنفيذي لما أصبح جاهزاً داخل Patrol Hub وما يجعله قابلاً للتطوير كتطبيق كامل.',
      child: LayoutBuilder(
        builder: (context, constraints) {
          final columns = constraints.maxWidth >= 980
              ? 3
              : constraints.maxWidth >= 620
                  ? 2
                  : 1;

          return GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: items.length,
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: columns,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              mainAxisExtent: 150,
            ),
            itemBuilder: (context, index) => AppCompletionCard(
              item: items[index],
            ),
          );
        },
      ),
    );
  }
}

class AppCompletionItem {
  const AppCompletionItem(this.icon, this.title, this.body);

  final IconData icon;
  final String title;
  final String body;
}

class AppCompletionCard extends StatelessWidget {
  const AppCompletionCard({super.key, required this.item});

  final AppCompletionItem item;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: const Color(0xFF2A1A12),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFF8C5A2B)),
                  ),
                  child: Icon(item.icon, color: const Color(0xFFFF8A1E)),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    item.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 17,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              item.body,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Color(0xFFD8D2CC),
                height: 1.45,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class GlobalReferenceVisionSection extends StatelessWidget {
  const GlobalReferenceVisionSection({super.key});

  static const pillars = [
    VisionPillar(
      Icons.account_tree,
      'قاعدة بيانات احترافية',
      'رسومات أصلية، OEM، أسماء متعددة اللغات، وظيفة القطعة، موقعها، الصور، والأبعاد عند توفرها.',
    ),
    VisionPillar(
      Icons.compare_arrows,
      'توافق القطع',
      'ربط القطعة بأجيال Y60 وY61 وY62 مستقبلاً، مع السنة والمحرك والقير والفئة.',
    ),
    VisionPillar(
      Icons.manage_search,
      'البحث الذكي',
      'بحث بالرقم، الاسم، العربية، الإنجليزية، VIN، والقسم الفني.',
    ),
    VisionPillar(
      Icons.price_change,
      'مقارنة الأسعار',
      'عرض السعر، العملة، الشحن، مدة التوصيل، الدولة، وحالة القطعة.',
    ),
    VisionPillar(
      Icons.verified,
      'تصنيف نوع القطعة',
      'OEM، مصنع أصلي، إعادة تصنيع عالية الجودة، بديل تجاري، مستعملة أصلية، وNOS.',
    ),
    VisionPillar(
      Icons.signal_cellular_alt,
      'مؤشر الندرة',
      'متوفرة، محدودة، نادرة، أو موقوفة الإنتاج NLA.',
    ),
    VisionPillar(
      Icons.build_circle,
      'الصيانة والشروحات',
      'أعراض التلف، سبب التعطل، العمر الافتراضي، العزم، الأدوات، وخطوات الفك والتركيب.',
    ),
    VisionPillar(
      Icons.groups,
      'المجتمع والمتاجر',
      'تقييمات، تجارب ملاك، مشاريع ترميم، متاجر عالمية وخليجية، تشاليح، وبائعون موثقون.',
    ),
    VisionPillar(
      Icons.psychology,
      'الذكاء الاصطناعي',
      'تعرف على القطعة من صورة، اقتراح بدائل، واستخراج تشخيص أولي من وصف العطل.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return PageShell(
      title: 'الرؤية العالمية لتطبيق الباترول',
      subtitle:
          'خارطة مزايا تجعل Patrol Hub مرجعاً شاملاً للقطع، الأسعار، الصيانة، المجتمع، والذكاء الاصطناعي.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          LayoutBuilder(
            builder: (context, constraints) {
              final columns = constraints.maxWidth >= 1040
                  ? 3
                  : constraints.maxWidth >= 680
                      ? 2
                      : 1;
              return GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: pillars.length,
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: columns,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  mainAxisExtent: 166,
                ),
                itemBuilder: (context, index) =>
                    VisionPillarCard(pillar: pillars[index]),
              );
            },
          ),
          const SizedBox(height: 12),
          const Card(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                'الهدف النهائي: أن يصبح التطبيق المرجع العالمي الأول لملاك نيسان باترول، بحيث يجد المستخدم كل ما يحتاجه عن أي قطعة في مكان واحد دون التنقل بين عشرات المواقع والمتاجر.',
                style: TextStyle(
                  color: Color(0xFFEDE4DA),
                  fontSize: 16,
                  height: 1.6,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class VisionPillar {
  const VisionPillar(this.icon, this.title, this.body);

  final IconData icon;
  final String title;
  final String body;
}

class VisionPillarCard extends StatelessWidget {
  const VisionPillarCard({super.key, required this.pillar});

  final VisionPillar pillar;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(pillar.icon, color: const Color(0xFFFF8A1E), size: 30),
            const SizedBox(height: 10),
            Text(
              pillar.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 17,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              pillar.body,
              maxLines: 4,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: Color(0xFFD8D2CC), height: 1.45),
            ),
          ],
        ),
      ),
    );
  }
}

class ImplementationGuideSection extends StatelessWidget {
  const ImplementationGuideSection({super.key});

  static const items = [
    GuideItem(
      Icons.folder_copy,
      'مصادر قاعدة البيانات',
      'كتالوجات Y60 من 1988 إلى 1997، ملف WGY60348567، فهرس البحث، وفهرس الأقسام.',
    ),
    GuideItem(
      Icons.account_tree,
      'طريقة الفرز',
      'كل صفحة تُربط بقسمها: محرك، قير، دفرنسات، بدي، داخلية، كهرباء، تكييف، أو عام.',
    ),
    GuideItem(
      Icons.manage_search,
      'طريقة البحث',
      'البحث يقارن رقم الهيكل، رقم القطعة، السنة، عنوان الصفحة، الكلمات المفتاحية، ووصف الصفحة.',
    ),
    GuideItem(
      Icons.install_mobile,
      'طريقة التركيب',
      'نفس ملفات الأصول والفهارس تُبنى للويب وويندوز، ويمكن نقلها لاحقاً لتطبيق Android و iOS.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return PageShell(
      title: 'طريقة التركيب وقواعد البيانات',
      subtitle:
          'معلومات تشغيلية مختصرة توضّح كيف تم تعبئة الموقع والتطبيق من ملفات الكتالوج.',
      child: LayoutBuilder(
        builder: (context, constraints) {
          final columns = constraints.maxWidth >= 960
              ? 4
              : constraints.maxWidth >= 620
                  ? 2
                  : 1;
          return GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: items.length,
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: columns,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              mainAxisExtent: 174,
            ),
            itemBuilder: (context, index) => GuideCard(item: items[index]),
          );
        },
      ),
    );
  }
}

class GuideItem {
  const GuideItem(this.icon, this.title, this.body);

  final IconData icon;
  final String title;
  final String body;
}

class GuideCard extends StatelessWidget {
  const GuideCard({super.key, required this.item});

  final GuideItem item;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 44,
              height: 44,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: const Color(0xFF2A1A12),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFF8C5A2B)),
              ),
              child: Icon(item.icon, color: const Color(0xFFFF8A1E)),
            ),
            const SizedBox(height: 12),
            Text(
              item.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              item.body,
              maxLines: 4,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: Color(0xFFD8D2CC), height: 1.45),
            ),
          ],
        ),
      ),
    );
  }
}

class VehicleProfileSection extends StatelessWidget {
  const VehicleProfileSection({super.key, required this.generation});

  final PatrolGeneration generation;

  @override
  Widget build(BuildContext context) {
    final profile = generation.vehicleProfile;
    final items = [
      SpecItem('الفئة', profile?.nameAr ?? 'نيسان باترول سفاري Y60 SGL'),
      SpecItem('رقم الهيكل', profile?.chassisNumber ?? 'WGY60-348567'),
      SpecItem('الموديل', profile?.modelCode ?? 'WLGY60JFRC5'),
      const SpecItem('الإنتاج', '10 / 1991'),
      const SpecItem('موديل الاستمارة', '1992'),
      const SpecItem('بلد الصنع', 'اليابان'),
      SpecItem('المحرك', profile?.engineCode ?? 'TB42S'),
      SpecItem(
        'وصف المحرك',
        profile?.engineDescriptionAr ?? 'بنزين 6 سلندر مستقيم، 4.2 لتر',
      ),
      SpecItem('القير', profile?.transmissionCode ?? 'FS5R50A'),
      SpecItem('الدفرنس', profile?.finalDriveCode ?? 'HG41'),
      SpecItem('الهيكل', profile?.bodyStyleAr ?? 'Wagon طويل خمسة أبواب'),
      SpecItem('اللون الخارجي', profile?.exteriorColorCode ?? '2L3'),
      SpecItem('اللون الداخلي', profile?.interiorColorCode ?? 'AH3 / عنابي'),
      SpecItem('المقود', profile?.driveSide ?? 'LHD'),
      SpecItem('السوق', profile?.market ?? 'الخليج / السعودية'),
    ];

    return PageShell(
      title: 'بطاقة السيارة',
      subtitle:
          'بيانات السيارة الخاصة WGY60-348567 المستخدمة في البحث والكتالوجات.',
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth >= 780;
          return GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: items.length,
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: isWide ? 4 : 2,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              mainAxisExtent: isWide ? 92 : 108,
            ),
            itemBuilder: (context, index) => SpecCard(item: items[index]),
          );
        },
      ),
    );
  }
}

class SpecItem {
  const SpecItem(this.label, this.value);

  final String label;
  final String value;
}

class SpecCard extends StatelessWidget {
  const SpecCard({super.key, required this.item});

  final SpecItem item;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              item.label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Color(0xFFFF8A1E),
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
            ),
            Text(
              item.value,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 15,
                height: 1.25,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class CatalogSectionsGrid extends StatefulWidget {
  const CatalogSectionsGrid({super.key});

  @override
  State<CatalogSectionsGrid> createState() => _CatalogSectionsGridState();
}

class _CatalogSectionsGridState extends State<CatalogSectionsGrid> {
  late final Future<CatalogSectionIndex> _sectionIndexFuture;

  @override
  void initState() {
    super.initState();
    _sectionIndexFuture = CatalogSectionIndex.load();
  }

  @override
  Widget build(BuildContext context) {
    return PageShell(
      title: 'أقسام الكتالوج',
      subtitle:
          'أقسام مملوءة فعلياً من فهرس كتالوجات Y60 وملف السيارة WGY60348567.',
      child: FutureBuilder<CatalogSectionIndex>(
        future: _sectionIndexFuture,
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Card(
              child: Padding(
                padding: EdgeInsets.all(18),
                child: Row(
                  children: [
                    SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                    SizedBox(width: 12),
                    Expanded(
                        child: Text('جاري تعبئة الأقسام من قاعدة البيانات...')),
                  ],
                ),
              ),
            );
          }

          final sectionIndex = snapshot.data!;
          final sections = sectionIndex.sections;

          return LayoutBuilder(
            builder: (context, constraints) {
              final columns = constraints.maxWidth >= 980
                  ? 3
                  : constraints.maxWidth >= 620
                      ? 2
                      : 1;
              return GridView.builder(
                key: const Key('catalog-sections-loaded'),
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: sections.length,
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: columns,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  mainAxisExtent: columns == 1 ? 118 : 142,
                ),
                itemBuilder: (context, itemIndex) => SystemCard(
                  item: sections[itemIndex].toSummary(),
                  entries: sections[itemIndex].entries,
                ),
              );
            },
          );
        },
      ),
    );
  }
}

const catalogSectionDefinitions = [
  CatalogSectionDefinition(
    id: 'vehicle',
    titleAr: 'بطاقة السيارة',
    descriptionAr: 'بيانات السيارة الخاصة، رقم الهيكل، ومعلومات WGY60348567.',
    icon: Icons.badge,
  ),
  CatalogSectionDefinition(
    id: 'engine',
    titleAr: 'المحرك والوقود',
    descriptionAr: 'المحرك TB42S، البلوك، الكربريتر، الوقود، والعادم.',
    icon: Icons.settings,
  ),
  CatalogSectionDefinition(
    id: 'transmission',
    titleAr: 'القير والدبل',
    descriptionAr: 'ناقل الحركة، الدبل، الكلتش، وعمود الكردان.',
    icon: Icons.precision_manufacturing,
  ),
  CatalogSectionDefinition(
    id: 'axle',
    titleAr: 'الدفرنسات والمحاور',
    descriptionAr: 'الدفرنسات، المحاور، التعليق، ومكونات الحركة.',
    icon: Icons.account_tree,
  ),
  CatalogSectionDefinition(
    id: 'brake',
    titleAr: 'الفرامل',
    descriptionAr: 'نظام الفرامل، الهوبات، المواسير، والقطع المرتبطة.',
    icon: Icons.album,
  ),
  CatalogSectionDefinition(
    id: 'body',
    titleAr: 'البدي والخارجية',
    descriptionAr: 'الهيكل، الرفارف، الكبوت، الأبواب، الصدامات، والزجاج.',
    icon: Icons.directions_car,
  ),
  CatalogSectionDefinition(
    id: 'interior',
    titleAr: 'الداخلية والفرش',
    descriptionAr: 'الطبلون، المقاعد، الأبواب، السقف، الأرضية، والديكورات.',
    icon: Icons.airline_seat_recline_normal,
  ),
  CatalogSectionDefinition(
    id: 'electrical',
    titleAr: 'الكهرباء والظفيرة',
    descriptionAr: 'الأفياش، التوصيلات، اللمبات، العدادات، والمفاتيح.',
    icon: Icons.electrical_services,
  ),
  CatalogSectionDefinition(
    id: 'cooling_ac',
    titleAr: 'التكييف والثلاجات',
    descriptionAr: 'المكيف الأمامي والخلفي، الثلاجات، الهوايات، والوايرات.',
    icon: Icons.ac_unit,
  ),
  CatalogSectionDefinition(
    id: 'general',
    titleAr: 'عام وباقي الصفحات',
    descriptionAr: 'صفحات عامة أو صفحات لم تُصنّف آلياً من نص الكتالوج.',
    icon: Icons.folder_copy,
  ),
];

class CatalogSectionDefinition {
  const CatalogSectionDefinition({
    required this.id,
    required this.titleAr,
    required this.descriptionAr,
    required this.icon,
  });

  final String id;
  final String titleAr;
  final String descriptionAr;
  final IconData icon;
}

class CatalogSectionSummary {
  const CatalogSectionSummary({
    required this.definition,
    required this.title,
    required this.count,
  });

  final CatalogSectionDefinition definition;
  final String title;
  final int count;
}

class SystemCard extends StatelessWidget {
  const SystemCard({super.key, required this.item, required this.entries});

  final CatalogSectionSummary item;
  final List<CatalogSearchEntry> entries;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => Directionality(
                textDirection: TextDirection.rtl,
                child: CatalogSectionPage(
                  section: item.title,
                  entries: entries,
                  totalCount: item.count,
                ),
              ),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: const Color(0xFF2A1A12),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFF8C5A2B)),
                ),
                child: Icon(
                  item.definition.icon,
                  color: const Color(0xFFFF8A1E),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      item.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      '${item.definition.descriptionAr}\n${item.count} صفحة/نتيجة مفهرسة',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: Color(0xFFD8D2CC)),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_left, color: Color(0xFFFFB15C)),
            ],
          ),
        ),
      ),
    );
  }
}

class GenerationsSection extends StatelessWidget {
  const GenerationsSection({super.key, required this.generations});

  final List<PatrolGeneration> generations;

  @override
  Widget build(BuildContext context) {
    return PageShell(
      title: 'أجيال الباترول',
      subtitle: 'الواجهة مجهزة لتوسيع المحتوى خارج Y60 لاحقًا.',
      child: SizedBox(
        height: 265,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          itemCount: generations.length,
          separatorBuilder: (_, __) => const SizedBox(width: 10),
          itemBuilder: (context, index) {
            final generation = generations[index];
            return SizedBox(
              width: 260,
              child: Card(
                child: InkWell(
                  borderRadius: BorderRadius.circular(8),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => Directionality(
                          textDirection: TextDirection.rtl,
                          child: GenerationDetailsPage(generation: generation),
                        ),
                      ),
                    );
                  },
                  child: Padding(
                    padding: const EdgeInsets.all(10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(7),
                          child: AspectRatio(
                            aspectRatio: 16 / 9,
                            child: Image.asset(
                              generation.imageAssetPath,
                              fit: BoxFit.cover,
                              filterQuality: FilterQuality.medium,
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          generation.code,
                          style: const TextStyle(
                              fontSize: 22, fontWeight: FontWeight.w900),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          generation.nameAr,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          generation.years,
                          style: const TextStyle(color: Color(0xFF7A1F2B)),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class PageShell extends StatelessWidget {
  const PageShell({
    super.key,
    required this.child,
    this.title,
    this.subtitle,
    this.top = 22,
    this.bottom = 0,
  });

  final Widget child;
  final String? title;
  final String? subtitle;
  final double top;
  final double bottom;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1180),
        child: Padding(
          padding: EdgeInsets.fromLTRB(20, top, 20, bottom),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (title != null) ...[
                Text(
                  title!,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 6),
                  Text(subtitle!,
                      style: const TextStyle(color: Color(0xFFCDBCAD))),
                ],
                const SizedBox(height: 12),
              ],
              child,
            ],
          ),
        ),
      ),
    );
  }
}

class GenerationDetailsPage extends StatelessWidget {
  const GenerationDetailsPage({super.key, required this.generation});

  final PatrolGeneration generation;

  @override
  Widget build(BuildContext context) {
    final profile = generation.vehicleProfile;
    const sections = [
      GenerationDetailSection('دليل التشغيل', Icons.menu_book,
          menuTarget: 'guide'),
      GenerationDetailSection('الصيانة الدورية', Icons.build,
          menuTarget: 'maintenance'),
      GenerationDetailSection('قطع الغيار', Icons.manage_search,
          menuTarget: 'parts'),
      GenerationDetailSection('المحرك', Icons.settings,
          catalogSectionId: 'engine'),
      GenerationDetailSection('القير والدبل', Icons.precision_manufacturing,
          catalogSectionId: 'transmission'),
      GenerationDetailSection('الكهرباء', Icons.electrical_services,
          catalogSectionId: 'electrical'),
      GenerationDetailSection('التكييف', Icons.ac_unit,
          catalogSectionId: 'cooling_ac'),
      GenerationDetailSection('الأعطال الشائعة', Icons.report_problem,
          menuTarget: 'issues'),
      GenerationDetailSection('المخططات', Icons.account_tree,
          menuTarget: 'catalogs'),
    ];

    return Scaffold(
      appBar: AppBar(title: Text(generation.code)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: AspectRatio(
              aspectRatio: 16 / 9,
              child: Image.asset(
                generation.imageAssetPath,
                fit: BoxFit.cover,
                filterQuality: FilterQuality.medium,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(generation.nameAr,
              style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 8),
          Text(generation.imageDescriptionAr),
          const SizedBox(height: 8),
          Text('السنوات: ${generation.years}'),
          if (profile != null) ...[
            const SizedBox(height: 8),
            Text('الفئة: ${profile.nameAr}'),
            Text('المحرك: ${profile.engineCode}'),
            Text('القير: ${profile.transmissionCode}'),
          ],
          const SizedBox(height: 16),
          const Text('المحركات:',
              style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: generation.engines
                .map((engine) => Chip(label: Text(engine)))
                .toList(),
          ),
          const SizedBox(height: 24),
          const Text('الأقسام:', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          ...sections.map(
            (section) => Card(
              child: ListTile(
                leading:
                    Icon(section.icon, color: const Color(0xFFFFB15C)),
                title: Text(section.title),
                trailing: const Icon(Icons.chevron_left),
                onTap: () {
                  final catalogSectionId = section.catalogSectionId;
                  final menuTarget = section.menuTarget;
                  if (catalogSectionId != null) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => Directionality(
                          textDirection: TextDirection.rtl,
                          child: CatalogLinkedSectionPage(
                            sectionId: catalogSectionId,
                          ),
                        ),
                      ),
                    );
                  } else if (menuTarget != null) {
                    HeaderMenuButton.openItem(context, menuTarget);
                  }
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class GenerationDetailSection {
  const GenerationDetailSection(
    this.title,
    this.icon, {
    this.catalogSectionId,
    this.menuTarget,
  });

  final String title;
  final IconData icon;
  final String? catalogSectionId;
  final String? menuTarget;
}

class CatalogLinkedSectionPage extends StatelessWidget {
  const CatalogLinkedSectionPage({super.key, required this.sectionId});

  final String sectionId;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<CatalogSectionIndex>(
      future: CatalogSectionIndex.load(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        CatalogSectionData? section;
        for (final item in snapshot.data!.sections) {
          if (item.id == sectionId) {
            section = item;
            break;
          }
        }
        if (section == null) {
          return const Scaffold(
            body: Center(child: Text('لم يتم العثور على هذا القسم في الفهرس.')),
          );
        }

        return CatalogSectionPage(
          section: section.toSummary().title,
          entries: section.entries,
          totalCount: section.count,
        );
      },
    );
  }
}

class CatalogEntryDetailPage extends StatelessWidget {
  const CatalogEntryDetailPage({super.key, required this.entry});

  final CatalogSearchEntry entry;

  @override
  Widget build(BuildContext context) {
    final partNumbers = _extractPartNumbers(entry);
    final installNotes = _installNotesFor(entry.sectionId);
    final sourceName = entry.sourcePdfPath.split('/').last;

    return Scaffold(
      appBar: AppBar(title: const Text('تفاصيل القطعة / الصفحة')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 54,
                        height: 54,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFFFF8A1E), Color(0xFF7A1F2B)],
                          ),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: const Color(0xFFE7C8A1)),
                        ),
                        child: Text(
                          entry.year,
                          textDirection: TextDirection.ltr,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              entry.titleAr,
                              style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              entry.subtitleAr,
                              style: const TextStyle(
                                color: Color(0xFFD8D2CC),
                                height: 1.45,
                              ),
                            ),
                            if (entry.titleEn != entry.titleAr) ...[
                              const SizedBox(height: 6),
                              Text(
                                entry.titleEn,
                                textDirection: TextDirection.ltr,
                                style: const TextStyle(
                                  color: Color(0xFFFFB15C),
                                  fontWeight: FontWeight.w700,
                                  height: 1.35,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      DetailChip(Icons.folder, entry.sectionTitleAr),
                      DetailChip(Icons.picture_as_pdf, sourceName),
                      DetailChip(
                        Icons.description,
                        entry.pageNumber > 0
                            ? 'صفحة ${entry.pageNumber}'
                            : 'بطاقة مركبة',
                      ),
                      DetailChip(Icons.verified, _typeLabel(entry.type)),
                    ],
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: () => openCatalogEntry(context, entry),
                      icon: const Icon(Icons.open_in_new),
                      label: const Text('فتح صفحة الكتالوج الأصلية PDF'),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          DetailSection(
            title: 'الأرقام الظاهرة في الصفحة',
            child: partNumbers.isEmpty
                ? const Text(
                    'لا توجد أرقام قطع واضحة في هذه النتيجة. افتح PDF للتحقق من الجدول الأصلي.',
                    style: TextStyle(color: Color(0xFFD8D2CC), height: 1.5),
                  )
                : Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: partNumbers
                        .map(
                          (number) => Chip(
                            label: Text(
                              number,
                              textDirection: TextDirection.ltr,
                            ),
                            backgroundColor: const Color(0xFF211814),
                            side: const BorderSide(color: Color(0xFF7C5A3B)),
                            labelStyle:
                                const TextStyle(color: Color(0xFFFFD0A0)),
                          ),
                        )
                        .toList(growable: false),
                  ),
          ),
          const SizedBox(height: 12),
          DetailSection(
            title: 'طريقة التركيب والتحقق',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: installNotes
                  .map(
                    (note) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(
                            Icons.check_circle,
                            size: 18,
                            color: Color(0xFFFF8A1E),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              note,
                              style: const TextStyle(
                                color: Color(0xFFD8D2CC),
                                height: 1.5,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                  .toList(growable: false),
            ),
          ),
          const SizedBox(height: 12),
          DetailSection(
            title: 'وصف الصفحة من الفهرس',
            child: Text(
              entry.snippet.isEmpty ? entry.queryText : entry.snippet,
              maxLines: 12,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: Color(0xFFD8D2CC), height: 1.55),
            ),
          ),
          const SizedBox(height: 12),
          DetailSection(
            title: 'كلمات البحث المرتبطة',
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: entry.keywords.take(28).map((keyword) {
                return Chip(
                  label: Text(keyword, textDirection: TextDirection.ltr),
                  backgroundColor: const Color(0xFF15100D),
                  side: const BorderSide(color: Color(0xFF514236)),
                  labelStyle: const TextStyle(color: Color(0xFFD8D2CC)),
                );
              }).toList(growable: false),
            ),
          ),
        ],
      ),
    );
  }

  static List<String> _extractPartNumbers(CatalogSearchEntry entry) {
    final source =
        '${entry.titleAr} ${entry.titleEn} ${entry.snippet} ${entry.keywords.join(' ')}';
    final matches = RegExp(r'\b[0-9A-Z]{5,12}\b').allMatches(source);
    final numbers = <String>[];
    for (final match in matches) {
      final value = match.group(0)!;
      final hasDigit = RegExp(r'\d').hasMatch(value);
      final hasLetter = RegExp(r'[A-Z]').hasMatch(value);
      if (!hasDigit || !hasLetter) continue;
      if (value == 'WGY60' || value == 'TB42S' || value == 'FS5R50A') continue;
      if (!numbers.contains(value)) numbers.add(value);
      if (numbers.length >= 32) break;
    }
    return numbers;
  }

  static List<String> _installNotesFor(String sectionId) {
    switch (sectionId) {
      case 'engine':
        return const [
          'طابق رقم القطعة مع المحرك TB42S قبل الطلب أو التركيب.',
          'راجع اتجاه التركيب في المخطط الأصلي، خصوصاً الخراطيم والحساسات والجلب.',
          'استبدل الجلود والكلبسات المستهلكة مع القطعة إذا كانت مذكورة في نفس الصفحة.',
        ];
      case 'transmission':
        return const [
          'تأكد من توافق القطعة مع القير FS5R50A والدبل قبل الطلب.',
          'افحص الصوف، الرمانات، والكلبسات المرتبطة لأن كثيراً منها يظهر في نفس مخطط المجموعة.',
          'بعد التركيب راجع مستوى الزيت وحالة التهريب والتعشيق.',
        ];
      case 'electrical':
        return const [
          'افصل البطارية قبل تركيب أي مفتاح أو فيش أو ظفيرة.',
          'طابق شكل الفيش وعدد الأسلاك قبل الاعتماد على رقم القطعة فقط.',
          'افحص الأرضي والفيوزات بعد التركيب إذا كانت القطعة كهربائية.',
        ];
      case 'cooling_ac':
        return const [
          'تأكد من توافق القطعة مع نظام المكيف الخلفي أو الأمامي حسب الصفحة.',
          'عند فك ليات أو مواسير المكيف يجب تفريغ النظام بطريقة آمنة لدى فني مختص.',
          'راجع اتجاه الوايرات والبوابات والهوايات في المخطط قبل التثبيت النهائي.',
        ];
      case 'body':
      case 'interior':
        return const [
          'طابق اللون والجهة: يمين/يسار، أمامي/خلفي، وعنابي/رمادي عند وجود أكثر من خيار.',
          'استخدم الكلبسات الأصلية أو بدائل مطابقة حتى لا تنكسر الديكورات.',
          'لا تعتمد على الصورة وحدها؛ افتح صفحة PDF للتأكد من رقم النداء ورقم القطعة.',
        ];
      default:
        return const [
          'هذه بطاقة تفصيل مبنية من فهرس الكتالوج وليست بديلاً عن صفحة PDF الأصلية.',
          'افتح صفحة الكتالوج الأصلية للتحقق من رقم النداء، رقم القطعة، والموديلات المطابقة.',
          'اعتمد القطعة فقط بعد مطابقة سنة السيارة، السوق، المحرك، ونوع القير.',
        ];
    }
  }

  static String _typeLabel(String type) {
    switch (type) {
      case 'vehicle':
        return 'بطاقة سيارة';
      case 'vehicle_pdf_page':
        return 'صفحة ملف السيارة';
      case 'catalog_page':
        return 'صفحة كتالوج';
      default:
        return type;
    }
  }
}

class DetailChip extends StatelessWidget {
  const DetailChip(this.icon, this.label, {super.key});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Chip(
      avatar: Icon(icon, size: 18, color: const Color(0xFFFFB15C)),
      label: Text(label, overflow: TextOverflow.ellipsis),
      backgroundColor: const Color(0xFF211814),
      side: const BorderSide(color: Color(0xFF7C5A3B)),
      labelStyle: const TextStyle(color: Color(0xFFEDE4DA)),
    );
  }
}

class DetailSection extends StatelessWidget {
  const DetailSection({super.key, required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 12),
            child,
          ],
        ),
      ),
    );
  }
}

class CatalogSectionPage extends StatelessWidget {
  const CatalogSectionPage({
    super.key,
    required this.section,
    required this.entries,
    required this.totalCount,
  });

  final String section;
  final List<CatalogSearchEntry> entries;
  final int totalCount;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(section)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    section,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'تمت تعبئة هذا القسم من قاعدة فهرس الكتالوج: $totalCount صفحة/نتيجة. المعروض هنا أول ${entries.length} نتيجة لتخفيف الحمل على الجوال.',
                    style: const TextStyle(height: 1.5),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          if (entries.isEmpty)
            const Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Text('لا توجد نتائج مفهرسة في هذا القسم حالياً.'),
              ),
            )
          else
            ...entries.map(
              (entry) => Card(
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: const Color(0xFF2A1A12),
                    foregroundColor: const Color(0xFFFFB15C),
                    child: Text(entry.year),
                  ),
                  title: Text(
                    entry.titleAr,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  subtitle: Text(
                    '${entry.subtitleAr}\n${entry.snippet}',
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                  trailing: const Icon(Icons.picture_as_pdf),
                  iconColor: const Color(0xFFFFB15C),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => Directionality(
                          textDirection: TextDirection.rtl,
                          child: CatalogEntryDetailPage(entry: entry),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class MenuContentPage extends StatelessWidget {
  const MenuContentPage({super.key, required this.item});

  final HeaderMenuItem item;

  @override
  Widget build(BuildContext context) {
    final content = _contentFor(item.value);

    return Scaffold(
      appBar: AppBar(title: Text(item.label)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: const Color(0xFF2A1A12),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFF8C5A2B)),
                    ),
                    child: Icon(item.icon, color: const Color(0xFFFF8A1E)),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.label,
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(content.summary),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          ...content.items.map(
            (line) => Card(
              child: ListTile(
                leading: const Icon(Icons.chevron_left),
                title: Text(line),
              ),
            ),
          ),
        ],
      ),
    );
  }

  MenuPageContent _contentFor(String value) {
    switch (value) {
      case 'parts':
        return const MenuPageContent(
          'قسم القطع يعتمد على فهرس الكتالوج ويربط رقم القطعة بالقسم والصفحة والصورة أو المخطط عند توفره.',
          [
            'الحقول الأساسية: رقم القطعة، الاسم العربي، الاسم الإنجليزي، القسم، سنة الكتالوج، ورقم الصفحة.',
            'الحقول المساعدة: رقم المخطط، رقم النداء داخل الرسم، ملاحظات التركيب، وصورة القطعة.',
            'مصدر التعبئة الحالي: catalog_search_index.json و catalog_section_index.json داخل assets/catalog/search.',
            'طريقة الربط: عند اختيار نتيجة يتم فتح ملف PDF الأصلي على صفحة الكتالوج المطابقة.',
            'المرحلة التالية: إنشاء نموذج إضافة قطعة وحفظها محلياً ثم ربطها بالفهرس الكامل.',
          ],
        );
      case 'issues':
        return const MenuPageContent(
          'قسم الأعطال مخصص لتجميع الأعطال المتكررة وربطها بالنظام والقطع المرتبطة بها.',
          [
            'التصنيف: كهرباء، تكييف، ميكانيكا، قير ودبل، وقود، داخلية، خارجية.',
            'بيانات العطل: الأعراض، السبب المحتمل، خطوات الفحص، القطع المرتبطة، ودرجة الخطورة.',
            'طريقة الإدخال: لا يُضاف العطل إلا بعد ربطه بدليل فني أو تجربة موثقة أو صفحة من الكتالوج.',
            'طريقة العرض: بطاقة مختصرة ثم صفحة تفصيل فيها الحل، الأدوات، والقطع المطلوبة.',
          ],
        );
      case 'maintenance':
        return const MenuPageContent(
          'قسم الصيانة مخصص لتنظيم أعمال الصيانة الدورية والوقائية حسب النظام والمسافة.',
          [
            'الحقول: اسم العملية، النظام، كل كم كيلومتر، المواد، أرقام القطع، الملاحظات، وآخر تنفيذ.',
            'الأمثلة: زيت المكينة، فلتر الزيت، زيت القير، زيت الدفرنس، ماء الرديتر، فحص السيور والخراطيم.',
            'طريقة الربط: كل عملية صيانة تربط بقطعها وبصفحات الكتالوج التي تثبت رقم القطعة.',
            'المرحلة التالية: تفعيل تذكيرات محلية بدون تسجيل دخول وبدون خادم خارجي.',
          ],
        );
      case 'photos':
        return const MenuPageContent(
          'قسم الصور مخصص لصور السيارة، اللوحات، القطع، والمخططات.',
          [
            'صور داخلية وخارجية.',
            'صور لوحة البيانات ورقم الهيكل.',
            'صور القطع التي سيتم ربطها بالكتالوج.',
          ],
        );
      case 'catalogs':
        return const MenuPageContent(
          'قسم الكتالوجات يحتوي ملفات PDF الأصلية ويفرزها حسب السنة وملف السيارة الخاص.',
          [
            'الملفات المضافة: Y60 1988 إلى Y60 1997، وملف WGY60348567 الخاص بالسيارة.',
            'التحميل: الملفات محفوظة داخل assets/catalog/pdfs وتفتح مباشرة من الموقع والتطبيق.',
            'الفهرسة: تم استخراج عناوين وصفحات وربطها بالأقسام حتى تعمل خانة البحث.',
            'الجودة: يتم الاحتفاظ بملفات PDF الأصلية دون ضغط داخل أصول التطبيق.',
          ],
        );
      case 'database':
        return const MenuPageContent(
          'قاعدة البيانات الحالية Offline-first وتعتمد على ملفات JSON وPDF داخل التطبيق نفسه.',
          [
            'catalog_search_index.json: فهرس البحث الكامل للصفحات والنتائج والكلمات المفتاحية.',
            'catalog_section_index.json: فهرس الأقسام مع النتائج التابعة لكل قسم.',
            'assets/catalog/pdfs: مجلد ملفات PDF الأصلية لكل السنوات وملف السيارة.',
            'assets/hero و assets/generations: صور الواجهة والأجيال والعرض البصري.',
            'طريقة التركيب: عند البناء للويب أو ويندوز تُنسخ هذه الأصول داخل build وتعمل بدون خادم بيانات.',
            'التطوير القادم: يمكن نقل نفس البنية إلى SQLite أو Isar عند الحاجة لتعديل البيانات من داخل التطبيق.',
          ],
        );
      case 'vision':
        return const MenuPageContent(
          'هذه الصفحة تعتمد خارطة المزايا التي تجعل Patrol Hub مرجعاً عالمياً لملاك نيسان باترول.',
          [
            'قاعدة بيانات احترافية: الرسومات الأصلية، OEM، أسماء متعددة اللغات، وصف الوظيفة، الموقع، الصور، والأبعاد عند توفرها.',
            'توافق القطع: معرفة السيارات المطابقة والفروقات بين Y60 وY61 وY62 مستقبلاً حسب السنة والمحرك والقير والفئة.',
            'البحث الذكي: رقم القطعة، الاسم، العربية، الإنجليزية، VIN، والقسم الفني مثل مكيف ومحرك وكهرباء وديكور.',
            'مقارنة الأسعار: السعر، العملة، الشحن، مدة التوصيل، الدولة، وحالة القطعة من عدة متاجر.',
            'تصنيف نوع القطعة: OEM، مصنع أصلي، إعادة تصنيع عالية الجودة، بديل تجاري، مستعملة أصلية، وNOS.',
            'مؤشر الندرة: متوفرة بكثرة، محدودة، نادرة، أو موقوفة الإنتاج NLA.',
            'معلومات الصيانة: سبب التعطل، أعراض التلف، العمر الافتراضي، وقت التغيير، والأعطال الناتجة عن الإهمال.',
            'الشروحات: فيديوهات، صور خطوة بخطوة، عزم الربط، الأدوات المطلوبة، ودرجة الصعوبة.',
            'المجتمع والمتاجر: تقييمات، تجارب ملاك، مشاريع ترميم، متاجر عالمية وخليجية، تشاليح، وبائعون موثقون.',
            'الذكاء الاصطناعي والإحصائيات: معرفة القطعة من صورة، اقتراح البدائل، تشخيص الأعطال، وأكثر القطع طلباً وندرة.',
          ],
        );
      case 'guide':
        return const MenuPageContent(
          'قسم الشرح يوضح طريقة استخدام الموقع وتركيب قاعدة البيانات وتحديثها لاحقاً.',
          [
            'البحث: اكتب رقم الهيكل أو رقم القطعة أو كود النظام مثل TB42S أو FS5R50A.',
            'فتح المخطط: اضغط نتيجة البحث لفتح PDF الأصلي على الصفحة المرتبطة.',
            'قراءة القطعة: رقم النداء داخل الرسم يربط بالجدول، ثم رقم القطعة الأصلي.',
            'تحديث البيانات: أضف PDF جديد، شغّل بناء الفهرس، ثم أعد بناء الويب أو التطبيق.',
            'قاعدة العمل: لا تعتمد أي رقم قطعة إلا من صفحة كتالوج أو مصدر موثوق ومطابق للموديل.',
          ],
        );
      case 'contact':
        return const MenuPageContent(
          'للتواصل وإدارة المشروع استخدم البريد الرسمي.',
          [
            'البريد الرسمي: patrolsafariy60@gmail.com',
            'هذا البريد معتمد للموقع والتطبيق وطلبات الدعم.',
          ],
        );
      default:
        return const MenuPageContent(
          'الصفحة الرئيسية تعرض البحث، الكتالوجات، بيانات السيارة، والأقسام.',
          [
            'استخدم زر المحتويات للانتقال بين أقسام الموقع.',
            'استخدم البحث للوصول السريع إلى أرقام القطع والصفحات.',
          ],
        );
    }
  }
}

class MenuPageContent {
  const MenuPageContent(this.summary, this.items);

  final String summary;
  final List<String> items;
}

class SiteFooter extends StatelessWidget {
  const SiteFooter({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 28),
      color: const Color(0xFF1D1B1A),
      child: const Center(
        child: Padding(
          padding: EdgeInsets.all(22),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Patrol Hub • منصة كتالوج باترول Y60',
                style: TextStyle(color: Colors.white),
              ),
              SizedBox(height: 8),
              Text(
                'البريد الرسمي: patrolsafariy60@gmail.com',
                textDirection: TextDirection.ltr,
                style: TextStyle(
                  color: Color(0xFFD8D2CC),
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
