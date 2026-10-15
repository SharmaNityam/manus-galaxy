import 'package:flutter/material.dart';
import '../../../../core/widgets/app_icon.dart';

enum AddToChatAction {
  camera,
  picture,
  file,
  library,
  creations,
  recentTasks,
  skills,
}

Future<AddToChatAction?> showAddToChatSheet(
  BuildContext context,
) => showModalBottomSheet<AddToChatAction>(
  context: context,
  isScrollControlled: true,
  backgroundColor: Colors.white,
  barrierColor: Colors.black54,
  shape: const RoundedRectangleBorder(
    borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
  ),
  builder: (context) => SizedBox(
    height: MediaQuery.sizeOf(context).height * .5,
    child: Column(
      children: [
        const SizedBox(height: 5),
        Container(
          width: 36,
          height: 5,
          decoration: BoxDecoration(
            color: const Color(0xFFDDDDDD),
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        SizedBox(
          height: 48,
          child: Stack(
            alignment: Alignment.center,
            children: [
              const Text(
                'Add to chat',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
              ),
              Align(
                alignment: Alignment.centerLeft,
                child: Padding(
                  padding: const EdgeInsets.only(left: 8),
                  child: IconButton(
                    tooltip: 'Close',
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(
                      Icons.close_rounded,
                      color: Color(0xFF8B8B87),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 6, 16, 16),
            children: [
              Row(
                children: [
                  for (final item in [
                    (AddToChatAction.camera, 'camera', 'Camera'),
                    (AddToChatAction.picture, 'image', 'Picture'),
                    (AddToChatAction.file, 'paperclip', 'File'),
                  ]) ...[
                    if (item.$1 != AddToChatAction.camera)
                      const SizedBox(width: 12),
                    Expanded(
                      child: Material(
                        color: const Color(0xFFF7F7F7),
                        borderRadius: BorderRadius.circular(18),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(18),
                          onTap: () => Navigator.of(context).pop(item.$1),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 17),
                            child: Column(
                              children: [
                                AppIcon(item.$2, size: 26),
                                const SizedBox(height: 8),
                                Text(
                                  item.$3,
                                  style: const TextStyle(fontSize: 16),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 19),
              for (final item in [
                (AddToChatAction.library, 'library-big', 'Library'),
                (AddToChatAction.creations, 'workflow', 'Creations'),
                (AddToChatAction.recentTasks, 'list-todo', 'Recent tasks'),
                (AddToChatAction.skills, 'puzzle', 'Skills'),
              ])
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  minTileHeight: 52,
                  horizontalTitleGap: 10,
                  leading: AppIcon(item.$2, size: 24),
                  title: Text(item.$3, style: const TextStyle(fontSize: 16)),
                  onTap: () => Navigator.of(context).pop(item.$1),
                ),
            ],
          ),
        ),
      ],
    ),
  ),
);
