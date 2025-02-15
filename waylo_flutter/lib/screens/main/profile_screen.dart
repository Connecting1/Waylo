import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/sign_up_provider.dart';
import '../auth/sign_up_start.dart';

class ProfileScreenPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('사용자 페이지'),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                Provider.of<SignUpProvider>(context, listen: false).logout(); // ✅ 로그아웃 기능 호출
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (context) => SignUpStartPage()), // ✅ 로그인 화면으로 이동
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
