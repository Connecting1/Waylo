import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:waylo_flutter/models/album_widget.dart';
import 'package:waylo_flutter/services/api/widget_api.dart';
import 'package:waylo_flutter/providers/widget_provider.dart';
import '../../styles/app_styles.dart';

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

    // 제목을 위한 컨트롤러 초기화
    _titleController = TextEditingController(
        text: widget.widget.extraData['title'] ?? 'Check List');
  }

  @override
  void dispose() {
    _titleController.dispose();
    _titleFocusNode.dispose();
    super.dispose();
  }

  Future<void> _saveTitle() async {
    if (_titleController.text.isEmpty) {
      _titleController.text = 'Check List';
    }

    final String newTitle = _titleController.text;
    final String currentTitle = widget.widget.extraData['title'] ?? 'Check List';

    if (newTitle != currentTitle) {
      // extraData 복사 후 title 업데이트
      Map<String, dynamic> updatedExtraData = Map.from(widget.widget.extraData);
      updatedExtraData['title'] = newTitle;

      // 서버에 업데이트 요청
      final widgetProvider =
      Provider.of<WidgetProvider>(context, listen: false);
      bool success = await widgetProvider.updateWidgetExtraData(
          widget.widget.id, updatedExtraData);

      if (!success) {
        // 실패 시 원래 제목으로 복원
        setState(() {
          _titleController.text = currentTitle;
        });

        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Failed to save title')));
      }
    }
  }

  void _toggleTitleEditMode() {
    setState(() {
      _isTitleEditMode = !_isTitleEditMode;
      if (_isTitleEditMode) {
        // 포커스 요청을 지연시켜 setState 완료 후 실행
        Future.delayed(Duration(milliseconds: 50), () {
          _titleFocusNode.requestFocus();
        });
      }
    });
  }

  Future<void> _loadItems() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // 위젯의 extraData에서 items 배열을 가져옵니다
      // 기존 위젯 모델의 extraData를 사용
      final items = widget.widget.extraData['items'] ?? [];
      setState(() {
        _items = List<Map<String, dynamic>>.from(items);
        _isLoading = false;
      });
    } catch (e) {
      print("❌ 체크리스트 항목 로드 오류: $e");
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _toggleItem(int index, bool value) async {
    try {
      // 로컬 상태 먼저 업데이트
      setState(() {
        _items[index]['checked'] = value;
      });

      // extraData에 수정된 items 배열 반영
      Map<String, dynamic> updatedExtraData = Map.from(widget.widget.extraData);
      updatedExtraData['items'] = _items;

      // 기존 updateWidget API 사용하여 extraData 업데이트
      bool success = await WidgetApi.updateWidget(
        widgetId: widget.widget.id,
        extraData: updatedExtraData,
      );

      if (!success) {
        // 실패 시 원래 상태로 복원
        setState(() {
          _items[index]['checked'] = !value;
        });
      }
    } catch (e) {
      print("❌ 체크리스트 항목 토글 오류: $e");
      // 실패 시 원래 상태로 복원
      setState(() {
        _items[index]['checked'] = !value;
      });
    }
  }

  Future<void> _addItem(String text) async {
    if (text.isEmpty) return;

    try {
      // 새 항목 생성
      final newItem = {
        'id': DateTime.now().millisecondsSinceEpoch.toString(), // 간단한 고유 ID
        'text': text,
        'checked': false
      };

      // 로컬 상태에 항목 추가
      setState(() {
        _items.add(newItem);
      });

      // extraData 업데이트
      Map<String, dynamic> updatedExtraData = Map.from(widget.widget.extraData);
      updatedExtraData['items'] = _items;

      // 기존 updateWidget API 사용
      bool success = await WidgetApi.updateWidget(
        widgetId: widget.widget.id,
        extraData: updatedExtraData,
      );

      if (!success) {
        // 실패 시 마지막 항목 제거
        setState(() {
          _items.removeLast();
        });
      }
    } catch (e) {
      print("❌ 체크리스트 항목 추가 오류: $e");
      // 실패 시 마지막 항목 제거
      setState(() {
        _items.removeLast();
      });
    }
  }

  Future<void> _removeItem(int index) async {
    try {
      // 삭제할 항목 저장
      final removedItem = _items[index];

      // 로컬 상태 업데이트
      setState(() {
        _items.removeAt(index);
      });

      // extraData 업데이트
      Map<String, dynamic> updatedExtraData = Map.from(widget.widget.extraData);
      updatedExtraData['items'] = _items;

      // 기존 updateWidget API 사용
      bool success = await WidgetApi.updateWidget(
        widgetId: widget.widget.id,
        extraData: updatedExtraData,
      );

      if (!success) {
        // 실패 시 삭제된 항목 복원
        setState(() {
          _items.insert(index, Map<String, dynamic>.from(removedItem));
        });
      }
    } catch (e) {
      print("❌ 체크리스트 항목 삭제 오류: $e");
    }
  }

  Future<void> _updateItemText(int index, String newText) async {
    if (newText.isEmpty) return;

    try {
      // 기존 텍스트 저장
      final oldText = _items[index]['text'];

      // 로컬 상태 업데이트
      setState(() {
        _items[index]['text'] = newText;
      });

      // extraData 업데이트
      Map<String, dynamic> updatedExtraData = Map.from(widget.widget.extraData);
      updatedExtraData['items'] = _items;

      // 기존 updateWidget API 사용
      bool success = await WidgetApi.updateWidget(
        widgetId: widget.widget.id,
        extraData: updatedExtraData,
      );

      if (!success) {
        // 실패 시 원래 텍스트로 복원
        setState(() {
          _items[index]['text'] = oldText;
        });
      }
    } catch (e) {
      print("❌ 체크리스트 항목 텍스트 업데이트 오류: $e");
    }
  }

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

  void _toggleEditMode() {
    setState(() {
      _isEditMode = !_isEditMode;
    });

    // 편집 모드가 종료될 때 제목 저장
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
          // 헤더 부분
          Row(
            children: [
              Icon(Icons.checklist, color: AppColors.primary,),
              SizedBox(width: 8),
              // 제목 부분 - 편집 모드에 따라 다르게 표시
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

              // 편집 모드 토글 버튼
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
              // 항목 추가 버튼
              IconButton(
                icon: Icon(Icons.add, color: AppColors.primary, size: 20),
                onPressed: _showAddItemDialog,
                padding: EdgeInsets.all(4),
                constraints: BoxConstraints(),
              ),
            ],
          ),
          Divider(),
          // 항목 목록
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
