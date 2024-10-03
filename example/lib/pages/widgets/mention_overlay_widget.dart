import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

enum OverlayBuilderType { mention, information }

class ReplacementInfo {
  final int start;
  final int end;
  final String oldString;
  final String content;
  final int index;

  const ReplacementInfo({
    required this.index,
    required this.oldString,
    required this.content,
    this.start = 0,
    this.end = 0,
  });
}

class MentionOverlayHandler extends StatefulWidget {
  final Widget child;
  final EditorState editorState;
  final String currentPlainText;
  final String currentNodeType;
  final int cursorPosition;

  const MentionOverlayHandler({
    super.key,
    required this.child,
    required this.editorState,
    this.currentPlainText = '',
    this.currentNodeType = '',
    this.cursorPosition = 0,
  });

  @override
  State<MentionOverlayHandler> createState() => _MentionOverlayHandlerState();
}

class _MentionOverlayHandlerState extends State<MentionOverlayHandler> {
  EditorState get editorState => widget.editorState;

  List<String> mentionData = ['everyone', 'channel', 'here'];

  OverlayEntry? _selectionMenuEntry;

  bool _selectionUpdateByInner = false;
  Offset _offset = Offset.zero;
  Alignment _alignment = Alignment.topLeft;

  int oldExtentOffset = -1; //To skip the click toolbar button action

  final mentionPattern = r"(?:^|\s)(@(?!\@)(?:\S|$)+)";

  @override
  void initState() {
    super.initState();
    mentionData = [
      ...mentionData,
      ...List.generate(20, (index) => "Hoang Hieu$index")
    ];
    editorState.selectionNotifier.addListener(_mentionAndHashtagListener);
  }

  @override
  void dispose() {
    editorState.selectionNotifier.removeListener(_mentionAndHashtagListener);
    super.dispose();
  }

  SelectionMenuStyle get style => SelectionMenuStyle.light;

  void _onSelectionChange() {
    // workaround: SelectionService has been released after hot reload.
    final isSelectionDisposed =
        editorState.service.selectionServiceKey.currentState == null;
    if (!isSelectionDisposed) {
      final selectionService = editorState.service.selectionService;
      if (selectionService.currentSelection.value == null) {
        return;
      }
    }

    if (_selectionUpdateByInner) {
      _selectionUpdateByInner = false;
      return;
    }

    dismiss();
  }

  void dismiss() {
    if (_selectionMenuEntry != null) {
      editorState.service.keyboardService?.enable();
      editorState.service.scrollService?.enable();
    }

    _selectionMenuEntry?.remove();
    _selectionMenuEntry = null;

    // workaround: SelectionService has been released after hot reload.
    final isSelectionDisposed =
        editorState.service.selectionServiceKey.currentState == null;
    if (!isSelectionDisposed) {
      final selectionService = editorState.service.selectionService;
      // focus to reload the selection after the menu dismissed.
      editorState.selection = editorState.selection;
      selectionService.currentSelection.removeListener(_onSelectionChange);
    }
  }

  List<String> getMatchingMentions(String mentionText) {
    String normalizedText = mentionText.startsWith('@')
        ? mentionText.substring(1).toLowerCase()
        : mentionText.toLowerCase();

    return mentionData
        .where((mention) => mention.toLowerCase().startsWith(normalizedText))
        .toList();
  }

  void _mentionAndHashtagListener() {
    String currentPlainText = widget.currentPlainText;
    int extentOffset = widget.cursorPosition;

    if (oldExtentOffset == extentOffset) return;

    oldExtentOffset = extentOffset;

    if (currentPlainText.isEmpty) {
      dismiss();
    } else {
      final String currentTextBeforeCursor =
          currentPlainText.substring(0, extentOffset);

      if (currentTextBeforeCursor.endsWith('@')) {
        _handleReplaceText(
          '@',
          mentionData,
          currentTextBeforeCursor.length - 1,
          currentTextBeforeCursor.length,
        );
        return;
      }

      if (currentTextBeforeCursor.endsWith(' ') ||
          currentTextBeforeCursor.endsWith('\n')) {
        dismiss();
        return;
      }

      int start = currentTextBeforeCursor.lastIndexOf(RegExp(mentionPattern));

      if (start == -1) {
        start = currentTextBeforeCursor.lastIndexOf('@');
        if (start == -1) {
          start = currentTextBeforeCursor.lastIndexOf('#');
        }

        if (start == -1) {
          dismiss();
          return;
        }
      }

      String text = currentTextBeforeCursor.substring(
        start,
        extentOffset,
      );

      for (var pattern in [mentionPattern]) {
        final match = RegExp(
          pattern,
          caseSensitive: false,
        ).firstMatch(text);

        if (match != null || text.startsWith('@') || text.startsWith('#')) {
          String? textPart = match?.group(0) ?? text;

          // Remove leading space or newline if exists
          String textValue = textPart.startsWith(RegExp(r'[\n ]+'))
              ? textPart.trimLeft()
              : textPart;

          List<String> matchingList = switch (textValue) {
            (String value) when value.startsWith("@") =>
              getMatchingMentions(value),
            // (String value) when value.startsWith("#") =>
            //   getMatchingHashTags(value),
            _ => []
          };

          _handleReplaceText(
            textValue,
            matchingList,
            textPart.startsWith(RegExp(r'[\n ]+')) ? start + 1 : start,
            extentOffset,
          );
        }
      }
    }
  }

  void _handleReplaceText(
      String value, List<String> matchingListData, int start, int end) {
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      List<ReplacementInfo> result = [];

      result = matchingListData.map((element) {
        return ReplacementInfo(
          index: matchingListData.indexOf(element),
          oldString: value,
          content: element,
          start: start,
          end: end,
        );
      }).toList();

      if (result.isNotEmpty) {
        if (result.length == 1 && widget.currentNodeType == 'mention') {}
      } else {
        dismiss();
      }
    });
  }

  void _showMentionMenu() {
    dismiss();

    final selectionService = editorState.service.selectionService;

    final selectionRects = editorState.selectionRects();
    if (selectionRects.isEmpty) {
      return;
    }

    calculateSelectionMenuOffset(selectionRects.first);
    final (left, top, right, bottom) = getPosition();

    final editorHeight = editorState.renderBox!.size.height;
    final editorWidth = editorState.renderBox!.size.width;

    _selectionMenuEntry = OverlayEntry(
      builder: (context) {
        return SizedBox(
          width: editorWidth,
          height: editorHeight,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () {
              dismiss();
            },
            child: Stack(
              children: [
                Positioned(
                  top: top,
                  bottom: bottom,
                  left: left,
                  right: right,
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Container(
                      height: 100,
                      width: 200,
                      color: Colors.red,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );

    Overlay.of(context, rootOverlay: true).insert(_selectionMenuEntry!);

    editorState.service.keyboardService?.disable(showCursor: true);
    editorState.service.scrollService?.disable();
    selectionService.currentSelection.addListener(_onSelectionChange);
  }

  (double? left, double? top, double? right, double? bottom) getPosition() {
    double? left, top, right, bottom;
    switch (alignment) {
      case Alignment.topLeft:
        left = offset.dx;
        top = offset.dy;
        break;
      case Alignment.bottomLeft:
        left = offset.dx;
        bottom = offset.dy;
        break;
      case Alignment.topRight:
        right = offset.dx;
        top = offset.dy;
        break;
      case Alignment.bottomRight:
        right = offset.dx;
        bottom = offset.dy;
        break;
    }

    return (left, top, right, bottom);
  }

  void calculateSelectionMenuOffset(Rect rect) {
    // Workaround: We can customize the padding through the [EditorStyle],
    // but the coordinates of overlay are not properly converted currently.
    // Just subtract the padding here as a result.
    var menuHeight = 100.0;
    const menuOffset = Offset(0, 10);
    final editorOffset =
        editorState.renderBox?.localToGlobal(Offset.zero) ?? Offset.zero;
    final editorHeight = editorState.renderBox!.size.height;
    final editorWidth = editorState.renderBox!.size.width;

    // show below default
    _alignment = Alignment.topLeft;
    final bottomRight = rect.bottomRight;
    final topRight = rect.topRight;
    var offset = bottomRight + menuOffset;
    _offset = Offset(
      offset.dx,
      offset.dy,
    );

    // show above
    if (offset.dy + menuHeight >= editorOffset.dy + editorHeight) {
      offset = topRight - menuOffset;
      _alignment = Alignment.bottomLeft;

      _offset = Offset(
        offset.dx,
        MediaQuery.of(context).size.height - offset.dy,
      );
    }

    // show on left
    if (_offset.dx - editorOffset.dx > editorWidth / 2) {
      _alignment = _alignment == Alignment.topLeft
          ? Alignment.topRight
          : Alignment.bottomRight;

      _offset = Offset(
        editorWidth - _offset.dx + editorOffset.dx,
        _offset.dy,
      );
    }
  }

  Future<bool> _showSlashMenu(
    EditorState editorState,
    List<ReplacementInfo> items, {
    bool shouldInsertSlash = true,
    SelectionMenuStyle style = SelectionMenuStyle.light,
  }) async {
    final selection = editorState.selection;
    if (selection == null) {
      return false;
    }

    // Check if we need to insert the slash character
    if (shouldInsertSlash) {
      final currentNode = editorState.getNodeAtPath(selection.start.path);
      final currentPlainText = currentNode?.delta?.toPlainText() ?? '';

      // Avoid inserting if the "/" is already there
      if (selection.start.offset > 0 &&
          currentPlainText[selection.start.offset - 1] == '/') {
        shouldInsertSlash = false;
      } else {
        keepEditorFocusNotifier.increase();
      }
    }

    // Make sure to dismiss the previous menu if it's still open
    dismiss();

    // delete the selection
    if (!selection.isCollapsed) {
      await editorState.deleteSelection(selection);
    }

    final afterSelection = editorState.selection;
    if (afterSelection == null || !afterSelection.isCollapsed) {
      assert(false, 'the selection should be collapsed');
      return true;
    }

    final node = editorState.getNodeAtPath(selection.start.path);

    // only enable in white-list nodes
    if (node == null || !_isSupportSlashMenuNode(node)) {
      return false;
    }

    // insert the slash character
    if (shouldInsertSlash) {
      keepEditorFocusNotifier.increase();
      await editorState.insertTextAtPosition('@', position: selection.start);
    }

    // show the slash menu

    final context = editorState.getNodeAtPath(selection.start.path)?.context;
    if (context != null && context.mounted) {
      _showMentionMenu();
    }

    if (shouldInsertSlash) {
      WidgetsBinding.instance.addPostFrameCallback(
        (timeStamp) => keepEditorFocusNotifier.decrease(),
      );
    }

    return true;
  }

  bool _isSupportSlashMenuNode(Node node) {
    var result = supportSlashMenuNodeWhiteList.contains(node.type);
    if (node.level > 1 && node.parent != null) {
      return result && _isSupportSlashMenuNode(node.parent!);
    }
    return result;
  }

  Alignment get alignment {
    return _alignment;
  }

  Offset get offset {
    return _offset;
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}

class MentionOverlayWidget extends StatefulWidget {
  final EditorState editorState;
  final SelectionMenuStyle style;
  final OverlayBuilderType type;
  final List<ReplacementInfo> replacements;
  const MentionOverlayWidget({
    super.key,
    required this.editorState,
    required this.style,
    required this.replacements,
    this.type = OverlayBuilderType.mention,
  });

  @override
  State<MentionOverlayWidget> createState() => _MentionOverlayWidgetState();
}

class _MentionOverlayWidgetState extends State<MentionOverlayWidget> {
  EditorState get editorState => widget.editorState;

  ValueNotifier<int> currentSelect = ValueNotifier(0);
  final ScrollController scrollController =
      ScrollController(initialScrollOffset: 0);

  final double itemExtent = 40;

  void _onTapItemOverlay(ReplacementInfo replace) {
    currentSelect.value = replace.index;

    final selection = editorState.selection;
    if (selection == null || !selection.isCollapsed) {
      return;
    }
    final node = editorState.getNodeAtPath(selection.end.path);
    final delta = node?.delta;
    if (node == null || delta == null) {
      return;
    }
    final transaction = editorState.transaction;

    final plainText = delta.toPlainText();
    final lastWord = plainText.substring(0, selection.endIndex).split(' ').last;

    final indexOfAtSign = plainText.length - lastWord.length;

    transaction.insertText(node, indexOfAtSign, replace.content);
    editorState.apply(transaction).then((_) {
      final newSelection = selection.copyWith(
        start: selection.start.copyWith(offset: indexOfAtSign),
        end: selection.start
            .copyWith(offset: indexOfAtSign + replace.content.length),
      );
      editorState.formatDelta(
        newSelection,
        {
          'mention': true,
        },
      );
    });
  }

  Widget buildListMentionOverlay(List<ReplacementInfo> value) {
    return ValueListenableBuilder<int>(
      valueListenable: currentSelect,
      builder: (context, currentIndex, child) => ListView.builder(
        controller: scrollController,
        padding: const EdgeInsets.all(5),
        itemExtent: itemExtent,
        shrinkWrap: true,
        itemBuilder: (context, index) {
          final isSelected = currentIndex == index;

          return InkWell(
            onTap: () {
              _onTapItemOverlay(value.elementAt(index));
            },
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: isSelected
                    ? Colors.blue.withOpacity(0.2)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const CircleAvatar(
                    radius: 15,
                    child: Icon(Icons.person),
                  ),
                  Text(
                    value.elementAt(index).content,
                    style: Theme.of(context)
                        .textTheme
                        .bodyMedium
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  Icon(
                    Icons.circle,
                    size: 10,
                    color: Colors.green.shade500,
                  ),
                  Text(
                    value.elementAt(index).content,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ]
                    .expand<Widget>(
                      (element) => [
                        element,
                        const SizedBox(width: 5),
                      ],
                    )
                    .toList(),
              ),
            ),
          );
        },
        itemCount: value.length,
      ),
    );
  }

  Widget buildInformationOverlay(List<ReplacementInfo> value) {
    final mention = value.first;

    return Padding(
      padding: const EdgeInsets.all(5),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              const Icon(Icons.person, size: 36),
              Text(
                mention.content,
                style: Theme.of(context)
                    .textTheme
                    .bodyMedium
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
              const Icon(Icons.circle_outlined),
            ]
                .expand<Widget>(
                  (element) => [
                    element,
                    const SizedBox(width: 5),
                  ],
                )
                .toList(),
          ),
          const Divider(height: 10, thickness: 0.5),
          ListTile(
            leading: const Icon(Icons.timelapse),
            title: Text(
              "${DateFormat().add_jm().format(DateTime.now())} local time",
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: widget.style.selectionMenuBackgroundColor,
        boxShadow: [
          BoxShadow(
            blurRadius: 5,
            spreadRadius: 1,
            color: Colors.black.withOpacity(0.1),
          ),
        ],
        borderRadius: BorderRadius.circular(6.0),
      ),
      child: widget.type == OverlayBuilderType.mention
          ? buildListMentionOverlay(widget.replacements)
          : buildInformationOverlay(widget.replacements),
    );
  }
}
