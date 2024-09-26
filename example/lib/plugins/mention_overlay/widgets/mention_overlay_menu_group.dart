
import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:collection/collection.dart';
import 'package:example/plugins/mention_overlay/mention_overlay_result.dart';
import 'package:flutter/material.dart';

import '../../../widgets/widgets.dart';
import '../mention_overlay_menu.dart';
import 'mention_overlay_handler.dart';

class MentionOverlayGroup extends StatelessWidget {
  const MentionOverlayGroup({
    super.key,
    required this.result,
    required this.editorState,
    required this.menuService,
    required this.style,
    required this.onSelected,
    required this.startOffset,
    required this.endOffset,
    this.isLastGroup = false,
    this.isGroupSelected = false,
    this.selectedIndex = 0,
  });

  final MentionOverlayResult result;
  final EditorState editorState;
  final MentionOverlayMenuService menuService;
  final MentionOverlayMenuStyle style;
  final VoidCallback onSelected;
  final int startOffset;
  final int endOffset;

  final bool isLastGroup;
  final bool isGroupSelected;
  final int selectedIndex;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: isLastGroup ? EdgeInsets.zero : const EdgeInsets.only(bottom: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 4),
          ...result.results.mapIndexed(
            (index, item) => InlineActionsWidget(
              item: item,
              editorState: editorState,
              menuService: menuService,
              isSelected: isGroupSelected && index == selectedIndex,
              style: style,
              onSelected: onSelected,
              startOffset: startOffset,
              endOffset: endOffset,
            ),
          ),
        ],
      ),
    );
  }
}

class InlineActionsWidget extends StatefulWidget {
  const InlineActionsWidget({
    super.key,
    required this.item,
    required this.editorState,
    required this.menuService,
    required this.isSelected,
    required this.style,
    required this.onSelected,
    required this.startOffset,
    required this.endOffset,
  });

  final MentionOverlayMenuItem item;
  final EditorState editorState;
  final MentionOverlayMenuService menuService;
  final bool isSelected;
  final MentionOverlayMenuStyle style;
  final VoidCallback onSelected;
  final int startOffset;
  final int endOffset;

  @override
  State<InlineActionsWidget> createState() => _InlineActionsWidgetState();
}

class _InlineActionsWidgetState extends State<InlineActionsWidget> {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: SizedBox(
        width: kInlineMenuWidth,
        child: FlowyButton(
          expand: true,
          isSelected: widget.isSelected,
          leftIcon: widget.item.icon?.call(widget.isSelected),
          text: FlowyText.regular(
            widget.item.label,
            figmaLineHeight: 18,
          ),
          onTap: _onPressed,
        ),
      ),
    );
  }

  void _onPressed() {
    widget.onSelected();
    widget.item.onSelected?.call(
      context,
      widget.editorState,
      widget.menuService,
      (widget.startOffset, widget.endOffset),
    );
  }
}