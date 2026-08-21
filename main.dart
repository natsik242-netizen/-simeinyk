import 'dart:async';
import 'package:flutter/material.dart';

void main() {
  runApp(const SimeinykApp());
}

class SimeinykApp extends StatelessWidget {
  const SimeinykApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Сімейник',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF6A8D73)),
        scaffoldBackgroundColor: const Color(0xFFF7F7F2),
        cardTheme: const CardThemeData(
          elevation: 0,
          margin: EdgeInsets.zero,
        ),
      ),
      home: const MainShell(),
    );
  }
}

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int index = 0;

  final pages = const [
    TodayPage(),
    CalendarPage(),
    FamilyPage(),
    TasksPage(),
    MorePage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(child: pages[index]),
      bottomNavigationBar: NavigationBar(
        selectedIndex: index,
        onDestinationSelected: (i) => setState(() => index = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home), label: 'Головна'),
          NavigationDestination(icon: Icon(Icons.calendar_month_outlined), selectedIcon: Icon(Icons.calendar_month), label: 'Календар'),
          NavigationDestination(icon: Icon(Icons.groups_outlined), selectedIcon: Icon(Icons.groups), label: 'Сім’я'),
          NavigationDestination(icon: Icon(Icons.check_circle_outline), selectedIcon: Icon(Icons.check_circle), label: 'Справи'),
          NavigationDestination(icon: Icon(Icons.grid_view_outlined), selectedIcon: Icon(Icons.grid_view_rounded), label: 'Ще'),
        ],
      ),
    );
  }
}

class Header extends StatelessWidget {
  final String title;
  final String? subtitle;
  const Header(this.title, {this.subtitle, super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w800)),
          if (subtitle != null) ...[
            const SizedBox(height: 4),
            Text(subtitle!, style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.black54)),
          ]
        ],
      ),
    );
  }
}

class SectionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;

  const SectionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.onTap,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: CircleAvatar(
          backgroundColor: Theme.of(context).colorScheme.primaryContainer,
          child: Icon(icon),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}

class TodayPage extends StatefulWidget {
  const TodayPage({super.key});

  @override
  State<TodayPage> createState() => _TodayPageState();
}

class _TodayPageState extends State<TodayPage> {
  Timer? timer;
  DateTime? sleepStartedAt;
  Duration elapsed = Duration.zero;

  bool get sleeping => sleepStartedAt != null;

  void toggleSleep() {
    if (!sleeping) {
      sleepStartedAt = DateTime.now();
      elapsed = Duration.zero;
      timer = Timer.periodic(const Duration(seconds: 1), (_) {
        if (!mounted || sleepStartedAt == null) return;
        setState(() {
          elapsed = DateTime.now().difference(sleepStartedAt!);
        });
      });
      setState(() {});
    } else {
      timer?.cancel();
      setState(() {
        sleepStartedAt = null;
      });
    }
  }

  String fmt(Duration d) {
    String two(int n) => n.toString().padLeft(2, '0');
    return '${two(d.inHours)}:${two(d.inMinutes.remainder(60))}:${two(d.inSeconds.remainder(60))}';
  }

  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.only(bottom: 24),
      children: [
        const Header('Сімейник', subtitle: 'Уся сім’я — в одному місці'),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Сон дитини', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
                  const SizedBox(height: 8),
                  Text(
                    sleeping ? fmt(elapsed) : 'Таймер не запущено',
                    style: const TextStyle(fontSize: 30, fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: toggleSleep,
                      icon: Icon(sleeping ? Icons.wb_sunny_outlined : Icons.bedtime_outlined),
                      label: Text(sleeping ? 'Прокинувся — зупинити' : 'Заснув — запустити'),
                    ),
                  )
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 14),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            children: const [
              SectionCard(icon: Icons.medication_outlined, title: 'Ліки о 18:00', subtitle: 'Нагадування для члена сім’ї'),
              SizedBox(height: 10),
              SectionCard(icon: Icons.pets_outlined, title: 'Обробка тварини', subtitle: 'Через 3 дні'),
              SizedBox(height: 10),
              SectionCard(icon: Icons.cake_outlined, title: 'День народження', subtitle: 'Через 6 днів'),
              SizedBox(height: 10),
              SectionCard(icon: Icons.home_outlined, title: 'Оренда', subtitle: 'До 25 числа'),
              SizedBox(height: 10),
              SectionCard(icon: Icons.directions_car_outlined, title: 'ТО автомобіля', subtitle: 'Через 1 200 км'),
            ],
          ),
        ),
      ],
    );
  }
}

class CalendarPage extends StatelessWidget {
  const CalendarPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: [
        const Header('Календар', subtitle: 'Особисті та сімейні події'),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            children: const [
              SectionCard(icon: Icons.person_outline, title: 'Мій календар', subtitle: 'Особисті події та нагадування'),
              SizedBox(height: 10),
              SectionCard(icon: Icons.groups_outlined, title: 'Сімейний календар', subtitle: 'Спільні події сім’ї'),
              SizedBox(height: 10),
              SectionCard(icon: Icons.cake_outlined, title: 'Дні народження', subtitle: 'Щорічні нагадування'),
              SizedBox(height: 10),
              SectionCard(icon: Icons.notifications_active_outlined, title: 'Будильники', subtitle: 'Події, ліки, платежі, ТО'),
            ],
          ),
        ),
      ],
    );
  }
}

class FamilyPage extends StatelessWidget {
  const FamilyPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: [
        const Header('Мій акаунт', subtitle: 'Кілька сімей та персональні доступи'),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            children: const [
              SectionCard(icon: Icons.account_circle_outlined, title: 'Мій профіль', subtitle: 'Мої дані, здоров’я, документи'),
              SizedBox(height: 10),
              SectionCard(icon: Icons.family_restroom_outlined, title: 'Мої сім’ї', subtitle: 'Можна бути учасником кількох сімей'),
              SizedBox(height: 10),
              SectionCard(icon: Icons.lock_open_outlined, title: 'Доступне мені', subtitle: 'Дані, які інші відкрили для мене'),
              SizedBox(height: 10),
              SectionCard(icon: Icons.child_care_outlined, title: 'Мої діти', subtitle: 'Сон, харчування, здоров’я, документи'),
              SizedBox(height: 10),
              SectionCard(icon: Icons.pets_outlined, title: 'Мої тварини', subtitle: 'Вакцинації, лікування, годування, документи'),
              SizedBox(height: 10),
              SectionCard(icon: Icons.directions_car_outlined, title: 'Мої авто', subtitle: 'ТО, пробіг, страховка, документи'),
            ],
          ),
        ),
      ],
    );
  }
}

class TasksPage extends StatelessWidget {
  const TasksPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: [
        const Header('Справи', subtitle: 'Особисті та сімейні завдання'),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            children: const [
              SectionCard(icon: Icons.shopping_cart_outlined, title: 'Списки покупок', subtitle: 'Продукти, аптека, товари для дому'),
              SizedBox(height: 10),
              SectionCard(icon: Icons.task_alt_outlined, title: 'Сімейні завдання', subtitle: 'Призначення відповідального та дедлайн'),
              SizedBox(height: 10),
              SectionCard(icon: Icons.payments_outlined, title: 'Платежі', subtitle: 'Оренда, комунальні, підписки, страхування'),
            ],
          ),
        ),
      ],
    );
  }
}

class MorePage extends StatelessWidget {
  const MorePage({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: [
        const Header('Ще'),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            children: const [
              SectionCard(icon: Icons.favorite_border, title: 'Здоров’я', subtitle: 'Лікарі, операції, група крові, цикл, лікування'),
              SizedBox(height: 10),
              SectionCard(icon: Icons.folder_copy_outlined, title: 'Документи', subtitle: 'Особисті, медичні, авто, майно'),
              SizedBox(height: 10),
              SectionCard(icon: Icons.home_work_outlined, title: 'Майно', subtitle: 'Квартири, будинки, гаражі'),
              SizedBox(height: 10),
              SectionCard(icon: Icons.account_balance_wallet_outlined, title: 'Бюджет', subtitle: 'Витрати, доходи, регулярні платежі'),
              SizedBox(height: 10),
              SectionCard(icon: Icons.security_outlined, title: 'Приватність і доступи', subtitle: 'Хто і що може бачити'),
              SizedBox(height: 10),
              SectionCard(icon: Icons.settings_outlined, title: 'Налаштування', subtitle: 'Профіль, сповіщення, зовнішній вигляд'),
            ],
          ),
        ),
      ],
    );
  }
}
