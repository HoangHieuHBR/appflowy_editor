import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:flutter/material.dart';

class MobileSelectionWrapper extends StatefulWidget {
  final EditorState editorState;
  final Widget child;
  const MobileSelectionWrapper({
    super.key,
    required this.editorState,
    required this.child,
  });

  @override
  State<MobileSelectionWrapper> createState() => _MobileSelectionWrapperState();
}

class _MobileSelectionWrapperState extends State<MobileSelectionWrapper>
    with WidgetsBindingObserver {
  EditorState get editorState => widget.editorState;

  bool _isUpdatingSelection = false;

  String currentPlainText = '';
  String currentNodeType = '';
  int cursorPosition = 0;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addObserver(this);
    editorState.selectionNotifier.addListener(_updateSelection);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    editorState.selectionNotifier.removeListener(_updateSelection);

    super.dispose();
  }

  void _updateSelection() async {
    // Prevent re-entrance if already updating
    if (_isUpdatingSelection) return;

    final selection = editorState.selection;

    if (selection == null || !selection.isCollapsed) {
      return;
    }

    final position = selection.start;
    if (position.offset == 0) {
      return;
    }

    final currentNode = editorState.getNodeAtPath(selection.end.path);

    currentPlainText = currentNode!.delta!.toPlainText();
    cursorPosition = position.offset;

    // currentNodeType = 

    final lastWord =
        currentPlainText.substring(0, position.offset).split(' ').last;

    if (lastWord.length == 1) {
      _isUpdatingSelection = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}
