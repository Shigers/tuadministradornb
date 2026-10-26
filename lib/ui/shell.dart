import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../core/theme.dart';
import '../core/utils.dart';
import '../data/app_controller.dart';
import 'upload_flow.dart';
import 'widgets.dart';

class AppDestination {
  const AppDestination(this.path, this.label, this.icon, this.selectedIcon);

  final String path;
  final String label;
  final IconData icon;
  final IconData selectedIcon;
}

const appDestinations = <AppDestination>[
  AppDestination(
    '/',
    'Inicio',
    Icons.space_dashboard_outlined,
    Icons.space_dashboard,
  ),
  AppDestination('/inbox', 'Bandeja', Icons.inbox_outlined, Icons.inbox),
  AppDestination(
    '/documents',
    'Documentos',
    Icons.description_outlined,
    Icons.description,
  ),
  AppDestination(
    '/folders',
    'Carpetas',
    Icons.account_tree_outlined,
    Icons.account_tree,
  ),
  AppDestination('/export', 'Exportar', Icons.archive_outlined, Icons.archive),
  AppDestination('/team', 'Equipo', Icons.group_outlined, Icons.group),
  AppDestination(
    '/settings',
    'Ajustes',
    Icons.settings_outlined,
    Icons.settings,
  ),
];

class AppShell extends StatefulWidget {
  const AppShell({super.key, required this.currentPath, required this.child});

  final String currentPath;
  final Widget child;

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  late final TextEditingController _search;

  @override
  void initState() {
    super.initState();
    _search = TextEditingController();
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  AppDestination get _current {
    for (final destination in appDestinations) {
      if (destination.path == widget.currentPath) return destination;
    }
    return appDestinations.first;
  }

  void _navigate(String path) {
    context.go(path);
  }

  void _searchDocuments(String query) {
    final trimmed = query.trim();
    if (trimmed.isEmpty) return;
    context.go('/documents?q=${Uri.encodeComponent(trimmed)}');
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth >= 1024;
        if (wide) {
          return Scaffold(
            body: Row(
              children: [
                _Sidebar(
                  currentPath: widget.currentPath,
                  onNavigate: _navigate,
                ),
                const VerticalDivider(width: 1, thickness: 1),
                Expanded(
                  child: Column(
                    children: [
                      _DesktopTopBar(
                        searchController: _search,
                        onSearch: _searchDocuments,
                        onNavigate: _navigate,
                      ),
                      Expanded(
                        child: Align(
                          alignment: Alignment.topCenter,
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 1360),
                            child: widget.child,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        }

        final bottomIndex = _bottomIndex(widget.currentPath);
        return Scaffold(
          key: _scaffoldKey,
          drawer: Drawer(
            width: 286,
            child: SafeArea(
              child: _SidebarContent(
                currentPath: widget.currentPath,
                onNavigate: (path) {
                  Navigator.of(context).pop();
                  _navigate(path);
                },
              ),
            ),
          ),
          appBar: AppBar(
            backgroundColor: AppColors.surface,
            surfaceTintColor: Colors.transparent,
            elevation: 0,
            scrolledUnderElevation: 0.5,
            titleSpacing: 4,
            title: Text(
              _current.label,
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: AppColors.ink,
              ),
            ),
            actions: const [
              Padding(
                padding: EdgeInsets.only(right: 12),
                child: _MobileUploadAction(),
              ),
            ],
            bottom: const PreferredSize(
              preferredSize: Size.fromHeight(1),
              child: Divider(height: 1),
            ),
          ),
          body: widget.child,
          bottomNavigationBar: NavigationBar(
            selectedIndex: bottomIndex,
            height: 66,
            backgroundColor: AppColors.surface,
            indicatorColor: AppColors.accentSoft,
            labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
            onDestinationSelected: (index) {
              if (index == 4) {
                _scaffoldKey.currentState?.openDrawer();
                return;
              }
              _navigate(['/', '/inbox', '/documents', '/folders'][index]);
            },
            destinations: const [
              NavigationDestination(
                icon: Icon(Icons.space_dashboard_outlined),
                selectedIcon: Icon(Icons.space_dashboard),
                label: 'Inicio',
              ),
              NavigationDestination(
                icon: Icon(Icons.inbox_outlined),
                selectedIcon: Icon(Icons.inbox),
                label: 'Bandeja',
              ),
              NavigationDestination(
                icon: Icon(Icons.description_outlined),
                selectedIcon: Icon(Icons.description),
                label: 'Documentos',
              ),
              NavigationDestination(
                icon: Icon(Icons.account_tree_outlined),
                selectedIcon: Icon(Icons.account_tree),
                label: 'Carpetas',
              ),
              NavigationDestination(icon: Icon(Icons.menu), label: 'Más'),
            ],
          ),
        );
      },
    );
  }

  int _bottomIndex(String path) {
    final index = ['/', '/inbox', '/documents', '/folders'].indexOf(path);
    return index < 0 ? 4 : index;
  }
}

class _MobileUploadAction extends StatelessWidget {
  const _MobileUploadAction();

  @override
  Widget build(BuildContext context) {
    final controller = context.read<AppController>();
    return UploadMenuButton(controller: controller);
  }
}

class _Sidebar extends StatelessWidget {
  const _Sidebar({required this.currentPath, required this.onNavigate});

  final String currentPath;
  final ValueChanged<String> onNavigate;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 256,
      color: AppColors.surface,
      child: SafeArea(
        child: _SidebarContent(
          currentPath: currentPath,
          onNavigate: onNavigate,
        ),
      ),
    );
  }
}

class _SidebarContent extends StatelessWidget {
  const _SidebarContent({required this.currentPath, required this.onNavigate});

  final String currentPath;
  final ValueChanged<String> onNavigate;

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<AppController>();
    final company = controller.settings.companyName;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 22, 16, 20),
          child: Row(
            children: [
              const AppMark(size: 42),
              const SizedBox(width: 11),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    RichText(
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      text: const TextSpan(
                        style: TextStyle(
                          fontSize: 14.5,
                          fontWeight: FontWeight.w800,
                          color: AppColors.ink,
                          letterSpacing: -0.3,
                        ),
                        children: [
                          TextSpan(text: 'TuAdministrador'),
                          TextSpan(
                            text: 'NB',
                            style: TextStyle(color: AppColors.accent),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      company.isEmpty ? 'Archivo digital' : company,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall
                          ?.copyWith(fontSize: 11.5),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Text(
            'ARCHIVO',
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              fontSize: 10,
              letterSpacing: 1.4,
              color: AppColors.muted,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            children: [
              for (final destination in appDestinations)
                _SidebarItem(
                  destination: destination,
                  selected: currentPath == destination.path,
                  onTap: () => onNavigate(destination.path),
                ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(12),
          child: _StorageCard(
            documents: controller.totalDocuments,
            bytes: controller.totalBytes,
            onTap: () => onNavigate('/settings'),
          ),
        ),
      ],
    );
  }
}

class _SidebarItem extends StatelessWidget {
  const _SidebarItem({
    required this.destination,
    required this.selected,
    required this.onTap,
  });

  final AppDestination destination;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final icon = selected ? destination.selectedIcon : destination.icon;
    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: Material(
        color: selected ? AppColors.navySoft : Colors.transparent,
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(10),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              children: [
                Icon(
                  icon,
                  size: 19,
                  color: selected ? AppColors.navy : AppColors.inkSoft,
                ),
                const SizedBox(width: 11),
                Expanded(
                  child: Text(
                    destination.label,
                    style: TextStyle(
                      fontSize: 13.5,
                      fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                      color: selected ? AppColors.navy : AppColors.inkSoft,
                    ),
                  ),
                ),
                if (destination.path == '/inbox' &&
                    context.watch<AppController>().pendingCount > 0)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.amberSoft,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '${context.watch<AppController>().pendingCount}',
                      style: const TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w700,
                        color: AppColors.amber,
                      ),
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

class _StorageCard extends StatelessWidget {
  const _StorageCard({
    required this.documents,
    required this.bytes,
    required this.onTap,
  });

  final int documents;
  final int bytes;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surfaceAlt,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.all(13),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.lock_outline,
                    size: 15,
                    color: AppColors.accentDark,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Modo local',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600,
                      color: AppColors.accentDark,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 9),
              Text(
                humanBytes(bytes),
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.ink,
                ),
              ),
              Text(
                '$documents documento${documents == 1 ? '' : 's'} · sin cuotas',
                style: Theme.of(context).textTheme.bodySmall
                    ?.copyWith(fontSize: 11),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DesktopTopBar extends StatelessWidget {
  const _DesktopTopBar({
    required this.searchController,
    required this.onSearch,
    required this.onNavigate,
  });

  final TextEditingController searchController;
  final ValueChanged<String> onSearch;
  final ValueChanged<String> onNavigate;

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<AppController>();
    final initial = controller.settings.ownerName.trim().isEmpty
        ? 'A'
        : controller.settings.ownerName.trim().substring(0, 1).toUpperCase();

    return Container(
      height: 72,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(bottom: BorderSide(color: AppColors.border)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Align(
              alignment: Alignment.centerLeft,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 360),
                child: SearchField(
                  controller: searchController,
                  hint: 'Buscar en el archivo…',
                  onSubmitted: onSearch,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          UploadMenuButton(controller: controller, expanded: true),
          const SizedBox(width: 14),
          IconButton(
            tooltip: 'Equipo',
            onPressed: () => onNavigate('/team'),
            icon: const Icon(Icons.help_outline, size: 20),
          ),
          const SizedBox(width: 4),
          InkWell(
            onTap: () => onNavigate('/settings'),
            borderRadius: BorderRadius.circular(30),
            child: CircleAvatar(
              radius: 17,
              backgroundColor: AppColors.navySoft,
              child: Text(
                initial,
                style: const TextStyle(
                  color: AppColors.navy,
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
