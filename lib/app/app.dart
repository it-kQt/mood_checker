import "package:flutter/material.dart";
import "package:it_kqt_mood/app/theme.dart";
import "package:it_kqt_mood/features/day/presentation/pages/home_page.dart";

class App extends StatelessWidget {
const App({super.key});

@override
Widget build(BuildContext context) {
return MaterialApp(
title: "Дневник настроения",
theme: lightTheme,
home: const HomePage(),
debugShowCheckedModeBanner: false,
);
}
}
