import 'mention_overlay_result.dart';

abstract class MentionOverlayDelegate {
  Future<MentionOverlayResult> search(String? search);

  Future<void> dispose() async {}
}