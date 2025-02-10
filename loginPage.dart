import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:first_page_test/styles/app_styles.dart';
import 'getEmailPage.dart';
import 'getBirthDatePage.dart';
import 'loginPage2.dart';


class LoginPage extends StatefulWidget {
  const LoginPage({Key? key}) : super(key: key);

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: ['email'],
  );

  GoogleSignInAccount? _currentUser;

  Future<void> _handleSignIn(BuildContext context) async {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const GetEmailPage()),
    );
  }

  Future<void> _handleLogIn(BuildContext context) async {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const LoginPage2()),
    );
  }

  Future<void> _handleGoogleSignIn() async {
    try {
      final user = await _googleSignIn.signIn();
      setState(() {
        _currentUser = user;
      });
      if (_currentUser != null) {
        print('Logged in as: ${_currentUser?.displayName}');
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const GetBirthDatePage()),
        );
      }
    } catch (error) {
      print('Sign-In Error: $error');
    }
  }

  Future<void> _handleSignOut() async {
    await _googleSignIn.signOut();
    setState(() {
      _currentUser = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF97DCF1), // 배경색
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // 로고 이미지
            Image.asset(
              'assets/logo2.png',
              width: 250,
              height: 250,
            ),

            Text(
              'enjoy your trip\nand write it down',
              style: TextStyle(
                fontSize: 35, // 글자 크기
                fontWeight: FontWeight.bold, // 글자 굵기
                color: Colors.white, // 글자 색상
                letterSpacing: 1.0, // 글자 간격
              ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 30),

            ElevatedButton.icon(
              onPressed: () => _handleSignIn(context),
              label: const Text(
                'Sign up for free',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              style: ButtonStyles.loginButtonStyle(context),
            ),

            const SizedBox(height: 15),

            ElevatedButton(
              onPressed: _handleGoogleSignIn,
              style: ButtonStyles.loginButtonStyle(context),
              child: Stack(
                alignment: Alignment.center, // 텍스트를 정확히 버튼 중앙 정렬
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.max, // 버튼 크기를 넘어서지 않도록 설정
                    children: [
                      SizedBox(
                        width: 24, // 로고 크기 고정
                        height: 24,
                        child: Image.asset(
                          'assets/google_logo.png',
                          fit: BoxFit.cover,
                        ),
                      ),
                    ],
                  ),
                  const Text(
                    'Continue with Google',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center, // 텍스트 중앙 정렬
                  ),
                ],
              ),
            ),
            // 로그인 상태에 따른 UI 표시
            // if (_currentUser == null)
            //   ElevatedButton(
            //     onPressed: _handleGoogleSignIn,
            //     style: ButtonStyles.loginButtonStyle(context),
            //     child: Stack(
            //       alignment: Alignment.center, // 텍스트를 정확히 버튼 중앙 정렬
            //       children: [
            //         Row(
            //           mainAxisSize: MainAxisSize.max, // 버튼 크기를 넘어서지 않도록 설정
            //           children: [
            //             SizedBox(
            //               width: 24, // 로고 크기 고정
            //               height: 24,
            //               child: Image.asset(
            //                 'assets/google_logo.png',
            //                 fit: BoxFit.cover,
            //               ),
            //             ),
            //           ],
            //         ),
            //         const Text(
            //           'Continue with Google',
            //           style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            //           textAlign: TextAlign.center, // 텍스트 중앙 정렬
            //         ),
            //       ],
            //     ),
            //   )
            // else
            //   Column(
            //     children: [
            //       Text(
            //         'Name: ${_currentUser?.displayName ?? 'Unknown'}',
            //         style: const TextStyle(fontSize: 16),
            //       ),
            //       Text(
            //         'Email: ${_currentUser?.email ?? 'Unknown'}',
            //         style: const TextStyle(fontSize: 16),
            //       ),
            //       const SizedBox(height: 10),
            //       if (_currentUser?.photoUrl != null)
            //         CircleAvatar(
            //           backgroundImage: NetworkImage(_currentUser!.photoUrl!),
            //           radius: 40,
            //         ),
            //       const SizedBox(height: 20),
            //       ElevatedButton(
            //         onPressed: _handleSignOut,
            //         child: const Text(
            //           'Sign Out',
            //           style: TextStyle(fontSize: 16),
            //         ),
            //         style: ElevatedButton.styleFrom(
            //           backgroundColor: Colors.red, // 로그아웃 버튼 색상
            //           foregroundColor: Colors.white, // 버튼 텍스트 색상
            //           padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            //         ),
            //       ),
            //     ],
            //   ),

            const SizedBox(height: 15),

            ElevatedButton(
              onPressed: _handleGoogleSignIn,
              style: ButtonStyles.loginButtonStyle(context),
              child: Stack(
                alignment: Alignment.center, // 텍스트를 정확히 버튼 중앙 정렬
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.max, // 버튼 크기를 넘어서지 않도록 설정
                    children: [
                      SizedBox(
                        width: 24, // 로고 크기 고정
                        height: 24,
                        child: Image.asset(
                          'assets/kakao_logo.png',
                          fit: BoxFit.cover,
                        ),
                      ),
                    ],
                  ),
                  const Text(
                    'Continue with Kakao',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center, // 텍스트 중앙 정렬
                  ),
                ],
              ),
            ),

            const SizedBox(height: 15),

            ElevatedButton(
              onPressed: _handleGoogleSignIn,
              style: ButtonStyles.loginButtonStyle(context),
              child: Stack(
                alignment: Alignment.center, // 텍스트를 정확히 버튼 중앙 정렬
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.max, // 버튼 크기를 넘어서지 않도록 설정
                    children: [
                      SizedBox(
                        width: 24, // 로고 크기 고정
                        height: 24,
                        child: Image.asset(
                          'assets/facebook_logo.png',
                          fit: BoxFit.cover,
                        ),
                      ),
                    ],
                  ),
                  const Text(
                    'Continue with Facebook',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center, // 텍스트 중앙 정렬
                  ),
                ],
              ),
            ),
            const SizedBox(height: 15),
            GestureDetector(
              onTap: () => _handleLogIn(context),
              // onTap: (){
              //
              // },
              child: Text(
                'Log in',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white),
              ),
            )
          ],
        ),
      ),
    );
  }
}
