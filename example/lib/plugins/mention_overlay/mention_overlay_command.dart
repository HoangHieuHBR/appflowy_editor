import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:example/plugins/mention_overlay/mention_overlay_menu.dart';
import 'package:example/plugins/mention_overlay/mention_overlay_result.dart';
import 'package:example/plugins/mention_overlay/mention_overlay_service.dart';

const mentionStartCharacter = '@';

CharacterShortcutEvent mentionOverlayCommand(
  MentionOverlayService mentionOverlayService, {
  MentionOverlayMenuStyle style = const MentionOverlayMenuStyle.light(),
}) =>
    CharacterShortcutEvent(
      key: 'Opens Mention Overlay',
      character: mentionStartCharacter,
      handler: (editorState) => mentionOverlayCommandHandler(
        editorState,
        mentionOverlayService,
        style,
      ),
    );

MentionOverlayMenuService? selectionMenuService;
Future<bool> mentionOverlayCommandHandler(
  EditorState editorState,
  MentionOverlayService service,
  MentionOverlayMenuStyle style,
) async {
  final selection = editorState.selection;

  if (!selection!.isCollapsed) {
    await editorState.deleteSelection(selection);
  }

  await editorState.insertTextAtPosition(
    mentionStartCharacter,
    position: selection.start,
  );

  final List<MentionOverlayResult> initialResults = [];
  for (final handler in service.handlers) {
    final group = await handler.search(null);

    if (group.results.isNotEmpty) {
      initialResults.add(group);
    }
  }

  if (service.context != null) {
    selectionMenuService = MentionOverLayMenu(
      context: service.context!,
      editorState: editorState,
      service: service,
      initialResults: initialResults,
      style: style,
    );

    selectionMenuService?.show();
  }

  return true;
}
