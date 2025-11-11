import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'screens/chat_screen.dart';
import 'providers/conversation_provider.dart';
import 'providers/message_provider.dart';
import 'providers/model_provider.dart';
import 'api_client.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await dotenv.load(fileName: "assets/.env");
  } catch (e) {
    debugPrint("❌ 错误: 缺少 assets/.env 文件或加载失败: $e");
    exit(-1);
  }

  final apiBaseUrl = dotenv.env['API_BASE_URL'];
  if (apiBaseUrl == null || apiBaseUrl.isEmpty) {
    debugPrint("❌ .env 文件必须包含 API_BASE_URL");
    exit(-1);
  }

  final apiClient = ApiClient(apiBaseUrl);
  runApp(MyApp(apiClient: apiClient));
}

class MyApp extends StatelessWidget {
  final ApiClient apiClient;
  const MyApp({super.key, required this.apiClient});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => ModelProvider(apiClient: apiClient),
        ),
        ChangeNotifierProvider(
          create: (_) => ConversationProvider(apiClient: apiClient),
        ),
        ChangeNotifierProxyProvider<ConversationProvider, MessageProvider>(
          create: (context) {
            final messageProvider = MessageProvider(apiClient: apiClient);

            messageProvider.onConversationIdCreated = (newId) {
              print("Create new ID $newId");
              context.read<ConversationProvider>().setConversationId(newId);
            };

            return messageProvider;
          },
          update: (context, conversationProvider, messageProvider) {
            final convId = conversationProvider.selectedConversationId;
            messageProvider!.onConversationIdCreated = (newId) {
              print("Create new ID $newId");
              context.read<ConversationProvider>().setConversationId(newId);
            };
            messageProvider.updateAndLoadMessages(convId);

            return messageProvider;
          },
        ),
      ],
      child: MaterialApp(
        title: 'AI Chat',
        debugShowCheckedModeBanner: false,
        home: const HomeBootstrap(),
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
          useMaterial3: true,
        ),
        darkTheme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: Colors.blue,
            brightness: Brightness.dark,
          ),
          useMaterial3: true,
        ),
        themeMode: ThemeMode.system,
      ),
    );
  }
}

class HomeBootstrap extends StatefulWidget {
  const HomeBootstrap({super.key});
  @override
  State<HomeBootstrap> createState() => _HomeBootstrapState();
}

class _HomeBootstrapState extends State<HomeBootstrap> {
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initApp();
    });
  }

  Future<void> _initApp() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final convProvider = context.read<ConversationProvider>();
      final modelProvider = context.read<ModelProvider>();

      await Future.wait([
        convProvider.loadConversations(),
        modelProvider.loadModels(),
      ]);

      if (mounted) {
        setState(() => _loading = false);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _loading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_error != null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('AI Chat 初始化失败'),
        ),
        body: SingleChildScrollView(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  "加载失败: $_error",
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.red),
                ),
                const SizedBox(height: 20),
                ElevatedButton.icon(
                  onPressed: _initApp,
                  icon: const Icon(Icons.refresh),
                  label: const Text("重试连接"),
                ),
                const SizedBox(height: 10),
                const Text(
                  "请检查网络或 API 地址配置 (.env 文件)",
                  style: TextStyle(fontSize: 14, color: Colors.grey),
                ),
              ],
            ),
          ),
        )
      );
    }

    return const ChatScreen();
  }
}