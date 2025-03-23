import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../styles/app_styles.dart';
import 'package:waylo_flutter/providers/user_provider.dart';
import 'package:waylo_flutter/services/data_loading_manager.dart';
import 'package:waylo_flutter/widgets/album_content.dart'; // AlbumContentWidget import

class AlbumScreenPage extends StatefulWidget {
  const AlbumScreenPage({Key? key}) : super(key: key);

  @override
  _AlbumScreenPageState createState() => _AlbumScreenPageState();
}

class _AlbumScreenPageState extends State<AlbumScreenPage> {
  bool _isLoading = false;
  final GlobalKey<AlbumContentWidgetState> _contentWidgetKey = GlobalKey<AlbumContentWidgetState>();

  @override
  void initState() {
    super.initState();
    print("🔍 AlbumScreenPage initState 호출");

    // 필요한 경우에만 데이터 로드
    _checkAndLoadData();
  }

  // 데이터가 로드되었는지 확인하고 필요한 경우에만 로드
  Future<void> _checkAndLoadData() async {
    // 이미 초기화되었다면 아무것도 하지 않음
    if (DataLoadingManager.isInitialized()) {
      print("✅ AlbumScreenPage: 데이터가 이미 로드되어 있습니다");
      return;
    }

    // 아직 초기화되지 않았다면 로딩 표시 후 데이터 로드
    setState(() {
      _isLoading = true;
    });

    try {
      await DataLoadingManager.initializeAppData(context);
    } catch (e) {
      print("❌ AlbumScreenPage: 데이터 로드 중 오류 발생: $e");

      // 오류 메시지 표시
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("데이터를 불러오는 중 오류가 발생했습니다."))
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    print("🔍 AlbumScreenPage build 호출");

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: AppColors.primary,
        title: Consumer<UserProvider>(
          builder: (context, userProvider, _) => Text(
            "${userProvider.username}'s album",
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white),
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.add, color: Colors.white,),
            onPressed: () {
              if (_contentWidgetKey.currentState != null) {
                _contentWidgetKey.currentState!.openWidgetSelection();
              }
            },
          ),
        ],
        centerTitle: true,
      ),
      body: AlbumContentWidget(key: _contentWidgetKey),
    );
  }
}