import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'firebase_options.dart';
import 'services/firebase_service.dart';
import 'services/audio_service.dart'; // <--- Import AudioService
import 'blocs/game/game_bloc.dart';
import 'screens/home_menu.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider(create: (context) => FirebaseService()),
        // 1. Create the AudioService here
        RepositoryProvider(create: (context) => AudioService()),
      ],
      child: MultiBlocProvider(
        providers: [
          BlocProvider<GameBloc>(
            create: (context) => GameBloc(
              context.read<FirebaseService>(),
              context.read<AudioService>(), // 2. Inject it into GameBloc
            ),
          ),
        ],
        child: MaterialApp(
          title: 'Flutter Ludo',
          home: const HomeMenu(),
        ),
      ),
    );
  }
}