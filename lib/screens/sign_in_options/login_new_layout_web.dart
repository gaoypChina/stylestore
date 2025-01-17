import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:rounded_loading_button_plus/rounded_loading_button.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:stylestore/Utilities/constants/color_constants.dart';
import 'package:stylestore/model/common_functions.dart';
import 'package:stylestore/screens/sign_in_options/signup_page.dart';
import 'package:stylestore/screens/sign_in_options/signup_pages/signup_mobile.dart';
import 'package:stylestore/screens/sign_in_options/signup_pages/signup_web.dart';

import '../../Utilities/constants/font_constants.dart';
import '../../Utilities/constants/user_constants.dart';
import '../../controllers/responsive/responsive_page.dart';
import '../../model/styleapp_data.dart';
import 'employee_sign_in.dart';

class LoginPageNewWeb extends StatefulWidget {
  static String id = 'login_page_new_web';
  @override
  _LoginPageNewWebState createState() => _LoginPageNewWebState();
}

class _LoginPageNewWebState extends State<LoginPageNewWeb> {
  final auth = FirebaseAuth.instance;
  String email = ' ';
  String password = ' ';

  final RoundedLoadingButtonController _btnController =
  RoundedLoadingButtonController();
  bool showSpinner = false;
  bool ownerLogin = false;


  void defaultsInitiation() async {
    final prefs = await SharedPreferences.getInstance();
    bool isLoggedIn = prefs.getBool(kIsLoggedInConstant) ?? false;
    setState(() {
      userLoggedIn = isLoggedIn;
      if (userLoggedIn == true) {
        Navigator.pushNamed(context, SuperResponsiveLayout.id);
      } else {
        print('NOT LOGGED IN');
      }
    });
  }

  bool userLoggedIn = false;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          Expanded(
            flex: 1,
            child: Container(
              height: double.infinity,
              color: kAppPinkColor,
              child: Image.asset("images/business_setup.png", fit: BoxFit.fitHeight,),
            ),
          ),
          Expanded(
            flex: 1,
            child: SingleChildScrollView(
              child: Container(
                color: kPureWhiteColor,
                child: Padding(
                    padding: EdgeInsets.only(
                      left: 50,
                      right: 50,
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.start,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        kLargeHeightSpacing,
                        Image.asset(
                          'images/new_logo.png',
                          height: 60,
                        ),
                        Text(
                          "Your Business On\nAuto Pilot",
                          textAlign: TextAlign.center,
                          style: kNormalTextStyle.copyWith(
                              fontSize: 30,
                              fontWeight: FontWeight.bold,
                              color: kBlack),
                        ),
                        Divider(
                          color: kBlueDarkColorOld.withOpacity(0.1),
                        ),
                        Text("Start Here",
                            style: kNormalTextStyle.copyWith(fontSize: 15)),
                        GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => SuperResponsiveLayout(
                                  mobileBody: SignupMobile(),
                                  desktopBody: SignupWeb(),
                                ),
                              ),
                            );
                          },
                          child: Container(
                            width: double.infinity,
                            height: 40,
                            decoration: BoxDecoration(
                              color: kPureWhiteColor,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: kPureWhiteColor,
                                width: 1,
                              ),
                            ),
                            child: Center(
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
              
              
                                    Text(
                                      "Create a New Business Account",
                                      style:
                                      kNormalTextStyle.copyWith(color:  Colors.blue, fontWeight: FontWeight.w900),
                                    ),
                                    Image.asset("images/takeflight.png",),
                                  ],
                                )),
                          ),
                        ),
                        kLargeHeightSpacing,
                        SizedBox(
                          height: 350,
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Divider(
                                color: kBlueDarkColorOld.withOpacity(0.1),
                              ),
                              Text("Or",
                                  style: kNormalTextStyle.copyWith(fontSize: 15)),
                              kLargeHeightSpacing,
                              ownerLogin == true
                                  ? Container()
                                  : GestureDetector(
                                onTap: () {
                                  setState(() {
                                    ownerLogin = true;
                                  });
                                },
                                child: Container(
                                  width: double.infinity,
                                  height: 40,
                                  decoration: BoxDecoration(
                                    color: kAppPinkColor,
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(
                                      color: kPureWhiteColor,
                                      width: 1,
                                    ),
                                  ),
                                  child: Center(
                                      child: Text(
                                        "Login as Business Owner",
                                        style: kNormalTextStyle.copyWith(
                                            color: kPureWhiteColor),
                                      )),
                                ),
                              ),
                              kSmallHeightSpacing,
                              ownerLogin == false
                                  ? Container()
                                  : Column(
                                children: [
                                  Container(
                                    decoration: BoxDecoration(
                                        borderRadius:
                                        BorderRadius.circular(10),
                                        color: Colors.white,
                                        boxShadow: [
                                          const BoxShadow(
                                            color: kBlueDarkColorOld,
                                            blurRadius: 3,
                                            offset: Offset(0, 2),
                                          )
                                        ]),
                                    child: Column(
                                      children: [
                                        Container(
                                          padding: EdgeInsets.all(10),
                                          decoration: BoxDecoration(
                                              border: Border(
                                                  bottom: BorderSide(
                                                      color:
                                                      kBlueDarkColorOld))),
                                          child: TextField(
                                            onChanged: (value) {
                                              email = value;
                                            },
                                            decoration: InputDecoration(
                                                border: InputBorder.none,
                                                hintText: 'Email Address',
                                                hintStyle: TextStyle(
                                                    color: Colors.grey)),
                                          ),
                                        ),
                                        // SizedBox(height: 10),
                                        Container(
                                          padding: EdgeInsets.all(10),
                                          child: TextField(
                                            obscureText: true,
                                            onChanged: (value) {
                                              password = value;
                                            },
                                            decoration: InputDecoration(
                                              border: InputBorder.none,
                                              hintText: 'Password',
                                              hintStyle: TextStyle(
                                                  color: Colors.grey),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  TextButton(
                                      onPressed: () {
                                        if (email != '') {
                                          auth.sendPasswordResetEmail(
                                              email: email);
                                          showDialog(
                                              context: context,
                                              builder:
                                                  (BuildContext context) {
                                                return CupertinoAlertDialog(
                                                  title: Text(
                                                      'Reset Email Sent'),
                                                  content: Text(
                                                      'Check email $email for the reset link'),
                                                  actions: [
                                                    CupertinoDialogAction(
                                                        isDestructiveAction:
                                                        true,
                                                        onPressed: () {
                                                          _btnController
                                                              .reset();
                                                          Navigator.pop(
                                                              context);
                                                        },
                                                        child:
                                                        Text('Cancel'))
                                                  ],
                                                );
                                              });
                                        } else {
                                          showDialog(
                                              context: context,
                                              builder:
                                                  (BuildContext context) {
                                                return CupertinoAlertDialog(
                                                  title: Text('Type Email'),
                                                  content: Text(
                                                      'Please type your email Address and Click on the forgot password!'),
                                                  actions: [
                                                    CupertinoDialogAction(
                                                        isDestructiveAction:
                                                        true,
                                                        onPressed: () {
                                                          //_btnController.reset();
                                                          Navigator.pop(
                                                              context);
                                                        },
                                                        child:
                                                        Text('Cancel'))
                                                  ],
                                                );
                                              });
                                        }
                                      },
                                      child: Text('Forgot Password')),
                                  RoundedLoadingButton(
                                    color: kAppPinkColor,
                                    child: Text('Login',
                                        style:
                                        TextStyle(color: Colors.white)),
                                    controller: _btnController,
                                    onPressed: () async {
                                      try {
                                        await auth
                                            .signInWithEmailAndPassword(
                                            email: email,
                                            password: password);
                                        final users =
                                        await FirebaseFirestore.instance
                                            .collection('users')
                                            .doc(auth.currentUser!.uid)
                                            .get();
                                        if (users['subscribed'] == false) {
                                          print("WE ENTERED HERE");
              
                                          final store =
                                          await FirebaseFirestore
                                              .instance
                                              .collection('medics')
                                              .doc(
                                              auth.currentUser!.uid)
                                              .get();
                                          print("WE NEED THIS");
                                          final prefs =
                                          await SharedPreferences
                                              .getInstance();
                                          print('${store['open']}');
                                          prefs.setString(
                                              kBusinessNameConstant,
                                              store['name']);
                                          prefs.setString(kLocationConstant,
                                              store['location']);
                                          prefs.setString(kImageConstant,
                                              store['image']);
                                          prefs.setString(kStoreIdConstant,
                                              store['id']);
                                          prefs.setInt(kStoreOpeningTime,
                                              store['open']);
                                          prefs.setInt(kStoreClosingTime,
                                              store['close']);
                                          prefs.setString(kLoginPersonName,
                                              users['lastName']);
                                          prefs.setString(kPermissions,
                                              store['permissions']);
                                          prefs.setBool(kDoesMobileConstant,
                                              store['doesMobile']);
                                          prefs.setBool(kIsOwner, true);
                                          prefs.setString(
                                              kEmployeeId, users.id);
                                          //prefs.setStringList(kStoreIdConstant, store['blackout']);
              
                                          prefs.setString(
                                              kPhoneNumberConstant,
                                              users['phoneNumber']);
                                          prefs.setBool(
                                              kIsLoggedInConstant, true);
                                          // subscribeToTopic();
                                          CommonFunctions().deliveryStream(context);
              
                                          Navigator.pushNamed(context,
                                              SuperResponsiveLayout.id);
                                        } else {
                                          showDialog(
                                              context: context,
                                              builder:
                                                  (BuildContext context) {
                                                return CupertinoAlertDialog(
                                                  title: Text(
                                                      'This account is not Registered for Beautician'),
                                                  content: Text(
                                                      'The credentials you have entered are incorrect'),
                                                  actions: [
                                                    CupertinoDialogAction(
                                                        isDestructiveAction:
                                                        true,
                                                        onPressed: () {
                                                          _btnController
                                                              .reset();
                                                          Navigator.pop(
                                                              context);
                                                        },
                                                        child:
                                                        Text('Cancel'))
                                                  ],
                                                );
                                              });
                                        }
              
                                        //showSpinner = false;
                                      } catch (e) {
                                        _btnController.error();
                                        showDialog(
                                            context: context,
                                            builder:
                                                (BuildContext context) {
                                              return CupertinoAlertDialog(
                                                title: Text(
                                                    'Oops Login Failed'),
                                                content: Text("$e"),
                                                actions: [
                                                  CupertinoDialogAction(
                                                      isDestructiveAction:
                                                      true,
                                                      onPressed: () {
                                                        _btnController
                                                            .reset();
                                                        Navigator.pop(
                                                            context);
                                                      },
                                                      child: Text('Cancel'))
                                                ],
                                              );
                                            });
                                      }
                                    },
                                  ),
                                ],
                              ),
                              kLargeHeightSpacing,
                              GestureDetector(
                                onTap: () {
                                  Navigator.pushNamed(context, EmployeeSignIn.id);
                                },
                                child: Container(
                                  width: double.infinity,
                                  height: 40,
                                  decoration: BoxDecoration(
                                    color: kBlueDarkColor,
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(
                                      color: kPureWhiteColor,
                                      width: 1,
                                    ),
                                  ),
                                  child: Center(
                                      child: Text(
                                        "Login as Staff Member",
                                        style: kNormalTextStyle.copyWith(
                                            color: kPureWhiteColor),
                                      )),
                                ),
                              ),
                              kLargeHeightSpacing,
                            ],
                          ),
                        ),
                      ],
                    )),
              ),
            ),
          )
        ],
      ),
    );
  }
}
