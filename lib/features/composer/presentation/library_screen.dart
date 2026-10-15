import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/widgets/feature_scaffold.dart';
import '../../chat/domain/entities/chat_attachment.dart';
import 'composer_providers.dart';

class LibraryScreen extends ConsumerStatefulWidget {
  const LibraryScreen({super.key});
  @override
  ConsumerState<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends ConsumerState<LibraryScreen> {
  String _query = '';
  bool _imagesOnly = false;
  final _selected = <String>{};
  @override
  Widget build(BuildContext context) {
    final files = ref
        .read(attachmentLibraryProvider)
        .load()
        .where(
          (file) =>
              file.name.toLowerCase().contains(_query.toLowerCase()) &&
              (!_imagesOnly || file.isImage),
        )
        .toList();
    return FeatureScaffold(
      title: 'Library',
      action: IconButton(
        tooltip: 'Filter files',
        onPressed: () => setState(() => _imagesOnly = !_imagesOnly),
        icon: Icon(
          Icons.filter_list_rounded,
          color: _imagesOnly ? Colors.blue : null,
        ),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
            child: FeatureSearchField(
              hint: 'Search files',
              onChanged: (value) => setState(() => _query = value),
            ),
          ),
          if (_imagesOnly)
            const Padding(
              padding: EdgeInsets.only(bottom: 12),
              child: Text('Images', style: TextStyle(color: Colors.grey)),
            ),
          Expanded(
            child: files.isEmpty
                ? Center(
                    child: Text(
                      _query.isEmpty ? 'No files yet' : 'No matching files',
                      style: const TextStyle(fontSize: 16, color: Colors.grey),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: files.length,
                    itemBuilder: (context, index) {
                      final file = files[index];
                      return Card(
                        color: Colors.white,
                        elevation: 0,
                        child: CheckboxListTile(
                          value: _selected.contains(file.id),
                          onChanged: (selected) => setState(() {
                            if (selected == true && _selected.length < 4) {
                              _selected.add(file.id);
                            } else {
                              _selected.remove(file.id);
                            }
                          }),
                          secondary: file.isImage
                              ? ClipRRect(
                                  borderRadius: BorderRadius.circular(6),
                                  child: Image.memory(
                                    file.bytes,
                                    width: 40,
                                    height: 40,
                                    fit: BoxFit.cover,
                                  ),
                                )
                              : const Icon(Icons.description_outlined),
                          title: Text(
                            file.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          subtitle: Text(file.readableSize),
                        ),
                      );
                    },
                  ),
          ),
          if (_selected.isNotEmpty)
            Padding(
              padding: const EdgeInsets.all(16),
              child: FilledButton(
                onPressed: () => context.pop<List<ChatAttachment>>(
                  files.where((file) => _selected.contains(file.id)).toList(),
                ),
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(48),
                ),
                child: Text('Add ${_selected.length} to chat'),
              ),
            ),
        ],
      ),
    );
  }
}
