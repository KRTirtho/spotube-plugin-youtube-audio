import 'package:desktop_webview_window/desktop_webview_window.dart';
import 'package:example/localstorage.dart';
import 'package:example/youtube.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get_it/get_it.dart';
import 'package:hetu_script/hetu_script.dart';
import 'package:hetu_spotube_plugin/hetu_spotube_plugin.dart';
import 'package:hetu_std/hetu_std.dart';
import 'package:shared_preferences/shared_preferences.dart';

final getIt = GetIt.instance;

void main(List<String> args) async {
  WidgetsFlutterBinding.ensureInitialized();

  if (runWebViewTitleBarWidget(args)) {
    return;
  }

  final hetu = Hetu();
  getIt.registerSingleton<Hetu>(hetu);
  getIt.registerSingleton<SharedPreferences>(
    await SharedPreferences.getInstance(),
  );

  hetu.init();
  HetuStdLoader.loadBindings(hetu);

  await HetuStdLoader.loadBytecodeFlutter(hetu);
  await HetuSpotubePluginLoader.loadBytecodeFlutter(hetu);
  final byteCode = await rootBundle.load("assets/bytecode/plugin.out");
  await hetu.loadBytecode(
    bytes: byteCode.buffer.asUint8List(),
    moduleName: "plugin",
  );

  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(home: Scaffold(body: MyHome()));
  }
}

class MyHome extends StatefulWidget {
  const MyHome({super.key});

  @override
  State<MyHome> createState() => _MyHomeState();
}

class _MyHomeState extends State<MyHome> {
  @override
  void initState() {
    super.initState();
    final hetu = getIt<Hetu>();
    BuildContext? pageContext;
    HetuSpotubePluginLoader.loadBindings(
      hetu,
      localStorageImpl: SharedPreferencesLocalStorage(
        getIt<SharedPreferences>(),
      ),
      onNavigatorPush: (route) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) {
              pageContext = context;
              return Scaffold(
                appBar: AppBar(title: const Text('WebView')),
                body: route,
              );
            },
          ),
        );
      },
      onNavigatorPop: () {
        if (pageContext == null) {
          return;
        }
        Navigator.pop(pageContext!);
      },
      onShowForm: (title, fields) async {
        return [];
      },
      createYoutubeEngine: () {
        final ytEngine = YouTubeExplodeEngine();
        return YouTubeEngine(
          search: ytEngine.search,
          getVideo: ytEngine.getVideo,
          streamManifest: ytEngine.streamManifest,
        );
      },
    );

    hetu.eval(r"""
    import "module:plugin" as plugin;

    var YouTubeAudioSourcePlugin = plugin.YouTubeAudioSourcePlugin;
    var metadata = YouTubeAudioSourcePlugin()
    """);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Audio Source"),
          Row(
            spacing: 12,
            children: [
              ElevatedButton(
                onPressed: () async {
                  final result = await getIt<Hetu>().eval(
                    """
                      metadata.audioSource.matches({
                        'isrc': 'USAT22505503',
                        'title': 'Robot Voices',
                        'artists': [{'name':'Twenty One Pilots'}]
                      }.toJson())
                    """,
                  );
                  debugPrint(result.toString());
                },
                child: Text("Match/Search audio"),
              ),
              ElevatedButton(
                onPressed: () async {
                  final result = await getIt<Hetu>().eval(
                    """
                      metadata.audioSource.streams({
                        'id': 'o-LPIqIGuH0',
                      }.toJson())
                    """,
                  );
                  debugPrint(result.toString());
                },
                child: Text("Get match Stream"),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
