import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ludo/screens/landing_screen.dart';
import 'firebase_options.dart';
import 'services/firebase_service.dart';
// Note: We don't need to inject AudioService anymore because it is static.
import 'blocs/game/game_bloc.dart';

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
        // Removed AudioService provider (It is static now)
      ],
      child: MultiBlocProvider(
        providers: [
          BlocProvider<GameBloc>(
            create: (context) => GameBloc(
              // Updated to match the new GameBloc constructor
              firebaseService: context.read<FirebaseService>(),
            ),
          ),
        ],
        child: const MaterialApp( // Added const for performance
          title: 'Flutter Ludo',
          home: LandingScreen(),
          debugShowCheckedModeBanner: false,
        ),
      ),
    );
  }
}