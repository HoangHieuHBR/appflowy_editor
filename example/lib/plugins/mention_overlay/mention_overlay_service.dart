import 'package:example/plugins/mention_overlay/service_handler.dart';
import 'package:flutter/material.dart';

abstract class _MentionOverlayProvider {
  void dispose();
}

class MentionOverlayService extends _MentionOverlayProvider {
  MentionOverlayService({
    required this.context,
    required this.handlers,
  });

  BuildContext? context;

  final List<MentionOverlayDelegate> handlers;

  /// This is a workaround for not having a mounted check.
  /// Thus when the widget that uses the service is disposed,
  /// we set the [BuildContext] to null.
  ///
  @override
  Future<void> dispose() async {
    for (final handler in handlers) {
      await handler.dispose();
    }
    context = null;
  }
}