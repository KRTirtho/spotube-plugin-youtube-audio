import 'package:youtube_explode_dart/youtube_explode_dart.dart';

class YouTubeExplodeEngine {
  final YoutubeExplode yt = YoutubeExplode();

  YouTubeExplodeEngine();
  
  Future<Map<String, dynamic>> getVideo(String videoId) {
    return yt.videos
        .get(videoId)
        .then(
          (video) => {
            'id': video.id.value,
            'title': video.title,
            'author': video.author,
            'duration': video.duration?.inSeconds,
            'description': video.description,
            'uploadDate': video.uploadDate?.toIso8601String(),
            'viewCount': video.engagement.viewCount,
            'likeCount': video.engagement.likeCount,
            'isLive': video.isLive,
          },
        );
  }

  
  Future<List<Map<String, dynamic>>> search(String query) async {
    final results = await yt.search.search(query, filter: TypeFilters.video);

    return results
        .map(
          (video) => {
            'id': video.id.value,
            'title': video.title,
            'author': video.author,
            'duration': video.duration?.inSeconds,
            'description': video.description,
            'uploadDate': video.uploadDate?.toIso8601String(),
            'viewCount': video.engagement.viewCount,
            'likeCount': video.engagement.likeCount,
            'isLive': video.isLive,
          },
        )
        .toList();
  }

  
  Future<List<Map<String, dynamic>>> streamManifest(String videoId) async {
    final manifest = await yt.videos.streams.getManifest(videoId);
    final streams =
        manifest.audioOnly
            .map(
              (stream) => {
                'url': stream.url.toString(),
                'quality': stream.qualityLabel,
                'bitrate': stream.bitrate.bitsPerSecond,
                'container': stream.container.name,
                'videoId': stream.videoId,
              },
            )
            .toList();

    return streams;
  }
}