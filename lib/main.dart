import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ludo/screens/landing_screen.dart';
import 'firebase_options.dart';
import 'services/firebase_service.dart';
import 'blocs/game/game_bloc.dart';
// You don't need to import audio_service here anymore

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // REMOVED: await AudioService.initialize(); <-- NOT NEEDED for audioplayers

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider(create: (context) => FirebaseService()),
      ],
      child: MultiBlocProvider(
        providers: [
          BlocProvider<GameBloc>(
            create: (context) => GameBloc(
              firebaseService: context.read<FirebaseService>(),
            ),
          ),
        ],
        child: const MaterialApp(
          title: 'Flutter Ludo',
          home: LandingScreen(),
          debugShowCheckedModeBanner: false,
        ),
      ),
    );
  }
}