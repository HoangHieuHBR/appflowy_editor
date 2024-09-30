import 'dart:io';

import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:flutter/foundation.dart';
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

    final currentPlainText = currentNode!.delta!.toPlainText();

    final lastWord =
        currentPlainText.substring(0, position.offset).split(' ').last;

    print('lastWord: $lastWord');
    if (lastWord.startsWith("/") && lastWord.length == 1) {
      _isUpdatingSelection = true;
      print('showMenu');
      await _showSlashMenu(
        editorState,
        standardSelectionMenuItems,
      );

      _isUpdatingSelection = false;
    }
  }

  SelectionMenuService? _selectionMenuService;
  Future<bool> _showSlashMenu(
    EditorState editorState,
    List<SelectionMenuItem> items, {
    bool shouldInsertSlash = true,
    bool singleColumn = true,
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
    _selectionMenuService?.dismiss();

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
      await editorState.insertTextAtPosition('/', position: selection.start);
    }

    // show the slash menu

    final context = editorState.getNodeAtPath(selection.start.path)?.context;
    if (context != null && context.mounted) {
      _selectionMenuService = SelectionMenu(
        context: context,
        editorState: editorState,
        selectionMenuItems: items,
        deleteSlashByDefault: shouldInsertSlash,
        singleColumn: singleColumn,
        style: style,
      );
      if (!kIsWeb && Platform.environment.containsKey('FLUTTER_TEST')) {
        _selectionMenuService?.show();
      } else {
        await _selectionMenuService?.show();
      }
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

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }

  SelectionMenuStyle get style => SelectionMenuStyle.light;
}

  // OverlayEntry? _selectionMenuEntry;

  // bool _selectionUpdateByInner = false;
  // Offset _offset = Offset.zero;
  // Alignment _alignment = Alignment.topLeft;

//  void dismiss() {
//     if (_selectionMenuEntry != null) {
//       editorState.service.keyboardService?.enable();
//       editorState.service.scrollService?.enable();
//     }

//     _selectionMenuEntry?.remove();
//     _selectionMenuEntry = null;

//     // workaround: SelectionService has been released after hot reload.
//     final isSelectionDisposed =
//         editorState.service.selectionServiceKey.currentState == null;
//     if (!isSelectionDisposed) {
//       final selectionService = editorState.service.selectionService;
//       // focus to reload the selection after the menu dismissed.
//       editorState.selection = editorState.selection;
//       selectionService.currentSelection.removeListener(_onSelectionChange);
//     }
//   }

//   Alignment get alignment {
//     return _alignment;
//   }

//   Offset get offset {
//     return _offset;
//   }

//   void _onSelectionChange() {
//     // workaround: SelectionService has been released after hot reload.
//     final isSelectionDisposed =
//         editorState.service.selectionServiceKey.currentState == null;
//     if (!isSelectionDisposed) {
//       final selectionService = editorState.service.selectionService;
//       if (selectionService.currentSelection.value == null) {
//         return;
//       }
//     }

//     if (_selectionUpdateByInner) {
//       _selectionUpdateByInner = false;
//       return;
//     }

//     dismiss();
//   }


  // void _showMentionMenu() {
  //   dismiss();

  //   final selectionService = editorState.service.selectionService;

  //   final selectionRects = editorState.selectionRects();
  //   if (selectionRects.isEmpty) {
  //     return;
  //   }

  //   calculateSelectionMenuOffset(selectionRects.first);
  //   final (left, top, right, bottom) = getPosition();

  //   final editorHeight = editorState.renderBox!.size.height;
  //   final editorWidth = editorState.renderBox!.size.width;

  //   _selectionMenuEntry = OverlayEntry(
  //     builder: (context) {
  //       return SizedBox(
  //         width: editorWidth,
  //         height: editorHeight,
  //         child: GestureDetector(
  //           behavior: HitTestBehavior.opaque,
  //           onTap: () {
  //             dismiss();
  //           },
  //           child: Stack(
  //             children: [
  //               Positioned(
  //                 top: top,
  //                 bottom: bottom,
  //                 left: left,
  //                 right: right,
  //                 child: SingleChildScrollView(
  //                   scrollDirection: Axis.horizontal,
  //                   child: SizedBox.shrink(),
  //                   // SelectionMenuWidget(
  //                   //   selectionMenuStyle: style,
  //                   //   singleColumn: true,
  //                   //   items: standardSelectionMenuItems
  //                   //     ..forEach((element) {
  //                   //       element.deleteSlash = true;
  //                   //       element.onSelected = () {
  //                   //         dismiss();
  //                   //       };
  //                   //     }),
  //                   //   maxItemInRow: 5,
  //                   //   editorState: editorState,
  //                   //   itemCountFilter: 0,
  //                   //   menuService: SelectionMenu(
  //                   //     context: context,
  //                   //     editorState: editorState,
  //                   //     selectionMenuItems: standardSelectionMenuItems,
  //                   //   ),
  //                   //   onExit: () {
  //                   //     dismiss();
  //                   //   },
  //                   //   onSelectionUpdate: () {
  //                   //     _selectionUpdateByInner = true;
  //                   //   },
  //                   //   deleteSlashByDefault: true,
  //                   // )
  //                 ),
  //               ),
  //             ],
  //           ),
  //         ),
  //       );
  //     },
  //   );

  //   Overlay.of(context, rootOverlay: true).insert(_selectionMenuEntry!);

  //   editorState.service.keyboardService?.disable(showCursor: true);
  //   editorState.service.scrollService?.disable();
  //   selectionService.currentSelection.addListener(_onSelectionChange);
  // }

  // (double? left, double? top, double? right, double? bottom) getPosition() {
  //   double? left, top, right, bottom;
  //   switch (alignment) {
  //     case Alignment.topLeft:
  //       left = offset.dx;
  //       top = offset.dy;
  //       break;
  //     case Alignment.bottomLeft:
  //       left = offset.dx;
  //       bottom = offset.dy;
  //       break;
  //     case Alignment.topRight:
  //       right = offset.dx;
  //       top = offset.dy;
  //       break;
  //     case Alignment.bottomRight:
  //       right = offset.dx;
  //       bottom = offset.dy;
  //       break;
  //   }

  //   return (left, top, right, bottom);
  // }

  // void calculateSelectionMenuOffset(Rect rect) {
  //   // Workaround: We can customize the padding through the [EditorStyle],
  //   // but the coordinates of overlay are not properly converted currently.
  //   // Just subtract the padding here as a result.
  //   var menuHeight = 100.0;
  //   const menuOffset = Offset(0, 10);
  //   final editorOffset =
  //       editorState.renderBox?.localToGlobal(Offset.zero) ?? Offset.zero;
  //   final editorHeight = editorState.renderBox!.size.height;
  //   final editorWidth = editorState.renderBox!.size.width;

  //   // show below default
  //   _alignment = Alignment.topLeft;
  //   final bottomRight = rect.bottomRight;
  //   final topRight = rect.topRight;
  //   var offset = bottomRight + menuOffset;
  //   _offset = Offset(
  //     offset.dx,
  //     offset.dy,
  //   );

  //   // show above
  //   if (offset.dy + menuHeight >= editorOffset.dy + editorHeight) {
  //     offset = topRight - menuOffset;
  //     _alignment = Alignment.bottomLeft;

  //     _offset = Offset(
  //       offset.dx,
  //       MediaQuery.of(context).size.height - offset.dy,
  //     );
  //   }

  //   // show on left
  //   if (_offset.dx - editorOffset.dx > editorWidth / 2) {
  //     _alignment = _alignment == Alignment.topLeft
  //         ? Alignment.topRight
  //         : Alignment.bottomRight;

  //     _offset = Offset(
  //       editorWidth - _offset.dx + editorOffset.dx,
  //       _offset.dy,
  //     );
  //   }
  // }
