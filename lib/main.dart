import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';

import 'features/day/presentation/day_provider.dart';
import 'features/day/presentation/pages/home_page.dart';
import 'features/config/config_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
  await ConfigService.init(); // регистрирует адаптеры и открывает box
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => DayProvider()..init(),
      child: MaterialApp(
        title: 'Mood',
        theme: ThemeData(useMaterial3: true),
        home: const HomePage(),
      ),
    );
  }
}
