import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/canvas_provider.dart';
import '../../providers/feed_map_provider.dart';
import '../../providers/sign_up_provider.dart';
import '../../providers/user_provider.dart';
import '../../providers/widget_provider.dart';
import '../auth/sign_up_start.dart';

class SharedMapScreenPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('채팅 페이지'),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () async {
                // 모든 Provider 초기화
                Provider.of<SignUpProvider>(context, listen: false).logout(); // 기존 로그아웃 함수
                Provider.of<FeedMapProvider>(context, listen: false).reset(); // FeedMapProvider 초기화 추가
                Provider.of<CanvasProvider>(context, listen: false).reset(); // 기타 Provider도 초기화
                Provider.of<UserProvider>(context, listen: false).reset();
                Provider.of<WidgetProvider>(context, listen: false).reset();

                // 로그인 화면으로 이동
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (context) => SignUpStartPage()),
                      (route) => false,
                );
              },
              child: Text('로그아웃'),
            ),
          ],
        ),
      ),
    );
  }
}