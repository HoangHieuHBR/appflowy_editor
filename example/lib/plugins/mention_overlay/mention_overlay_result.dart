import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:flutter/material.dart';

import 'mention_overlay_menu.dart';

typedef SelectItemHandler = void Function(
  BuildContext context,
  EditorState editorState,
  MentionOverlayMenuService menuService,
  (int start, int end) replacement,
);

class MentionOverlayMenuItem {
  final String label;
  final Widget Function(bool onSelected)? icon;
  final List<String>? keywords;
  final SelectItemHandler? onSelected;

  MentionOverlayMenuItem({
    required this.label,
    this.icon,
    this.keywords,
    this.onSelected,
  });
}

class MentionOverlayResult {
  final List<MentionOverlayMenuItem> results;

  final List<String>? startsWithKeywords;

  MentionOverlayResult({
    required this.results,
    this.startsWithKeywords,
  });
}
