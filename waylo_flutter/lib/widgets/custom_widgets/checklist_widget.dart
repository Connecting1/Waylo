import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:waylo_flutter/models/album_widget.dart';
import 'package:waylo_flutter/services/api/widget_api.dart';
import 'package:waylo_flutter/providers/widget_provider.dart';
import '../../../styles/app_styles.dart';

/// 체크리스트 기능을 제공하는 위젯
class ChecklistWidget extends StatefulWidget {
  final AlbumWidget widget;

  const ChecklistWidget({Key? key, required this.widget}) : super(key: key);

  @override
  _ChecklistWidgetState createState() => _ChecklistWidgetState();
}

class _ChecklistWidgetState extends State<ChecklistWidget> {
  List<Map<String, dynamic>> _items = [];
  bool _isLoading = true;
  bool _isEditMode = false;
  bool _isTitleEditMode = false;
  late TextEditingController _titleController;
  final FocusNode _titleFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _loadItems();

    _titleController = TextEditingController(
        text: widget.widget.extraData['title'] ?? 'Check List');
  }

  @override
  void dispose() {
    _titleController.dispose();
    _titleFocusNode.dispose();
    super.dispose();
  }

  /// 제목 저장
  Future<void> _saveTitle() async {
    if (_titleController.text.isEmpty) {
      _titleController.text = 'Check List';
    }

    final String newTitle = _titleController.text;
    final String currentTitle = widget.widget.extraData['title'] ?? 'Check List';

    if (newTitle != currentTitle) {
      Map<String, dynamic> updatedExtraData = Map.from(widget.widget.extraData);
      updatedExtraData['title'] = newTitle;

      final widgetProvider =
      Provider.of<WidgetProvider>(context, listen: false);
      bool success = await widgetProvider.updateWidgetExtraData(
          widget.widget.id, updatedExtraData);

      if (!success) {
        setState(() {
          _titleController.text = currentTitle;
        });

        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Failed to save title')));
      }
    }
  }

  /// 제목 편집 모드 토글
  void _toggleTitleEditMode() {
    setState(() {
      _isTitleEditMode = !_isTitleEditMode;
      if (_isTitleEditMode) {
        Future.delayed(Duration(milliseconds: 50), () {
          _titleFocusNode.requestFocus();
        });
      }
    });
  }

  /// 체크리스트 항목 로드
  Future<void> _loadItems() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final items = widget.widget.extraData['items'] ?? [];
      setState(() {
        _items = List<Map<String, dynamic>>.from(items);
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  /// 체크리스트 항목 체크 상태 토글
  Future<void> _toggleItem(int index, bool value) async {
    try {
      setState(() {
        _items[index]['checked'] = value;
      });

      Map<String, dynamic> updatedExtraData = Map.from(widget.widget.extraData);
      updatedExtraData['items'] = _items;

      bool success = await WidgetApi.updateWidget(
        widgetId: widget.widget.id,
        extraData: updatedExtraData,
      );

      if (!success) {
        setState(() {
          _items[index]['checked'] = !value;
        });
      }
    } catch (e) {
      setState(() {
        _items[index]['checked'] = !value;
      });
    }
  }

  /// 새 항목 추가
  Future<void> _addItem(String text) async {
    if (text.isEmpty) return;

    try {
      final newItem = {
        'id': DateTime.now().millisecondsSinceEpoch.toString(),
        'text': text,
        'checked': false
      };

      setState(() {
        _items.add(newItem);
      });

      Map<String, dynamic> updatedExtraData = Map.from(widget.widget.extraData);
      updatedExtraData['items'] = _items;

      bool success = await WidgetApi.updateWidget(
        widgetId: widget.widget.id,
        extraData: updatedExtraData,
      );

      if (!success) {
        setState(() {
          _items.removeLast();
        });
      }
    } catch (e) {
      setState(() {
        _items.removeLast();
      });
    }
  }

  /// 항목 삭제
  Future<void> _removeItem(int index) async {
    try {
      final removedItem = _items[index];

      setState(() {
        _items.removeAt(index);
      });

      Map<String, dynamic> updatedExtraData = Map.from(widget.widget.extraData);
      updatedExtraData['items'] = _items;

      bool success = await WidgetApi.updateWidget(
        widgetId: widget.widget.id,
        extraData: updatedExtraData,
      );

      if (!success) {
        setState(() {
          _items.insert(index, Map<String, dynamic>.from(removedItem));
        });
      }
    } catch (e) {
      // 에러 처리
    }
  }

  /// 항목 텍스트 업데이트
  Future<void> _updateItemText(int index, String newText) async {
    if (newText.isEmpty) return;

    try {
      final oldText = _items[index]['text'];

      setState(() {
        _items[index]['text'] = newText;
      });

      Map<String, dynamic> updatedExtraData = Map.from(widget.widget.extraData);
      updatedExtraData['items'] = _items;

      bool success = await WidgetApi.updateWidget(
        widgetId: widget.widget.id,
        extraData: updatedExtraData,
      );

      if (!success) {
        setState(() {
          _items[index]['text'] = oldText;
        });
      }
    } catch (e) {
      // 에러 처리
    }
  }

  /// 항목 추가 다이얼로그 표시
  void _showAddItemDialog() {
    final TextEditingController controller = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Add Item'),
        content: TextField(
          controller: controller,
          decoration: InputDecoration(hintText: 'Add Item'),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              _addItem(controller.text);
              Navigator.pop(context);
            },
            child: Text('Add'),
          ),
        ],
      ),
    );
  }

  /// 편집 모드 토글
  void _toggleEditMode() {
    setState(() {
      _isEditMode = !_isEditMode;
    });

    if (!_isEditMode) {
      _saveTitle();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Container(
        width: widget.widget.width,
        height: widget.widget.height,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black26,
              offset: Offset(2, 2),
              blurRadius: 4,
            ),
          ],
        ),
        child: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Container(
      width: widget.widget.width,
      height: widget.widget.height,
      padding: EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black26,
            offset: Offset(2, 2),
            blurRadius: 4,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.checklist, color: AppColors.primary,),
              SizedBox(width: 8),
              Expanded(
                flex: 3,
                child: _isEditMode
                    ? TextField(
                  controller: _titleController,
                  focusNode: _titleFocusNode,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                  decoration: InputDecoration(
                    isDense: true,
                    contentPadding: EdgeInsets.symmetric(vertical: 8),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                )
                    : Text(
                  widget.widget.extraData['title'] ?? 'Check List',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),

              IconButton(
                icon: Icon(
                  _isEditMode ? Icons.done : Icons.edit,
                  color: AppColors.primary,
                  size: 20,
                ),
                onPressed: _toggleEditMode,
                padding: EdgeInsets.all(4),
                constraints: BoxConstraints(),
              ),
              IconButton(
                icon: Icon(Icons.add, color: AppColors.primary, size: 20),
                onPressed: _showAddItemDialog,
                padding: EdgeInsets.all(4),
                constraints: BoxConstraints(),
              ),
            ],
          ),
          Divider(),
          Expanded(
            child: _items.isEmpty
                ? Center(
              child: Text(
                'No items.\nPress the + button to add an item.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey),
              ),
            )
                : ListView.builder(
              itemCount: _items.length,
              itemBuilder: (context, index) {
                final item = _items[index];
                return _isEditMode
                    ? _buildEditableItem(item, index)
                    : _buildCheckableItem(item, index);
              },
            ),
          ),
        ],
      ),
    );
  }

  /// 편집 가능한 항목 위젯 구성
  Widget _buildEditableItem(Map<String, dynamic> item, int index) {
    final TextEditingController controller =
    TextEditingController(text: item['text']);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              decoration: InputDecoration(
                isDense: true,
                contentPadding: EdgeInsets.symmetric(vertical: 8),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              onSubmitted: (value) => _updateItemText(index, value),
            ),
          ),
          IconButton(
            icon: Icon(Icons.delete, color: Colors.red, size: 20),
            onPressed: () => _removeItem(index),
            padding: EdgeInsets.all(4),
            constraints: BoxConstraints(),
          ),
        ],
      ),
    );
  }

  /// 체크 가능한 항목 위젯 구성
  Widget _buildCheckableItem(Map<String, dynamic> item, int index) {
    return CheckboxListTile(
      controlAffinity: ListTileControlAffinity.leading,
      title: Text(
        item['text'] ?? '',
        style: TextStyle(
          decoration: item['checked'] == true
              ? TextDecoration.lineThrough
              : TextDecoration.none,
          color: item['checked'] == true ? Colors.grey : Colors.black,
        ),
      ),
      value: item['checked'] ?? false,
      onChanged: (value) {
        if (value != null) {
          _toggleItem(index, value);
        }
      },
      dense: true,
      contentPadding: EdgeInsets.zero,
    );
  }
}