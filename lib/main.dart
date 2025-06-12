import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'locator.dart';
import 'features/events/presentation/notifier/event_notifier.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await setupLocator();
  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(eventNotifierProvider);
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(title: const Text('Events')),
        body: Center(
          child: state is Loading
              ? const CircularProgressIndicator()
              : state is Loaded
              ? ListView(
                  children: state.events
                      .map(
                        (e) => ListTile(
                          title: Text(e.name),
                          subtitle: Text(e.time.toLocal().toString()),
                        ),
                      )
                      .toList(),
                )
              : state is Error
              ? Text(state.message)
              : ElevatedButton(
                  onPressed: () =>
                      ref.read(eventNotifierProvider.notifier).fetch(),
                  child: const Text('Load Events'),
                ),
        ),
      ),
    );
  }
}
