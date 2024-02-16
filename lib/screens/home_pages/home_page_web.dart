import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:stylestore/utilities/constants/color_constants.dart';
import '../../Utilities/constants/font_constants.dart';
import '../../Utilities/constants/user_constants.dart';
import '../../controllers/responsive/responsive_dimensions.dart';
import '../../model/common_functions.dart';
import '../../model/styleapp_data.dart';
import '../../utilities/constants/word_constants.dart';
import '../../widgets/documents_widget.dart';
import '../../widgets/photo_widget.dart';
import '../../widgets/rounded_icon_widget.dart';
import '../HomePageWidgets/summary_widget.dart';
import '../customer_pages/customers_page.dart';
import '../expenses_pages/expenses.dart';
import '../payment_pages/pos2.dart';
import '../sign_in_options/sign_in_page.dart';
import '../tasks_pages/tasks_widget.dart';

class HomePageWeb extends StatefulWidget {
  static String id = "home_page_web";

  @override
  State<HomePageWeb> createState() => _HomePageWebState();
}

class _HomePageWebState extends State<HomePageWeb> {
  List information = [
    "Onboard new Employees",
    "Monitor development of HR System",
    "Plan for 2024 MCF Culture"
  ];
  final reasonOptions = [
    'Sick Leave',
    'Vacation',
    'Mandatory Leave',
    'Emergency'
  ];
  String? selectedReason;
  Map<String, dynamic> permissionsMap = {};
  String businessName = 'Business';
  String userName = "";
  String image = '';
  String storeId = '';
  var storeLocation = "";
  late bool isCheckedIn;

  FirebaseFirestore firestore = FirebaseFirestore.instance;




  DateTimeRange? selectedDateRange;
  void defaultInitialization() async {
    permissionsMap = await CommonFunctions().convertPermissionsJson();

    final prefs = await SharedPreferences.getInstance();
    String newName = prefs.getString(kBusinessNameConstant) ?? 'Hi';
    storeLocation = prefs.getString(kLocationConstant) ?? 'Kampala';
    String newImage = prefs.getString(kImageConstant) ?? 'new_logo.png';
    String newStoreId = prefs.getString(kStoreIdConstant) ?? 'Hi';
    String newUserName = prefs.getString(kLoginPersonName) ?? "Hi";
    bool newIsCheckedIn = prefs.getBool(kIsCheckedIn) ?? false;
    Provider.of<StyleProvider>(context, listen: false)
        .setStoreValues(newStoreId, newImage);
    if (newIsCheckedIn == false) {
      Navigator.pushNamed(context, SignInUserPage.id);
    }

    setState(() {
      businessName = newName;
      image = newImage;
      storeId = newStoreId;
      isCheckedIn = newIsCheckedIn;
      userName = newUserName;
    });
  }

  @override
  initState() {
    defaultInitialization();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    var size = MediaQuery.of(context).size;
    return Scaffold(
      backgroundColor: kPlainBackground,
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Row(
                  children: [

                    RoundImageRing(radius: 60, outsideRingColor: kPureWhiteColor, networkImageToUse: Provider.of<StyleProvider>(context).beauticianImageUrl,),
                    kMediumWidthSpacing,
                    Text(
                      "$cHi $userName",
                      style: kHeading2TextStyleBold.copyWith(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    Spacer(),
                    permissionsMap['signIn'] == false ? Container():Padding(
                      padding: const EdgeInsets.all(8.0),
                      child:
                      GestureDetector(
                        onTap: (){
                          showDialog(context: context, builder: (BuildContext context){
                            return CupertinoAlertDialog(
                              title:Text(cSignOut.tr),
                              content: Text('${cSignOutInstructions.tr} \n${DateFormat('hh:mm a EE, dd, MMM, yyy').format(DateTime.now())}'),
                              actions: [
                                CupertinoDialogAction(isDestructiveAction: true,
                                    onPressed: (){
                                      Navigator.pop(context);

                                    },

                                    child: Text(cCancel.tr)
                                ),
                                CupertinoDialogAction(isDefaultAction: true,
                                  onPressed: (){

                                    Navigator.pop(context);
                                    CommonFunctions().signOutUser(context);

                                  }, child: Text(cSignOut.tr),)
                              ],
                            );
                          });

                        },
                        child: Tooltip(
                          message: cSignOutOfWork.tr,
                          child: Container(
                            height: 50,
                            width: 100,

                            decoration: BoxDecoration(
                              color: kBlack,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Center(child: Text(cSignOutOfWork.tr, style: kNormalTextStyle.copyWith(color: kPureWhiteColor, fontSize: 13),)),
                            // color: kAirPink,
                          ),
                        ),
                      ),
                    ),

                  ],
                ),
              ),
              kLargeHeightSpacing,
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Left Container
                  Expanded(
                    flex: 2,
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Container(
                              margin:
                                  EdgeInsets.only(left: 2, right: 2, top: 2),
                              padding: EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(10),
                                color:
                                    kPureWhiteColor, // Use Colors.white instead of kPureWhiteColor
                              ),
                              child: Column(
                                children: [
                                  Row(
                                    children: [
                                      Text(
                                        cDepartment.tr,
                                        style: kNormalTextStyle.copyWith(
                                            color: kGreenThemeColor,
                                            fontWeight: FontWeight.bold),
                                      ),
                                      kMediumWidthSpacing,
                                      Text("Operations"),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              margin:
                              EdgeInsets.only(left: 2, right: 2, top: 2),
                              padding: EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(10),
                                color:
                                    kPureWhiteColor, // Use Colors.white instead of kPureWhiteColor
                              ),
                              child: Column(
                                children: [
                                  Row(
                                    children: [
                                      Text(
                                        cCheckinTime.tr,
                                        style: kNormalTextStyle.copyWith(
                                            color: kBlack,
                                            fontWeight: FontWeight.bold),
                                      ),
                                      kMediumWidthSpacing,
                                      Text("12:53pm"),
                                    ],
                                  ),
                                ],
                              ),
                            ),

                          ],
                        ),
                        Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: Column(
                            children: [
                              Padding(
                                padding: const EdgeInsets.only(left:16.0),
                                child: Row(
                                  children: [
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        permissionsMap['sales'] == true
                                            ? PhotoWidget(
                                                onTapFunction: () {
                                                  Provider.of<StyleProvider>(
                                                          context,
                                                          listen: false)
                                                      .resetSelectedStockBasket();
                                                  Provider.of<StyleProvider>(
                                                          context,
                                                          listen: false)
                                                      .resetCustomerDetails();
                                                  Provider.of<StyleProvider>(
                                                          context,
                                                          listen: false)
                                                      .clearLists();
                                                  Navigator.pushNamed(
                                                      context, POS.id);
                                                },
                                                footer: cSale.tr,
                                                iconToUse: Icons.point_of_sale,
                                                widgetColor: kSalesButtonColor,
                                                iconColor: kBlueDarkColor,
                                                fontSize: CommonFunctions()
                                                    .calculateFontSize(context)
                                                // 16,

                                                )
                                            : Container(),
                                        kMediumWidthSpacing,
                                        permissionsMap['customers'] == true
                                            ? PhotoWidget(
                                                onTapFunction: () {
                                                  Navigator.pushNamed(
                                                      context, CustomerPage.id);
                                                },
                                                footer: cCustomers,
                                                iconToUse:
                                                    Icons.people_alt_outlined,
                                                widgetColor: kCustomersButtonColor,
                                                iconColor: kBlueDarkColor,
                                                fontSize: CommonFunctions()
                                                    .calculateFontSize(context),
                                              )
                                            : Container(),
                                      ],
                                    ),

                                    size.width > 1151 ? Expanded(
                                            child: permissionsMap['expenses'] ==
                                                    true
                                                ? Padding(
                                                    padding:
                                                        const EdgeInsets.only(
                                                            left: 10.0,
                                                            right: 10),
                                                    child: PhotoWidget(onTapFunction: () {
                                                        Navigator.pushNamed(
                                                            context,
                                                            ExpensesPage.id);
                                                      },
                                                      footer: cExpense,
                                                      iconToUse: Icons.monetization_on,
                                                      widgetColor: kPureWhiteColor,
                                                      iconColor: kBlueDarkColor,
                                                      width: double.infinity,
                                                      fontSize: CommonFunctions()
                                                          .calculateFontSize(
                                                              context),
                                                    ),
                                                  )
                                                : Container())
                                        : Container(),
                                  ],
                                ),
                              ),
                              LayoutBuilder(
                                builder: (BuildContext context,
                                    BoxConstraints constraints) {
                                  if (constraints.maxWidth <
                                      screenDisplayWidth) {
                                    return Padding(
                                      padding: const EdgeInsets.only(left: 16.0, top: 8.0),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          permissionsMap['expenses'] == true
                                              ? PhotoWidget(
                                                  onTapFunction: () {
                                                    Navigator.pushNamed(context,
                                                        ExpensesPage.id);
                                                  },
                                                  footer: cExpense,
                                                  iconToUse:
                                                      Icons.monetization_on,
                                                  widgetColor: kPureWhiteColor,
                                                  iconColor: kBlueDarkColor,
                                                  width: double.infinity,
                                                  fontSize: CommonFunctions()
                                                      .calculateFontSize(
                                                          context),
                                                )
                                              : Container(),
                                        ],
                                      ),
                                    );
                                  } else {
                                    return Container(); // Return an empty container if the condition is not met
                                  }
                                },
                              )
                            ],
                          ),
                        ),
                        Container(
                          margin: EdgeInsets.all(16),
                          padding: EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors
                                .white, // Use Colors.white instead of kPureWhiteColor
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                cLatestTransactions.tr,
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              SizedBox(height: 10),
                              // Use ListView.builder for dynamic information list
                              Container(
                                  height: 300,
                                  // width: 350,
                                  child: SummaryPage()),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Right Container
                  Expanded(
                    flex: 1,
                    child: Container(
                      margin: EdgeInsets.all(16),
                      padding: EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors
                            .white, // Use Colors.white instead of kPureWhiteColor
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withOpacity(0.5),
                            spreadRadius: 1,
                            blurRadius: 1,
                            offset: Offset(0, 1),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                cTaskBoard.tr,
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              GestureDetector(
                                onTap: (){
                                  showDialog(context: context, builder: (BuildContext context){
                                    return
                                      Scaffold(
                                          appBar: AppBar(

                                            elevation: 0,

                                            title: Row(
                                              children: [
                                                Provider.of<StyleProvider>(context).kdsMode == false?
                                                Text("Your Tasks",style: kNormalTextStyle.copyWith(color: kBlack),):
                                                Text("Order Display System",textAlign: TextAlign.center,style: kNormalTextStyle.copyWith(color: kPureWhiteColor),),
                                                kMediumWidthSpacing,
                                                kMediumWidthSpacing,
                                                GestureDetector(
                                                  onTap: (){
                                                    var styleData = Provider.of<StyleProvider>(context, listen: false);
                                                    var boolToEnter = !styleData.kdsMode;
                                                    styleData.enterKDSmode(boolToEnter);
                                                    setState(() {

                                                    });
                                                  },
                                                  child: Tooltip(
                                                      message: "Enter KDS mode",
                                                      child: CircleAvatar(

                                                          child: Icon(Icons.tv_outlined))),
                                                )
                                              ],
                                            ),
                                            centerTitle: true,

                                            backgroundColor: Provider.of<StyleProvider>(context).kdsMode== true?kBlack: kPureWhiteColor,
                                            foregroundColor: Provider.of<StyleProvider>(context).kdsMode== true?kPureWhiteColor: kBlack,
                                          ),
                                          body: TasksWidget());
                                  });
                                },
                                child: Tooltip(
                                    message: "Expand the Tasks Board",
                                    child: Icon(Icons.expand, color: kBlueDarkColor,)),
                              )
                            ],
                          ),
                          SizedBox(height: 10),
                          // Use ListView.builder for dynamic information list
                          Container(height: 500, child: TasksWidget()),
                          // Container(
                          //   height: 220,
                          //   child:
                          //   ListView.builder(
                          //     itemCount: information.length, // Change the itemCount accordingly
                          //     itemBuilder: (context, index) {
                          //       final item = information[index];
                          //       final isChecked = _isChecked[index];
                          //       return
                          //         CheckboxListTile(
                          //           title: Text(
                          //             "${index+1}. ${item}",
                          //             style: TextStyle(
                          //               decoration: isChecked ? TextDecoration.lineThrough : null,
                          //               color: isChecked ? kAppPinkColor : kBlack,
                          //
                          //             ),
                          //           ),
                          //           value: isChecked,
                          //           onChanged: (newValue) => setState(() => _isChecked[index] = newValue!),
                          //         );
                          //
                          //     },
                          //   ),
                          // ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Card(
                          color: kPureWhiteColor,
                          child: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Column(
                              children: [
                                Text(
                                  'Customer Celebrations',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                                Card(
                                  child: Padding(
                                    padding: const EdgeInsets.all(8.0),
                                    child: Row(
                                      children: [
                                        CircleAvatar(
                                          backgroundColor: kBeigeColor,
                                          child: Text('KP'),
                                        ),
                                        SizedBox(width: 16),
                                        Flexible(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text('Mugurusi Ronald',
                                                  overflow:
                                                      TextOverflow.ellipsis),
                                              Text(
                                                'January 13-Happy Birthday!',
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      // Spacer(),
                      Expanded(
                        child: Card(
                          color: kPureWhiteColor,
                          child: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Column(
                              children: [
                                Text(
                                  "Today's Activities",
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                                Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: Column(
                                    children: [
                                      // scheduledActivitiesWidget(heading: 'Monday 1st January', subheading: 'New year Service Kololo',),
                                      // scheduledActivitiesWidget(heading: 'Monday 3rd January', subheading: 'Onboard New Employees',),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      // Spacer(),
                      Expanded(
                        child: Card(
                          color: kPureWhiteColor,

                          child: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Column(
                              children: [
                                Text(
                                  'Documentation',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                                Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      CompanyDocumentationWidget(heading: 'Making Salad Dressing', subheading: '30th Jan 2024',),
                                      CompanyDocumentationWidget(heading: 'Recording Setup, Audio Mixing, Host and Guest Techniques', subheading: '11th May 2023',),
                                      CompanyDocumentationWidget(heading: 'Pre-Production: Show Concept, Guest Booking, Scriptwriting, Music Cues', subheading: '12th Feb 2023',),
                                      CompanyDocumentationWidget(heading: 'Technical Specifications: Equipment Usage, Troubleshooting Tips', subheading: '16th Dec 2023',),
                                      CompanyDocumentationWidget(heading: 'Post-Production: Editing, Mastering, Delivery Formats, Archiving', subheading: '12th July 2023',),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}