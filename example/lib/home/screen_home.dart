import 'package:blocx_example/list/users/screen_users.dart';
import 'package:flutter/material.dart';

class ScreenHome extends StatefulWidget {
  const ScreenHome({super.key});

  @override
  State<ScreenHome> createState() => _ScreenHomeState();
}

class _ScreenHomeState extends State<ScreenHome> {
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [item("list", "list"), item("form", "form"), item("detail", "detail")],
    );
  }

  Widget item(String title, String route) {
    return InkWell(
      onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (c) => ScreenUsers())),
      child: Padding(
        padding: EdgeInsets.all(8),
        child: Card(child: Text(title, style: Theme.of(context).textTheme.headlineMedium)),
      ),
    );
  }
}
