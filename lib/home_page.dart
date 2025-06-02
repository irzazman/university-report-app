import 'package:flutter/material.dart';
import 'report_page.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  void navigateToReport(BuildContext context, String category) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => ReportPage(category: category)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.colorScheme.background,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: theme.primaryColor,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {},
            tooltip: 'Settings',
          ),
        ],
        title: Row(
          children: [
            Image.asset(
              'assets/utem_logo.png', // Ensure this asset exists
              height: 36,
            ),
            const SizedBox(width: 12),
            Text(
              'UTeM Reporter',
              style: theme.textTheme.titleLarge?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.2,
              ),
            ),
          ],
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Welcome Card
            Card(
              color: Colors.white,
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 16,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Welcome, [User]!",
                      style: theme.textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.primaryColor,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "Please select where the issue is:",
                      style: theme.textTheme.bodyLarge,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 18),
            // Section Selector
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: _SectionCard(
                    label: 'Dorm',
                    icon: Icons.bed_outlined,
                    onTap: () => navigateToReport(context, 'Dorms'),
                    theme: theme,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _SectionCard(
                    label: 'Faculty',
                    icon: Icons.apartment_outlined,
                    onTap: () => navigateToReport(context, 'Faculty'),
                    theme: theme,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _SectionCard(
                    label: 'Campus',
                    icon: Icons.account_balance_outlined,
                    onTap: () => navigateToReport(context, 'Campus Ground'),
                    theme: theme,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            // Recent Reports Card (placeholder)
            Card(
              color: Colors.white,
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 16,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Recent Reports",
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.primaryColor,
                      ),
                    ),
                    const SizedBox(height: 12),
                    // Placeholder: You can replace with your report list widget
                    Text(
                      "No recent reports.",
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Section card widget for Dorm/Faculty/Campus
class _SectionCard extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;
  final ThemeData theme;

  const _SectionCard({
    required this.label,
    required this.icon,
    required this.onTap,
    required this.theme,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Card(
        elevation: 3,
        color: theme.colorScheme.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 8),
          child: Column(
            children: [
              Icon(icon, size: 44, color: theme.primaryColor),
              const SizedBox(height: 10),
              Text(
                label,
                style: theme.textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: theme.primaryColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
