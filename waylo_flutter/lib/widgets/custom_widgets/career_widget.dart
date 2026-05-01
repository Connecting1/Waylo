import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:waylo_flutter/models/album_widget.dart';
import 'package:waylo_flutter/providers/widget_provider.dart';
import '../../../styles/app_styles.dart';

class CareerWidget extends StatefulWidget {
  final AlbumWidget widget;

  const CareerWidget({Key? key, required this.widget}) : super(key: key);

  @override
  _CareerWidgetState createState() => _CareerWidgetState();
}

class _CareerWidgetState extends State<CareerWidget> {
  List<Map<String, dynamic>> _entries = [];

  @override
  void initState() {
    super.initState();
    _loadEntries();
  }

  void _loadEntries() {
    final raw = widget.widget.extraData['entries'];
    if (raw is List) {
      _entries = List<Map<String, dynamic>>.from(
        raw.map((e) => Map<String, dynamic>.from(e)),
      );
    }
  }

  Future<void> _saveEntries() async {
    final widgetProvider = Provider.of<WidgetProvider>(context, listen: false);
    final updated = Map<String, dynamic>.from(widget.widget.extraData);
    updated['entries'] = _entries;
    await widgetProvider.updateWidgetExtraData(widget.widget.id, updated);
  }

  void _showEntryDialog({int? editIndex}) {
    final existing = editIndex != null ? Map<String, dynamic>.from(_entries[editIndex]) : null;
    final categoryCtrl = TextEditingController(text: existing?['category'] ?? '');
    final activityCtrl = TextEditingController(text: existing?['activity'] ?? '');
    final periodCtrl = TextEditingController(text: existing?['period'] ?? '');
    final locationCtrl = TextEditingController(text: existing?['location'] ?? '');

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(editIndex != null ? '경력 수정' : '경력 추가'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildField('구분', categoryCtrl,
                    hint: '예) 현장실습, 봉사활동, 어학연수'),
                const SizedBox(height: 12),
                _buildField('활동내용', activityCtrl,
                    hint: '활동 내용을 입력하세요', maxLines: 3),
                const SizedBox(height: 12),
                _buildField('기간', periodCtrl,
                    hint: '예) 2023.03~2023.08'),
                const SizedBox(height: 12),
                _buildField('소재지', locationCtrl,
                    hint: '예) 서울, 부산'),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('취소'),
            ),
            TextButton(
              onPressed: () {
                final entry = {
                  'category': categoryCtrl.text.trim(),
                  'activity': activityCtrl.text.trim(),
                  'period': periodCtrl.text.trim(),
                  'location': locationCtrl.text.trim(),
                };
                setState(() {
                  if (editIndex != null) {
                    _entries[editIndex] = entry;
                  } else {
                    _entries.add(entry);
                  }
                });
                _saveEntries();
                Navigator.pop(context);
              },
              child: const Text('저장'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildField(String label, TextEditingController ctrl,
      {String hint = '', int maxLines = 1}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Colors.black87)),
        const SizedBox(height: 4),
        TextField(
          controller: ctrl,
          maxLines: maxLines,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(fontSize: 12, color: Colors.grey),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: AppColors.primary, width: 2),
            ),
          ),
          style: const TextStyle(fontSize: 13),
        ),
      ],
    );
  }

  Future<void> _deleteEntry(int index) async {
    setState(() {
      _entries.removeAt(index);
    });
    await _saveEntries();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: widget.widget.width,
      height: widget.widget.height,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [
          BoxShadow(color: Colors.black26, offset: Offset(2, 2), blurRadius: 4),
        ],
      ),
      child: Column(
        children: [
          _buildHeader(),
          Expanded(child: _buildTable()),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.1),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(12),
          topRight: Radius.circular(12),
        ),
      ),
      child: Row(
        children: [
          Icon(Icons.work_outline, color: AppColors.primary, size: 18),
          const SizedBox(width: 8),
          const Expanded(
            child: Text(
              '경력 및 활동',
              style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87),
            ),
          ),
          GestureDetector(
            onTap: () => _showEntryDialog(),
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Icon(Icons.add, color: Colors.white, size: 16),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTable() {
    if (_entries.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.edit_note, color: Colors.grey[400], size: 32),
            const SizedBox(height: 8),
            Text(
              '+ 버튼을 눌러 경력을 추가하세요',
              style: TextStyle(color: Colors.grey[500], fontSize: 12),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        _buildTableHeader(),
        Expanded(
          child: ListView.separated(
            itemCount: _entries.length,
            separatorBuilder: (_, __) =>
                const Divider(height: 1, color: Color(0xFFE0E0E0)),
            itemBuilder: (context, index) => _buildTableRow(index),
          ),
        ),
      ],
    );
  }

  Widget _buildTableHeader() {
    return Container(
      color: const Color(0xFFF5F5F5),
      child: Row(
        children: [
          _headerCell('구분', flex: 2),
          _headerCell('활동내용', flex: 3),
          _headerCell('기간', flex: 3),
          _headerCell('소재지', flex: 2),
          const SizedBox(width: 32),
        ],
      ),
    );
  }

  Widget _headerCell(String text, {int flex = 1}) {
    return Expanded(
      flex: flex,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
        child: Text(
          text,
          style: const TextStyle(
              fontSize: 11, fontWeight: FontWeight.bold, color: Colors.black54),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  Widget _buildTableRow(int index) {
    final e = _entries[index];
    return GestureDetector(
      onTap: () => _showEntryDialog(editIndex: index),
      child: Container(
        color: index.isEven ? Colors.white : const Color(0xFFFAFAFA),
        child: Row(
          children: [
            _dataCell(e['category'] ?? '', flex: 2),
            _dataCell(e['activity'] ?? '', flex: 3),
            _dataCell(e['period'] ?? '', flex: 3),
            _dataCell(e['location'] ?? '', flex: 2),
            GestureDetector(
              onTap: () => _deleteEntry(index),
              child: const SizedBox(
                width: 32,
                child: Icon(Icons.close, size: 14, color: Colors.redAccent),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _dataCell(String text, {int flex = 1}) {
    return Expanded(
      flex: flex,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
        child: Text(
          text.isEmpty ? '-' : text,
          style: TextStyle(
              fontSize: 11,
              color: text.isEmpty ? Colors.grey[400] : Colors.black87),
          textAlign: TextAlign.center,
          overflow: TextOverflow.ellipsis,
          maxLines: 2,
        ),
      ),
    );
  }
}
