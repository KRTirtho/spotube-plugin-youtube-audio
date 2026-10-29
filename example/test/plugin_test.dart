import 'package:example/localstorage.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hetu_script/hetu_script.dart';
import 'package:hetu_spotube_plugin/hetu_spotube_plugin.dart';
import 'package:hetu_std/hetu_std.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Same shape as the YouTubeEngine bridge in Spotube 5.1.2 (duration in seconds)
Map<String, dynamic> video(String id, {int? duration = 210, bool isLive = false}) => {
      'id': id,
      'title': 'Video $id',
      'author': 'Author $id',
      'duration': duration,
      'isLive': isLive,
    };

final fakeEngine = YouTubeEngine(
  search: (query) async => [
    video('regular'),
    // Spotube 5.1.2's NewPipe engine flags regular videos as live
    video('newpipe', isLive: true),
    video('no-duration', duration: null),
  ],
  getVideo: (id) async => video(id),
  streamManifest: (id) async => [
    {'url': 'https://a/mp4', 'container': 'mp4', 'bitrate': 130000, 'videoId': id},
    {'url': 'https://a/webm', 'container': 'webm', 'bitrate': 160000, 'videoId': id},
  ],
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Hetu hetu;

  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    hetu = Hetu()..init();
    HetuStdLoader.loadBindings(hetu);
    await HetuStdLoader.loadBytecodeFlutter(hetu);
    await HetuSpotubePluginLoader.loadBytecodeFlutter(hetu);
    final byteCode = await rootBundle.load('assets/bytecode/plugin.out');
    hetu.loadBytecode(bytes: byteCode.buffer.asUint8List(), moduleName: 'plugin');
    HetuSpotubePluginLoader.loadBindings(
      hetu,
      localStorageImpl: SharedPreferencesLocalStorage(await SharedPreferences.getInstance()),
      onNavigatorPush: (_) {},
      onNavigatorPop: () {},
      onShowForm: (_, __) async => [],
      createYoutubeEngine: () => fakeEngine,
    );
    // Mirrors how Spotube 5.1.2 instantiates the plugin from plugin.json's entryPoint
    hetu.eval('''
      import "module:plugin" as plugin
      var Plugin = plugin.YouTubeAudioSourcePlugin
      var metadataPlugin = Plugin()
    ''');
  });

  test('matches keeps every result and returns duration in microseconds', () async {
    final result = await hetu.eval('''
      metadataPlugin.audioSource.matches({
        "name": "Robot Voices",
        "artists": [{"name": "Twenty One Pilots"}],
      }.toJson())
    ''');
    final matches = List<Map>.from(result);

    expect(matches.map((m) => m['id']), ['regular', 'newpipe', 'no-duration']);
    expect(matches[0]['duration'], 210 * 1000000);
    expect(matches[2]['duration'], 0);
    expect(matches[0]['externalUri'], 'https://youtube.com/watch?v=regular');
  });

  test('streams are lossy with the codec of their container', () async {
    final result = await hetu.eval('''
      metadataPlugin.audioSource.streams({"id": "regular"}.toJson())
    ''');
    final streams = List<Map>.from(result);

    expect(streams.map((s) => s['type']), ['lossy', 'lossy']);
    expect(streams.map((s) => s['codec']), ['aac', 'opus']);
    expect(streams.map((s) => s['container']), ['mp4', 'webm']);
  });
}
