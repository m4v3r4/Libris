import 'package:flutter/material.dart';

import 'package:libris/common/localization/app_localization.dart';
import 'package:libris/features/books/screen/book_list_screen.dart';
import 'package:libris/features/home/screens/widgets/category_analysis_widget.dart';
import 'package:libris/features/home/screens/widgets/home_book.dart';
import 'package:libris/features/home/screens/widgets/home_loan.dart';
import 'package:libris/features/home/screens/widgets/home_members.dart';
import 'package:libris/features/home/screens/widgets/left_bar.dart';
import 'package:libris/features/home/screens/widgets/notification_widget.dart';
import 'package:libris/features/home/screens/widgets/quick_menu.dart';
import 'package:libris/features/loans/screen/loan_list_screen.dart';
import 'package:libris/features/members/screens/members_list_screen.dart';
import 'package:libris/features/settings/screen/category_manager_screen.dart';
import 'package:libris/features/settings/screen/settings_screen.dart';
import 'package:libris/features/settings/services/settings_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  static const desktopBreakpoint = 1200.0;
  static const tabletBreakpoint = 820.0;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  LeftbarDestination? _selected;

  void _openSection(LeftbarDestination destination) {
    setState(() {
      _selected = destination;
    });
  }

  void _closeSection() {
    setState(() {
      _selected = null;
    });
  }

  String get _sectionTitle {
    switch (_selected) {
      case LeftbarDestination.books:
        return l10n('Kitaplar', 'Books');
      case LeftbarDestination.members:
        return l10n('Üyeler', 'Members');
      case LeftbarDestination.loans:
        return l10n('Emanetler', 'Loans');
      case LeftbarDestination.categories:
        return l10n('Kategoriler', 'Categories');
      case LeftbarDestination.settings:
        return l10n('Ayarlar', 'Settings');
      case null:
        return l10n('Genel Bakış', 'Overview');
    }
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final showDesktopSidebar = width >= HomeScreen.desktopBreakpoint;
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      drawer: showDesktopSidebar
          ? null
          : Drawer(
              width: 280,
              child: Leftbar(
                selected: _selected,
                onSelect: (destination) {
                  Navigator.pop(context);
                  _openSection(destination);
                },
              ),
            ),
      appBar: AppBar(
        centerTitle: false,
        surfaceTintColor: Colors.transparent,
        titleSpacing: showDesktopSidebar ? 24 : 0,
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (!showDesktopSidebar) ...[
              Image.asset(
                'assets/branding/libris-icon-128.png',
                width: 30,
                height: 30,
                filterQuality: FilterQuality.high,
                semanticLabel: l10n('Libris logosu', 'Libris logo'),
              ),
              const SizedBox(width: 10),
            ],
            Text(
              _sectionTitle,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
          ],
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Divider(height: 1, color: scheme.outlineVariant),
        ),
      ),
      body: showDesktopSidebar
          ? Row(
              children: [
                SizedBox(
                  width: 248,
                  child: Leftbar(
                    selected: _selected,
                    onSelect: _openSection,
                  ),
                ),
                Expanded(
                  child: _selected == null
                      ? const _DashboardBody()
                      : _EmbeddedSection(
                          destination: _selected!,
                          onClose: _closeSection,
                        ),
                ),
              ],
            )
          : (_selected == null
              ? const _DashboardBody()
              : _EmbeddedSection(
                  destination: _selected!,
                  onClose: _closeSection,
                )),
    );
  }
}

class _EmbeddedSection extends StatelessWidget {
  final LeftbarDestination destination;
  final VoidCallback onClose;

  const _EmbeddedSection({required this.destination, required this.onClose});

  @override
  Widget build(BuildContext context) {
    switch (destination) {
      case LeftbarDestination.books:
        return BookListScreen(embedded: true, onClose: onClose);
      case LeftbarDestination.members:
        return MembersListScreen(embedded: true, onClose: onClose);
      case LeftbarDestination.loans:
        return LoanListScreen(embedded: true, onClose: onClose);
      case LeftbarDestination.categories:
        return CategoryManagerScreen(embedded: true, onClose: onClose);
      case LeftbarDestination.settings:
        return SettingsScreen(embedded: true, onClose: onClose);
    }
  }
}

enum _DashboardPanelId {
  quickActions,
  loans,
  books,
  members,
  categories,
  notifications,
}

enum _DashboardPanelSize { compact, normal, large, wide }

String _dashboardPanelTitle(_DashboardPanelId id) {
  switch (id) {
    case _DashboardPanelId.quickActions:
      return l10n('Hızlı İşlemler', 'Quick Actions');
    case _DashboardPanelId.loans:
      return l10n('Emanet Durumu', 'Loan Status');
    case _DashboardPanelId.books:
      return l10n('Kitap İstatistikleri', 'Book Statistics');
    case _DashboardPanelId.members:
      return l10n('Üye İstatistikleri', 'Member Statistics');
    case _DashboardPanelId.categories:
      return l10n('Kategori Analizi', 'Category Analysis');
    case _DashboardPanelId.notifications:
      return l10n('Bildirimler', 'Notifications');
  }
}

class _DashboardPanelConfig {
  final _DashboardPanelId id;
  final IconData icon;
  final bool visible;
  final _DashboardPanelSize size;

  const _DashboardPanelConfig({
    required this.id,
    required this.icon,
    required this.visible,
    required this.size,
  });

  String get title => _dashboardPanelTitle(id);

  _DashboardPanelConfig copyWith({
    bool? visible,
    _DashboardPanelSize? size,
  }) {
    return _DashboardPanelConfig(
      id: id,
      icon: icon,
      visible: visible ?? this.visible,
      size: size ?? this.size,
    );
  }
}

class _DashboardBody extends StatefulWidget {
  const _DashboardBody();

  @override
  State<_DashboardBody> createState() => _DashboardBodyState();
}

class _DashboardBodyState extends State<_DashboardBody> {
  final SettingsService _settings = SettingsService();

  List<_DashboardPanelConfig> _panels = _defaultPanels();
  bool _editing = false;

  static List<_DashboardPanelConfig> _defaultPanels() {
    return const [
      _DashboardPanelConfig(
        id: _DashboardPanelId.quickActions,
        icon: Icons.bolt_rounded,
        visible: true,
        size: _DashboardPanelSize.wide,
      ),
      _DashboardPanelConfig(
        id: _DashboardPanelId.loans,
        icon: Icons.swap_horiz_rounded,
        visible: true,
        size: _DashboardPanelSize.normal,
      ),
      _DashboardPanelConfig(
        id: _DashboardPanelId.books,
        icon: Icons.menu_book_rounded,
        visible: true,
        size: _DashboardPanelSize.normal,
      ),
      _DashboardPanelConfig(
        id: _DashboardPanelId.members,
        icon: Icons.groups_2_rounded,
        visible: true,
        size: _DashboardPanelSize.normal,
      ),
      _DashboardPanelConfig(
        id: _DashboardPanelId.categories,
        icon: Icons.category_rounded,
        visible: true,
        size: _DashboardPanelSize.normal,
      ),
      _DashboardPanelConfig(
        id: _DashboardPanelId.notifications,
        icon: Icons.notifications_none_rounded,
        visible: true,
        size: _DashboardPanelSize.compact,
      ),
    ];
  }

  @override
  void initState() {
    super.initState();
    _loadLayout();
  }

  Future<void> _loadLayout() async {
    final defaults = _defaultPanels();
    final byId = {for (final panel in defaults) panel.id: panel};
    final orderValue = await _settings.getValue('dashboard_panel_order');
    final orderedIds = <_DashboardPanelId>[];

    if (orderValue != null && orderValue.trim().isNotEmpty) {
      for (final name in orderValue.split(',')) {
        for (final id in _DashboardPanelId.values) {
          if (id.name == name && !orderedIds.contains(id)) {
            orderedIds.add(id);
            break;
          }
        }
      }
    }

    for (final panel in defaults) {
      if (!orderedIds.contains(panel.id)) orderedIds.add(panel.id);
    }

    final loaded = <_DashboardPanelConfig>[];
    for (final id in orderedIds) {
      final panel = byId[id];
      if (panel == null) continue;

      final visibleValue = await _settings.getValue(
        'dashboard_${panel.id.name}_visible',
      );
      final sizeValue = await _settings.getValue(
        'dashboard_${panel.id.name}_size',
      );

      final matchingSizes = _DashboardPanelSize.values.where(
        (item) => item.name == sizeValue,
      );

      loaded.add(
        panel.copyWith(
          visible: visibleValue == null
              ? panel.visible
              : visibleValue == 'true',
          size: matchingSizes.isEmpty ? panel.size : matchingSizes.first,
        ),
      );
    }

    if (!mounted) return;
    setState(() => _panels = loaded);
  }

  Future<void> _savePanel(_DashboardPanelConfig panel) async {
    await Future.wait([
      _settings.saveValue(
        'dashboard_${panel.id.name}_visible',
        panel.visible.toString(),
      ),
      _settings.saveValue(
        'dashboard_${panel.id.name}_size',
        panel.size.name,
      ),
    ]);
  }

  Future<void> _saveOrder() async {
    await _settings.saveValue(
      'dashboard_panel_order',
      _panels.map((panel) => panel.id.name).join(','),
    );
  }

  void _updatePanel(
    _DashboardPanelId id, {
    bool? visible,
    _DashboardPanelSize? size,
  }) {
    final index = _panels.indexWhere((panel) => panel.id == id);
    if (index == -1) return;

    final updated = _panels[index].copyWith(visible: visible, size: size);
    setState(() => _panels[index] = updated);
    _savePanel(updated);
  }

  void _movePanel(_DashboardPanelId id, int delta) {
    final index = _panels.indexWhere((panel) => panel.id == id);
    if (index == -1) return;

    final target = index + delta;
    if (target < 0 || target >= _panels.length) return;

    setState(() {
      final panel = _panels.removeAt(index);
      _panels.insert(target, panel);
    });
    _saveOrder();
  }

  Future<void> _resetLayout() async {
    final defaults = _defaultPanels();
    setState(() => _panels = defaults);

    await _settings.deleteValue('dashboard_panel_order');
    for (final panel in defaults) {
      await Future.wait([
        _settings.deleteValue('dashboard_${panel.id.name}_visible'),
        _settings.deleteValue('dashboard_${panel.id.name}_size'),
      ]);
    }
  }

  Widget _panelWidget(_DashboardPanelId id) {
    switch (id) {
      case _DashboardPanelId.quickActions:
        return const QuickMenu();
      case _DashboardPanelId.loans:
        return const HomeLoan();
      case _DashboardPanelId.books:
        return const HomeBook();
      case _DashboardPanelId.members:
        return const HomeMembers();
      case _DashboardPanelId.categories:
        return const CategoryAnalysisWidget();
      case _DashboardPanelId.notifications:
        return const NotificationWidget();
    }
  }

  double _panelHeight(_DashboardPanelSize size) {
    switch (size) {
      case _DashboardPanelSize.compact:
        return 250;
      case _DashboardPanelSize.normal:
        return 340;
      case _DashboardPanelSize.large:
        return 480;
      case _DashboardPanelSize.wide:
        return 280;
    }
  }

  String _sizeLabel(_DashboardPanelSize size) {
    switch (size) {
      case _DashboardPanelSize.compact:
        return l10n('Küçük', 'Compact');
      case _DashboardPanelSize.normal:
        return l10n('Orta', 'Medium');
      case _DashboardPanelSize.large:
        return l10n('Büyük', 'Large');
      case _DashboardPanelSize.wide:
        return l10n('Geniş', 'Wide');
    }
  }

  @override
  Widget build(BuildContext context) {
    final visiblePanels = _panels.where((panel) => panel.visible).toList();
    final hiddenPanels = _panels.where((panel) => !panel.visible).toList();

    return LayoutBuilder(
      builder: (context, constraints) {
        const pagePadding = 16.0;
        const spacing = 12.0;
        final availableWidth = constraints.maxWidth - (pagePadding * 2);
        final columns = availableWidth >= 1320
            ? 3
            : availableWidth >= 760
                ? 2
                : 1;
        final cellWidth = columns == 1
            ? availableWidth
            : (availableWidth - (spacing * (columns - 1))) / columns;

        return SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(
            pagePadding,
            18,
            pagePadding,
            24,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _DashboardHeader(
                editing: _editing,
                onToggleEditing: () {
                  setState(() => _editing = !_editing);
                },
              ),
              if (_editing) ...[
                const SizedBox(height: 12),
                _DashboardEditBar(
                  hiddenPanels: hiddenPanels,
                  onRestore: (id) => _updatePanel(id, visible: true),
                  onReset: _resetLayout,
                ),
              ],
              const SizedBox(height: 14),
              if (visiblePanels.isEmpty)
                _DashboardNoPanels(
                  editing: _editing,
                  onCustomize: () => setState(() => _editing = true),
                  hiddenPanels: hiddenPanels,
                  onRestore: (id) => _updatePanel(id, visible: true),
                )
              else
                Wrap(
                  spacing: spacing,
                  runSpacing: spacing,
                  children: visiblePanels.map((panel) {
                    final isWide = panel.size == _DashboardPanelSize.wide;
                    final panelWidth = isWide && columns > 1
                        ? (cellWidth * 2) + spacing
                        : cellWidth;
                    final panelIndex = _panels.indexOf(panel);

                    Widget child = _panelWidget(panel.id);
                    if (_editing) {
                      child = _EditableDashboardPanel(
                        panel: panel,
                        sizeLabel: _sizeLabel,
                        canMoveBack: panelIndex > 0,
                        canMoveForward: panelIndex < _panels.length - 1,
                        onMoveBack: () => _movePanel(panel.id, -1),
                        onMoveForward: () => _movePanel(panel.id, 1),
                        onHide: () => _updatePanel(panel.id, visible: false),
                        onSizeChanged: (size) =>
                            _updatePanel(panel.id, size: size),
                        child: child,
                      );
                    }

                    return SizedBox(
                      width: panelWidth.clamp(0.0, availableWidth).toDouble(),
                      height: _panelHeight(panel.size) + (_editing ? 46 : 0),
                      child: child,
                    );
                  }).toList(),
                ),
            ],
          ),
        );
      },
    );
  }
}

class _DashboardHeader extends StatelessWidget {
  final bool editing;
  final VoidCallback onToggleEditing;

  const _DashboardHeader({
    required this.editing,
    required this.onToggleEditing,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    final text = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n('Kütüphaneye genel bakış', 'Library overview'),
          style: textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w700,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          editing
              ? l10n(
                  'Kartları taşıyın, boyutlandırın veya ihtiyacınız olmayan panelleri gizleyin.',
                  'Move, resize, or hide panels you do not need.',
                )
              : l10n(
                  'Günlük kütüphane işlemleri ve önemli hareketler tek çalışma alanında.',
                  'Daily library tasks and important activity in one workspace.',
                ),
          style: textTheme.bodyMedium?.copyWith(
            color: scheme.onSurfaceVariant,
          ),
        ),
      ],
    );

    final actions = Wrap(
      spacing: 8,
      runSpacing: 8,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        if (!editing)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: scheme.primaryContainer.withValues(alpha: 0.55),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.cloud_off_rounded, size: 16, color: scheme.primary),
                const SizedBox(width: 6),
                Text(
                  l10n('Yerel veri', 'Local data'),
                  style: textTheme.labelMedium?.copyWith(
                    color: scheme.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        FilledButton.tonalIcon(
          onPressed: onToggleEditing,
          icon: Icon(
            editing ? Icons.done_rounded : Icons.dashboard_customize_rounded,
            size: 18,
          ),
          label: Text(
            editing
                ? l10n('Düzenlemeyi Bitir', 'Finish Editing')
                : l10n('Dashboard Düzenle', 'Edit Dashboard'),
          ),
        ),
      ],
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth >= 760) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(child: text),
              const SizedBox(width: 16),
              actions,
            ],
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            text,
            const SizedBox(height: 12),
            Align(alignment: Alignment.centerLeft, child: actions),
          ],
        );
      },
    );
  }
}

class _DashboardEditBar extends StatelessWidget {
  final List<_DashboardPanelConfig> hiddenPanels;
  final ValueChanged<_DashboardPanelId> onRestore;
  final Future<void> Function() onReset;

  const _DashboardEditBar({
    required this.hiddenPanels,
    required this.onRestore,
    required this.onReset,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 10, 12),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(Icons.drag_indicator_rounded, color: scheme.onSurfaceVariant),
          const SizedBox(width: 8),
          Expanded(
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Text(
                  hiddenPanels.isEmpty
                      ? l10n(
                          'Kartların üzerindeki kontrollerle düzeni değiştirin.',
                          'Use the controls on each card to change the layout.',
                        )
                      : l10n('Gizli paneller:', 'Hidden panels:'),
                  style: textTheme.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
                ...hiddenPanels.map(
                  (panel) => ActionChip(
                    avatar: Icon(panel.icon, size: 16),
                    label: Text(panel.title),
                    onPressed: () => onRestore(panel.id),
                    tooltip: l10n('Paneli yeniden göster', 'Show panel again'),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          TextButton.icon(
            onPressed: onReset,
            icon: const Icon(Icons.restart_alt_rounded, size: 18),
            label: Text(l10n('Sıfırla', 'Reset')),
          ),
        ],
      ),
    );
  }
}

class _EditableDashboardPanel extends StatelessWidget {
  final _DashboardPanelConfig panel;
  final String Function(_DashboardPanelSize) sizeLabel;
  final bool canMoveBack;
  final bool canMoveForward;
  final VoidCallback onMoveBack;
  final VoidCallback onMoveForward;
  final VoidCallback onHide;
  final ValueChanged<_DashboardPanelSize> onSizeChanged;
  final Widget child;

  const _EditableDashboardPanel({
    required this.panel,
    required this.sizeLabel,
    required this.canMoveBack,
    required this.canMoveForward,
    required this.onMoveBack,
    required this.onMoveForward,
    required this.onHide,
    required this.onSizeChanged,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(
          height: 40,
          child: Row(
            children: [
              Icon(
                Icons.drag_indicator_rounded,
                size: 18,
                color: scheme.onSurfaceVariant,
              ),
              const SizedBox(width: 5),
              Expanded(
                child: Text(
                  panel.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
              ),
              IconButton(
                visualDensity: VisualDensity.compact,
                onPressed: canMoveBack ? onMoveBack : null,
                icon: const Icon(Icons.arrow_back_rounded, size: 18),
                tooltip: l10n('Öne taşı', 'Move earlier'),
              ),
              IconButton(
                visualDensity: VisualDensity.compact,
                onPressed: canMoveForward ? onMoveForward : null,
                icon: const Icon(Icons.arrow_forward_rounded, size: 18),
                tooltip: l10n('Arkaya taşı', 'Move later'),
              ),
              PopupMenuButton<_DashboardPanelSize>(
                tooltip: l10n('Panel boyutu', 'Panel size'),
                onSelected: onSizeChanged,
                itemBuilder: (context) => _DashboardPanelSize.values
                    .map(
                      (size) => PopupMenuItem(
                        value: size,
                        child: Row(
                          children: [
                            Icon(
                              panel.size == size
                                  ? Icons.radio_button_checked_rounded
                                  : Icons.radio_button_unchecked_rounded,
                              size: 18,
                            ),
                            const SizedBox(width: 8),
                            Text(sizeLabel(size)),
                          ],
                        ),
                      ),
                    )
                    .toList(),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 7),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.aspect_ratio_rounded, size: 17),
                      const SizedBox(width: 5),
                      Text(sizeLabel(panel.size)),
                      const Icon(Icons.arrow_drop_down_rounded, size: 18),
                    ],
                  ),
                ),
              ),
              IconButton(
                visualDensity: VisualDensity.compact,
                onPressed: onHide,
                icon: const Icon(Icons.visibility_off_outlined, size: 18),
                tooltip: l10n('Paneli gizle', 'Hide panel'),
              ),
            ],
          ),
        ),
        const SizedBox(height: 6),
        Expanded(child: child),
      ],
    );
  }
}

class _DashboardNoPanels extends StatelessWidget {
  final bool editing;
  final VoidCallback onCustomize;
  final List<_DashboardPanelConfig> hiddenPanels;
  final ValueChanged<_DashboardPanelId> onRestore;

  const _DashboardNoPanels({
    required this.editing,
    required this.onCustomize,
    required this.hiddenPanels,
    required this.onRestore,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        border: Border.all(color: scheme.outlineVariant),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Icon(
            Icons.dashboard_customize_outlined,
            size: 44,
            color: scheme.onSurfaceVariant,
          ),
          const SizedBox(height: 12),
          Text(
            l10n('Gösterilecek panel kalmadı', 'No panels are visible'),
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: 6),
          Text(
            l10n(
              'İhtiyacınız olan panelleri yeniden açabilirsiniz.',
              'You can restore the panels you need.',
            ),
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
          ),
          const SizedBox(height: 16),
          if (!editing)
            FilledButton.icon(
              onPressed: onCustomize,
              icon: const Icon(Icons.tune_rounded),
              label: Text(l10n('Dashboard Düzenle', 'Edit Dashboard')),
            )
          else
            Wrap(
              spacing: 8,
              runSpacing: 8,
              alignment: WrapAlignment.center,
              children: hiddenPanels
                  .map(
                    (panel) => FilledButton.tonalIcon(
                      onPressed: () => onRestore(panel.id),
                      icon: Icon(panel.icon, size: 17),
                      label: Text(panel.title),
                    ),
                  )
                  .toList(),
            ),
        ],
      ),
    );
  }
}
