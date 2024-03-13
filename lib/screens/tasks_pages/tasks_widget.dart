import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:iconsax/iconsax.dart';
import 'package:intl/intl.dart';
import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:lottie/lottie.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:slide_countdown/slide_countdown.dart';
import 'package:slider_button/slider_button.dart';
import 'package:stylestore/Utilities/constants/user_constants.dart';
import 'package:stylestore/model/common_functions.dart';
import 'package:stylestore/screens/tasks_pages/add_tasks.dart';
import 'package:stylestore/utilities/constants/color_constants.dart';
import 'package:stylestore/widgets/dividing_line_widget.dart';
import '../../Utilities/constants/font_constants.dart';
import '../../model/styleapp_data.dart';

class TasksWidget extends StatefulWidget {
  const TasksWidget({Key? key}) : super(key: key);

  @override
  State<TasksWidget> createState() => _TasksWidgetState();
}

class _TasksWidgetState extends State<TasksWidget> {
  var orderStatus = [];
  var colours = [];
  var location = [];
  var storeLocation = "";
  var createdBy = [];
  var idList = [];
  var fromList = [];
  var formatter = NumberFormat('#,###,000');
  var instructions = [];
  var createdDate = [];
  var completedTasks = [];
  var dueDate = [];
  var bookingFee = [];
  var taskList = [];
  var cardColor = [];
  var textColor = [];
  var phoneCircleColor = [];
  var names = [];
  var appointmentsToday = [];
  List taskDates = [];
  var statusList = [];
  var bellOpacity = [];
  var datesColor = [];
  List<Color> onlineStatusColour = [];
  var totalBill = [];
  var newOrderNumber = 0;
  late bool isCheckedIn;

  String businessName = 'Business';
  String userName = "";
  String employeeId = "";
  String image = '';
  String storeId = '';
  bool kdsMode = false;

  void defaultInitialization() async {
    final prefs = await SharedPreferences.getInstance();
    storeId = prefs.getString(kStoreIdConstant) ?? "";
    userName = prefs.getString(kLoginPersonName) ?? "";
    employeeId = prefs.getString(kEmployeeId) ?? "";
    setState(() {});
  }

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    defaultInitialization();
  }

  @override
  Widget build(BuildContext context) {
    var styleDataDisplay =  Provider.of<StyleProvider>(context);
    return Scaffold(
      backgroundColor: styleDataDisplay.kdsMode == false ?kPureWhiteColor: kBlack,
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(top: 8.0),
        child:  Provider.of<StyleProvider>(context).kdsMode == true?Container(): FloatingActionButton.extended(
          splashColor: kCustomColor,
          // foregroundColor: Colors.black,
          backgroundColor: kAppPinkColor,
          //blendedData.saladButtonColour,
          onPressed: () async {
            Provider.of<StyleProvider>(context, listen: false).setTaskToDo("");
            showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                builder: (context) {
                  return Scaffold(
                      appBar: AppBar(
                        automaticallyImplyLeading: false,
                        backgroundColor: kPureWhiteColor,
                        elevation: 0,
                      ),
                      body: AddTasksWidget());
                });
          },

          // icon: Icon(Icons.toggle_off_outlined, color: kPureWhiteColor,) ,
          label: const Icon(Icons.add, color: kPureWhiteColor),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endTop,
      body:
      Padding(
        padding: const EdgeInsets.all(15.0),
        child:
        StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('tasks')
                .where('storeId', isEqualTo: storeId)
                .orderBy('createdDate', descending: true)
                .snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return Container();
              } else {
                createdBy = [];
                location = [];
                idList = [];
                orderStatus = [];
                createdDate = [];
                dueDate = [];
                taskList = [];
                instructions = [];
                totalBill = [];
                statusList = [];
                onlineStatusColour = [];
                bellOpacity = [];
                cardColor = [];
                textColor = [];
                phoneCircleColor = [];
                bookingFee = [];
                fromList = [];
                taskDates = [];
                completedTasks = [];

                var orders = snapshot.data?.docs;
                for (var order in orders!) {
                  if (order.get('status') != true) {
                    if( order.get('completed').every((element) => element == true)){

                    }else{
                      if (order.get('to') == "Everyone" ||
                          order.get('to') == userName ||
                          order.get('from') == employeeId) {
                        createdBy.add(order.get('createdBy'));
                        idList.add(order.get('id'));
                        fromList.add(order.get('from'));
                        orderStatus.add(order.get('status'));
                        createdDate.add(order.get('createdDate').toDate());
                        dueDate.add(order.get('dueDate').toDate());
                        taskList.add(order.get('task'));
                        statusList.add(order.get("toName"));
                        completedTasks.add(order.get("completed"));
                        // List<Timestamp> firestoreTimestamps = order.get('selectedDates');

                        taskDates.add(order
                            .get('selectedDates')
                            .map((timestamp) => timestamp.toDate())
                            .toList());

                        String datesReceived = order
                            .get('selectedDates')
                            .map((timestamp) => DateFormat('d-MM-yyyy')
                            .format(timestamp.toDate()))
                            .toList()
                            .join(',');
                        // convert the lists of datesReceived to a list
                        List<String> datesReceivedList = datesReceived.split(', ');

                        String currentDateTime = DateFormat('d-MM-yyyy').format(DateTime.now());

                        // print(datesReceivedList);
                        // IF KDS MODE IS ACTIVE
                        if(styleDataDisplay.kdsMode == false){
                          if (datesReceivedList.any((dates) => dates.contains(currentDateTime))) {

                            bellOpacity.add(1.0);
                            onlineStatusColour.add(kGreenThemeColor);
                            appointmentsToday.add(order.get('toName'));
                            cardColor.add(kBlueDarkColorOld);
                            phoneCircleColor.add(kAppPinkColor);
                            textColor.add(kPureWhiteColor);
                            datesColor.add(kAppPinkColor);
                          }
                          else {
                            bellOpacity.add(0.0);
                            onlineStatusColour.add(kAppPinkColor);
                            cardColor.add(kPlainBackground);
                            phoneCircleColor.add(kBlueDarkColorOld);
                            textColor.add(kBlack);
                            datesColor.add(kBeigeColor);
                          }
                        }else {
                          if (datesReceivedList.any((dates) => dates.contains(currentDateTime)))

                          {
                            bellOpacity.add(1.0);
                            onlineStatusColour.add(kGreenThemeColor);
                            appointmentsToday.add(order.get('toName'));
                            cardColor.add(kPureWhiteColor);
                            phoneCircleColor.add(kAppPinkColor);
                            textColor.add(kPureWhiteColor);
                            datesColor.add(kAppPinkColor);
                          }
                          else {
                            bellOpacity.add(0.0);
                            onlineStatusColour.add(kAppPinkColor);
                            cardColor.add(kPlainBackground);
                            phoneCircleColor.add(kBlueDarkColorOld);
                            textColor.add(kBlack);
                            datesColor.add(kBeigeColor);
                          }
                        }
                      }
                    }
                  }
                }
                // return Text('Let us understand this ${deliveryTime[3]} ', style: TextStyle(color: Colors.white, fontSize: 25),);
                return idList.isEmpty
                    ? const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Iconsax.designtools5,
                          color: kAppPinkColor,
                        ),
                        Text(
                          "Your Tasks will appear here",
                          style: kNormalTextStyle,
                        ),
                      ],
                    ))
                // Center(child: Text("Nothing"),)
                    : StaggeredGridView.countBuilder(
                    crossAxisCount: 2,
                    itemCount: idList.length,
                    crossAxisSpacing: 10,
                    // physics: NeverScrollableScrollPhysics(),
                    shrinkWrap: true,
                    itemBuilder: (context, index) {
                      return
                        Stack(

                            children: [
                              GestureDetector(
                                onTap: () {
                                  showDialog(
                                      context: context,
                                      builder: (BuildContext context) {
                                        return GestureDetector(
                                            onTap: () {
                                              Navigator.pop(context);
                                            },
                                            child: Material(
                                                color: Colors.black,
                                                child: Stack(
                                                  // mainAxisAlignment: MainAxisAlignment.center,

                                                  children: [
                                                    Positioned(
                                                      top: 70,
                                                      left: 10,
                                                      right: 10,
                                                      child: TextButton(
                                                        onPressed: () {
                                                          showDialog(
                                                            context: context,
                                                            builder: (BuildContext context) {
                                                              return AlertDialog(
                                                                title: const Text("Confirm Deletion"),
                                                                content: const Text("Are you sure you want to delete this task?"),
                                                                actions: <Widget>[
                                                                  TextButton(
                                                                    child: const Text("Cancel"),
                                                                    onPressed: () => Navigator.pop(context),
                                                                  ),
                                                                  TextButton(
                                                                    child: const Text("Delete"),
                                                                    onPressed: () {
                                                                      Navigator.pop(context); // Close the dialog
                                                                      Navigator.pop(context);  // Execute original pop
                                                                      CommonFunctions().updateDocumentFromServer(
                                                                          idList[index],
                                                                          "tasks",
                                                                          "status",
                                                                          true);
                                                                    },
                                                                  ),
                                                                ],
                                                              );
                                                            },
                                                          );
                                                        },
                                                        child: const Text("Delete This Task",
                                                          style: TextStyle(
                                                              color: kPureWhiteColor,
                                                              fontWeight: FontWeight.w500,
                                                              fontSize: 17),
                                                        ),
                                                      ),
                                                    ),
                                                    Positioned(
                                                      top: 120,
                                                      right: 10,
                                                      left: 10,
                                                      child: Center(
                                                        child: SizedBox(
                                                            width: 500,
                                                            child: activeDatesWidget(taskDates: taskDates, index: index, datesColor: datesColor, textColor: textColor, taskCompleted: completedTasks, idList: idList, mainPage: false, )),
                                                      ),
                                                    ),
                                                    Center(
                                                      child: Padding(
                                                        padding:
                                                        const EdgeInsets.all(
                                                            15.0),
                                                        child: Stack(
                                                          children: [

                                                            Container(
                                                                decoration:const BoxDecoration(
                                                                    color:
                                                                    kPlainBackground,
                                                                    borderRadius:
                                                                    BorderRadius
                                                                        .all(Radius
                                                                        .circular(
                                                                        10))),
                                                                child: Padding(
                                                                  padding:
                                                                  const EdgeInsets
                                                                      .all(8.0),
                                                                  child: Text(
                                                                    '${taskList[index]}',
                                                                    textAlign: TextAlign
                                                                        .center,
                                                                    style: kNormalTextStyleDark
                                                                        .copyWith(
                                                                        color:
                                                                        kBlack,
                                                                        fontSize:
                                                                        20),
                                                                  ),
                                                                )),
                                                            Positioned(
                                                              right: 5,
                                                              top: 5,
                                                              child:  GestureDetector(
                                                                onTap: (){

                                                                },
                                                                child: const CircleAvatar(
                                                                    backgroundColor: kBlueDarkColor,
                                                                    child: Icon(Icons.edit, color: kPureWhiteColor,)),
                                                              ),)
                                                          ],
                                                        ),
                                                      ),
                                                    ),
                                                    Positioned(
                                                      top: 70,
                                                      left: 10,
                                                      right: 10,
                                                      child: TextButton(
                                                        onPressed: () {
                                                          showDialog(
                                                            context: context,
                                                            builder: (BuildContext context) {
                                                              return AlertDialog(
                                                                title: const Text("Confirm Deletion"),
                                                                content: const Text("Are you sure you want to delete this task?"),
                                                                actions: <Widget>[
                                                                  TextButton(
                                                                    child: const Text("Cancel"),
                                                                    onPressed: () => Navigator.pop(context),
                                                                  ),
                                                                  TextButton(
                                                                    child: const Text("Delete"),
                                                                    onPressed: () {
                                                                      Navigator.pop(context); // Close the dialog
                                                                      Navigator.pop(context);  // Execute original pop
                                                                      CommonFunctions().updateDocumentFromServer(
                                                                          idList[index],
                                                                          "tasks",
                                                                          "status",
                                                                          true);
                                                                    },
                                                                  ),
                                                                ],
                                                              );
                                                            },
                                                          );
                                                        },
                                                        child: const Text("Delete This Task",
                                                          style: TextStyle(
                                                              color: kPureWhiteColor,
                                                              fontWeight: FontWeight.w500,
                                                              fontSize: 17),
                                                        ),
                                                      ),
                                                    ),

                                                  ],
                                                )));
                                      });
                                },
                                child: taskContainers(cardColor: cardColor, fromList: fromList, employeeId: employeeId, createdBy: createdBy, textColor: textColor, taskList: taskList, taskDates: taskDates, datesColor: datesColor, index: index, completedTasks: completedTasks, idList: idList,),
                              ),
                              Positioned(
                                left: 10,
                                bottom: 10,
                                child: Opacity(
                                  opacity: 1,
                                  child: Container(
                                    decoration: BoxDecoration(
                                        color: onlineStatusColour[index],
                                        borderRadius:
                                        BorderRadius.all(Radius.circular(6))),
                                    child: Padding(
                                      padding: EdgeInsets.all(3.0),
                                      child: Row(
                                        children: [
                                          Text(
                                            statusList[index],
                                            style:
                                            kNormalTextStyleWhitePendingLabel
                                                .copyWith(fontSize: 10),
                                          ),
                                          // Lottie.asset('images/new_order.json',height: 20)
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              // Positioned(
                              //   right: 12,
                              //   bottom: 5,
                              //   child: Opacity(
                              //     opacity: bellOpacity[index],
                              //     child: Lottie.asset('images/ring.json',
                              //         height: 30),
                              //   ),
                              // ),

                            ]);
                    },
                    staggeredTileBuilder: (index) => StaggeredTile.fit(1));
              }
            }),
      ),
    );
  }
}

class taskContainers extends StatelessWidget {
  const taskContainers({
    super.key,
    required this.cardColor,
    required this.fromList,
    required this.employeeId,
    required this.idList,
    required this.createdBy,
    required this.textColor,
    required this.taskList,
    required this.taskDates,
    required this.completedTasks,
    required this.datesColor,
    required this.index,

  });

  final List cardColor;
  final List idList;
  final List fromList;
  final String employeeId;
  final List createdBy;
  final List textColor;
  final List taskList;
  final List taskDates;
  final List completedTasks;
  final List datesColor;
  final int index;

  @override
  Widget build(BuildContext context) {
    return Provider.of<StyleProvider>(context).kdsMode == false ? Container(margin: const EdgeInsets.only(top: 10, right: 0, left: 0, bottom: 3),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        color: cardColor[index],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            //height: 170,
            child: Column(
              mainAxisAlignment:
              MainAxisAlignment.start,
              crossAxisAlignment:
              CrossAxisAlignment.start,
              children: [
                fromList[index] == employeeId
                    ? Text(
                  'Sent By You',
                  style: kNormalTextStyleDark
                      .copyWith(
                      color: kRedColor),
                )
                    : Text(
                  'By: ${createdBy[index]}',
                  style: kNormalTextStyleDark
                      .copyWith(
                      color:
                      textColor[index],
                      fontWeight:
                      FontWeight.bold),
                ),
                // DividingLine(),
                Text(
                  '${taskList[index].length > 50 ? taskList[index].substring(0, 50) + "..." : taskList[index]}',
                  style:
                  kNormalTextStyleDark.copyWith(
                    color: textColor[index],
                  ),
                ),

                const DividingLine(),
                Text('Active Dates',
                    style:
                    kNormalTextStyleDark.copyWith(
                        color: textColor[index],
                        fontWeight:
                        FontWeight.bold)),
                kSmallHeightSpacing,
                activeDatesWidget(taskDates: taskDates, index: index, datesColor: datesColor, textColor: textColor, taskCompleted: completedTasks, idList: idList, mainPage: true,),
                const DividingLine(),
                kLargeHeightSpacing,
                kLargeHeightSpacing,
              ],
            ),
          ),
        ],
      ),
    ):
    cardColor[index] == kPlainBackground?Container():Container(
      margin: EdgeInsets.only(
          top: 10, right: 0, left: 0, bottom: 3),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        color: cardColor[index],
      ),
      child: Column(
        children: [
          SerratedTicket(orderDetails: taskList[index], dates: taskDates[index],)
        ],
      ),
    )
    ;
  }
}

class activeDatesWidget extends StatelessWidget {
  const activeDatesWidget({
    super.key,
    required this.taskDates,
    required this.idList,
    required this.taskCompleted,
    required this.index,
    required this.datesColor,
    required this.textColor,
    required this.mainPage,


  });

  final List taskDates;
  final List taskCompleted;
  final List idList;
  final int index;
  final List datesColor;
  final List textColor;
  final bool mainPage;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 30,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount:
        taskDates[index].length,
        itemBuilder: (context, i) {
          return Padding(
            padding:
            const EdgeInsets.only(
                right: 8.0),
            child: GestureDetector(
              onTap: () {
                if(taskCompleted[index][i] == false){
                  showDialog(
                    context: context,
                    builder: (BuildContext context) {
                      return AlertDialog(
                        title: Text("Mark Task as Done?",textAlign: TextAlign.center,),
                        content: Text("Do you want to mark this task as done on ${DateFormat('d, MMMM, yyyy').format(taskDates[index][i])}?"),
                        actions: [
                          TextButton(
                            child: Text("Cancel"),
                            onPressed: () {
                              Navigator.pop(context); // Close the dialog
                            },
                          ),
                          TextButton(
                            child: Text("Confirm"),
                            onPressed: () {
                              var changedTaskList = taskCompleted[index];
                              changedTaskList[i] = true;
                              CommonFunctions()
                                  .updateDocumentFromServer(
                                  idList[index], "tasks", "completed", changedTaskList);
                              if(mainPage == true){
                                Navigator.pop(context);
                              }else {
                                Navigator.pop(context);
                                Navigator.pop(context);
                              }
                              // Close the dialog
                              // Navigator.pop(context); // Close the original context (assuming this is in a widget)
                            },
                          ),
                        ],
                      );
                    },
                  );
                } else {
                  showDialog(
                    context: context,
                    builder: (BuildContext context) {
                      return AlertDialog(
                        title: Text("Remove this Task from Completed?",textAlign: TextAlign.center,),
                        content: Text("Do you want to change this task on ${DateFormat('d, MMMM, yyyy').format(taskDates[index][i])} to NOT DONE?"),
                        actions: [
                          TextButton(
                            child: Text("Cancel"),
                            onPressed: () {
                              Navigator.pop(context); // Close the dialog
                            },
                          ),
                          TextButton(
                            child: Text("Confirm"),
                            onPressed: () {
                              var changedTaskList = taskCompleted[index];
                              changedTaskList[i] = false;
                              CommonFunctions()
                                  .updateDocumentFromServer(
                                  idList[index], "tasks", "completed", changedTaskList);
                              if(mainPage == true){
                                Navigator.pop(context);
                              }else {
                                Navigator.pop(context);
                                Navigator.pop(context);
                              }// Close the dialog
                              // Navigator.pop(context); // Close the original context (assuming this is in a widget)
                            },
                          ),
                        ],
                      );
                    },
                  );
                }

              },
              child: Container(
                decoration: BoxDecoration(
                  color: taskCompleted[index][i] == false?datesColor[index]:kGreenThemeColor,
                  borderRadius:
                  BorderRadius.circular(
                      10),
                ),
                child: Padding(
                  padding:
                  const EdgeInsets.all(
                      8.0),
                  child: taskCompleted[index][i] == false? Text(
                    '${DateFormat('d-MMM-yy').format(taskDates[index][i])}',
                    style: kNormalTextStyleDark.copyWith(color:textColor[index], fontWeight: FontWeight.bold,),
                  ):Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text('${DateFormat('d').format(taskDates[index][i])}th Done',style: kNormalTextStyleDark.copyWith(color: textColor[index], fontWeight: FontWeight.bold)),
                      kSmallWidthSpacing,
                      Icon(Icons.check_circle_outline, color:textColor[index],size: 15,)
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}


class SerratedPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..color = Colors.black
      ..strokeWidth = 2.0;

    final double width = size.width;
    final double height = size.height;

    final double unitWidth = width / 10;

    final Path path = Path()
      ..moveTo(0, 0)
      ..lineTo(0, height)
      ..moveTo(0, height)
      ..lineTo(width, height)
      ..moveTo(width, height)
      ..lineTo(width, 0);

    for (int i = 1; i < 10; i++) {
      if (i % 2 != 0) {
        path.moveTo(i * unitWidth, height);
        path.lineTo((i + 1) * unitWidth, 0);
      } else {
        path.moveTo(i * unitWidth, 0);
        path.lineTo((i + 1) * unitWidth, height);
      }
    }

    canvas.drawPath(path, paint);
  }
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return false;
  }
}

class SerratedTicket extends StatelessWidget {
  final String orderDetails;
  final List<dynamic> dates; // Renamed to 'dates' for clarity

  SerratedTicket({required this.orderDetails, required this.dates});
  Color countdownColor = kGreenThemeColor;
  Color secondsColor = kAppPinkColor;
  String dueStatement = "Due at";
  Duration timeUntil (DateTime targetTime) {
    final now = DateTime.now();
    final diff = targetTime.difference(now);
    int selectedHour = targetTime.hour;



    if (diff.isNegative) {
      if (now.hour > selectedHour){
        DateTime currentDate = DateTime( DateTime.now().year,DateTime.now().month ,DateTime.now().day, targetTime.hour, targetTime.minute  );
        countdownColor = kRedColor;
        secondsColor = kBlack;
        dueStatement = "Was Due at";
        return now.difference(currentDate);
      }else {
        DateTime currentDate = DateTime( DateTime.now().year,DateTime.now().month ,DateTime.now().day , targetTime.hour, targetTime.minute  );
        return currentDate.difference(now);
      }
    }
    return diff;
  }



  @override
  Widget build(BuildContext context) {
    DateTime? dueDate = _findDateMatchingToday(dates);
    StreamDuration streamDuration = StreamDuration(
      config: StreamDurationConfig(
        countDownConfig: CountDownConfig(duration: timeUntil(dueDate!)
        ),
      ),
    );

    return Container(
      padding: EdgeInsets.all(8.0),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8.0),
        border: Border.all(
          color: Colors.red,
          width: 2.0,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          if (dueDate != null) // Display 'Due at' only if a matching date is found
            Column(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  RawSlideCountdown(
                    streamDuration: streamDuration,
                    builder: (context, duration, countUp) {
                      return Row(

                        children: [
                          Column(

                            children: [
                              Text("HRS", style: kNormalTextStyle.copyWith(fontSize: 8, fontWeight: FontWeight.bold),),
                              kSmallHeightSpacing,
                              Container(
                                height: 30,

                                decoration: BoxDecoration(
                                    color: countdownColor,

                                    borderRadius: BorderRadius.circular(5)
                                ),
                                child:
                                Padding(
                                  padding: const EdgeInsets.all(3.0),
                                  child: Row(
                                    children: [
                                      RawDigitItem(
                                        duration: duration,
                                        timeUnit: TimeUnit.hours,
                                        digitType: DigitType.first,
                                        countUp: countUp,
                                        style: kNormalTextStyle.copyWith(color: kPureWhiteColor, fontWeight: FontWeight.w500),
                                      ),
                                      RawDigitItem(
                                        duration: duration,
                                        timeUnit: TimeUnit.hours,
                                        digitType: DigitType.second,
                                        countUp: countUp,
                                        style: kNormalTextStyle.copyWith(color: kPureWhiteColor, fontWeight: FontWeight.w500),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                          Center(child: Text(":")),
                          Column(
                            children: [
                              Text("MINS", style: kNormalTextStyle.copyWith(fontSize: 8, fontWeight: FontWeight.bold),),
                              kSmallHeightSpacing,
                              Container(
                                height: 30,

                                decoration: BoxDecoration(
                                    color: countdownColor,

                                    borderRadius: BorderRadius.circular(5)
                                ),
                                child:
                                Padding(
                                  padding: const EdgeInsets.all(3.0),
                                  child: Row(
                                    children: [
                                      RawDigitItem(
                                        duration: duration,
                                        timeUnit: TimeUnit.minutes,
                                        digitType: DigitType.first,
                                        countUp: countUp,
                                        style: kNormalTextStyle.copyWith(color: kPureWhiteColor, fontWeight: FontWeight.w500),
                                      ),
                                      RawDigitItem(
                                        duration: duration,
                                        timeUnit: TimeUnit.minutes,
                                        digitType: DigitType.second,
                                        countUp: countUp,
                                        style: kNormalTextStyle.copyWith(color: kPureWhiteColor, fontWeight: FontWeight.w500),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                          Text(":"),
                          Column(
                            children: [
                              Text("SECS", style: kNormalTextStyle.copyWith(fontSize: 8, fontWeight: FontWeight.bold),),
                              kSmallHeightSpacing,
                              Container(
                                height: 30,

                                decoration: BoxDecoration(
                                    color: secondsColor,

                                    borderRadius: BorderRadius.circular(5)
                                ),
                                child:
                                Padding(
                                  padding: const EdgeInsets.all(3.0),
                                  child: Row(
                                    children: [
                                      RawDigitItem(
                                        duration: duration,
                                        timeUnit: TimeUnit.seconds,
                                        digitType: DigitType.first,
                                        countUp: countUp,
                                        style: kNormalTextStyle.copyWith(color: kPureWhiteColor, fontWeight: FontWeight.w500),
                                      ),
                                      RawDigitItem(
                                        duration: duration,
                                        timeUnit: TimeUnit.seconds,
                                        digitType: DigitType.second,
                                        countUp: countUp,
                                        style: kNormalTextStyle.copyWith(color: kPureWhiteColor, fontWeight: FontWeight.w500),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      );
                    },
                  ),
                  Text('$dueStatement: ${DateFormat('hh:mm a').format(dueDate)}',
                    style: TextStyle(fontSize: 16.0, fontWeight: FontWeight.bold),

                  ),


                ]
            ),
          kLargeHeightSpacing,
          Text(
            orderDetails,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 20.0),
          ),

        ],
      ),
    );
  }

  DateTime? _findDateMatchingToday(List dates) {
    for (var date in dates) {
      if (date.year == DateTime.now().year &&
          date.month == DateTime.now().month &&
          date.day == DateTime.now().day) {
        return date;
      }
    }
    return null; // No matching date found
  }
}
