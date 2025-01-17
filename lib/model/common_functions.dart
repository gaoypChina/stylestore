


import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:excel/excel.dart';
import 'package:flutter/cupertino.dart';
import 'package:http/http.dart' as http;
import 'package:audioplayers/audioplayers.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:contacts_service/contacts_service.dart';
import 'package:cool_alert/cool_alert.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_barcode_scanner/flutter_barcode_scanner.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:internet_connection_checker/internet_connection_checker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import 'package:stylestore/model/stock_items.dart';
import 'package:stylestore/model/styleapp_data.dart';
import 'package:stylestore/screens/customer_pages/search_customer.dart';
import 'package:stylestore/widgets/ignore_ingredients_widget.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;


import '../Utilities/constants/color_constants.dart';
import '../Utilities/constants/font_constants.dart';
import '../main.dart';
import '../screens/Messages/bulk_message.dart';
import '../screens/Messages/message.dart';
import '../screens/customer_pages/customer_data.dart';
import '../screens/customer_pages/sync_customer.dart';
import '../screens/payment_pages/pos_summary.dart';
import 'package:flutter/material.dart';

import '../screens/products_pages/stock_items.dart';
import '../screens/sign_in_options/sign_in_page.dart';
import '../screens/store_setup.dart';
import '../utilities/constants/user_constants.dart';
// import '../widgets/employee_checklist.dart';
import '../widgets/debtors_widget.dart';
import '../widgets/employee_checklist.dart';
import '../widgets/subscription_ended_widget.dart';
import '../widgets/success_hi_five.dart';
import 'beautician_data.dart';

// import 'dart:html' as html;

import 'excel_model.dart';

class CommonFunctions {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  var formatter = NumberFormat('#,###');
  final auth = FirebaseAuth.instance;
  final AudioPlayer _audioPlayer = AudioPlayer();
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  CollectionReference testingTesting = FirebaseFirestore.instance.collection('testing');
  CollectionReference users = FirebaseFirestore.instance.collection('medics');
  CollectionReference attendanceCollection = FirebaseFirestore.instance.collection('attendance');

  // final HttpsCallable callableSmsTransaction = FirebaseFunctions.instance.httpsCallable('updateAiSMS');
  final HttpsCallable callableSmsCustomer = FirebaseFunctions.instance.httpsCallable('smsCustomer');

  // CollectionReference appointments = FirebaseFirestore.instance.collection('testing');
  AndroidNotificationChannel channel = const AndroidNotificationChannel(
      'high_importance_channel',
      'High Importance Notifications',
      // 'This channel is used for important Notifications',
      importance: Importance.high,
      playSound: true
  );

  void showChecklistToBeDoneDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Checklist", style: kNormalTextStyle.copyWith(color: kBlack, fontWeight: FontWeight.bold),),
          content: EmployeePreChecklist(),
          actions: [
            TextButton(
              child: Text('Cancel'),
              onPressed: () => Navigator.of(context).pop(),
            ),
            ElevatedButton(
              child: Text('Submit', style: kNormalTextStyle.copyWith(color: kPureWhiteColor),),
              onPressed: () async{
                final prefs = await SharedPreferences.getInstance();
                final String? attendanceCode = prefs.getString(kAttendanceCode);
                // Handle submission logic here (e.g., save results)

                uploadChecklistToAttendance(attendanceCode!, context);

                Navigator.of(context).pop();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: kAppPinkColor, // Set background color to red
              ),
            ),
          ],
        );
      },
    );
  }

  Future<List<AllCustomerData>> retrieveCustomerData(context) async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('customers')
          .where('storeId', isEqualTo: Provider.of<StyleProvider>(context, listen: false).beauticianId)
          .orderBy('name', descending: false)
          .get();

      final customerDataList = snapshot.docs
          .map((doc) => AllCustomerData.fromFirestore(doc))
          .toList();

      return customerDataList;
    } catch (error) {
      print('Error retrieving employee data: $error');
      return []; // Return an empty list if an error occurs
    }
  }

  Future<List<AllStockData>> retrieveStockData(context) async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('stores')
          .where('storeId', isEqualTo: Provider.of<StyleProvider>(context, listen: false).beauticianId)
          .orderBy('name', descending: false)
          .get();

      final stockDataList = snapshot.docs
          .map((doc) => AllStockData.fromFirestore(doc))
          .toList();

      return stockDataList;
    } catch (error) {
      print('Error retrieving stock data: $error');
      return []; // Return an empty list if an error occurs
    }
  }

  void showDebtorsDialog(BuildContext context, Map<String, bool> list) {
    Provider.of<StyleProvider>(context, listen: false).changeDebtorChecklistValues(list);
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Send Reminders To:",textAlign: TextAlign.center, style: kNormalTextStyle.copyWith(color: kBlack, fontWeight: FontWeight.bold),),
          content: DebtorsChecklist (checklistItems: list,),
          actions: [
            TextButton(
              child: Text('Cancel'),
              onPressed: () => Navigator.of(context).pop(),
            ),
            ElevatedButton(
              child: Text('Send Selected', style: kNormalTextStyle.copyWith(color: kPureWhiteColor),),
              onPressed: () async{
                final prefs = await SharedPreferences.getInstance();
                String storeName = prefs.getString(kBusinessNameConstant)??"";
                // This code gets the number from the seleceted names that are given
                List numbers = findPhonesForSelectedNames(Provider.of<StyleProvider>(context, listen: false).debtorsChecklist,Provider.of<StyleProvider>(context, listen: false).businessCustomers);
                // This code gets the names from the selected names that are given
                List names = findFullNamesForSelectedNames(Provider.of<StyleProvider>(context, listen: false).debtorsChecklist,Provider.of<StyleProvider>(context, listen: false).businessCustomers);

                Provider.of<StyleProvider>(context, listen: false).clearBulkSmsList();
                Navigator.pop(context);
                Navigator.pop(context);

                Provider.of<StyleProvider>(context, listen:false).addNormalContactToSmsList(numbers,names );


                Provider.of<BeauticianData>(context, listen: false).setTextMessage("Dear Customer! Please note that you have an outstanding invoice with $storeName. We appreciate having your account brought to zero.");
                showModalBottomSheet(
                    isScrollControlled: true,
                    context: context,
                    builder: (context) {
                      return const Scaffold(
                          body: BulkSmsPage());
                    });
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: kAppPinkColor, // Set background color to red
              ),
            ),
          ],
        );
      },
    );
  }

  void showIngredientsDialog(BuildContext context, Map<String, bool> list) {
    Provider.of<StyleProvider>(context, listen: false).changeDebtorChecklistValues(list);
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Select Items to Ignore:",textAlign: TextAlign.center, style: kNormalTextStyle.copyWith(color: kBlack, fontWeight: FontWeight.bold),),
          content: IngredientsChecklist (ingredientsListItems: list),
          actions: [
            TextButton(
              child: Text('Cancel'),
              onPressed: () => Navigator.of(context).pop(),
            ),
            ElevatedButton(
              child: Text('Change Selected', style: kNormalTextStyle.copyWith(color: kPureWhiteColor),),
              onPressed: () async{
                final prefs = await SharedPreferences.getInstance();
                String storeName = prefs.getString(kBusinessNameConstant)??"";
                // This code gets the number from the seleceted names that are given
                List id = findDocumentIdForSelectedIngredients(Provider.of<StyleProvider>(context, listen: false).ingredientsChecklist,Provider.of<StyleProvider>(context, listen: false).storeIngredients);
                List names = findNamesForSelectedIngredients(Provider.of<StyleProvider>(context, listen: false).ingredientsChecklist,Provider.of<StyleProvider>(context, listen: false).storeIngredients);
                // Navigator.pop(context);
                if(names.length == 0){

                }else {
                  showIgnoreNotificationPopup(context, names, id);
                }


              },
              style: ElevatedButton.styleFrom(
                backgroundColor: kAppPinkColor, // Set background color to red
              ),
            ),
          ],
        );
      },
    );
  }
  List<String> extractNames(String text) {
    // Split the text into lines
    List<String> lines = text.split('\n');

    // Find the starting line of the name list (assuming it has the word 'clients')
    int startIndex = lines.indexWhere((line) => line.toLowerCase().contains('clients'));

    // Extract names starting from the next line
    return lines.sublist(startIndex + 1).map((line) {
      // Remove numbering and trim
      return line.split('.').last.trim();
    }).toList();
  }

  List<String> extractIngredients(String text) {
    // Split the text into lines
    List<String> lines = text.split('\n');

    // Find the starting line of the name list (assuming it has the word 'clients')
    int startIndex = lines.indexWhere((line) => line.toLowerCase().contains('stock'));

    // Extract names starting from the next line
    return lines.sublist(startIndex + 1).map((line) {
      // Remove numbering and trim
      return line.split('.').last.trim();
    }).toList();
  }

  Map<String, bool> createChecklist(List<String> names) {

    return Map.fromIterable(names,
        key: (name) => name,
        value: (name) => true);
  }

  Map<String, bool> createIngredientChecklist(List<String> names) {

    return Map.fromIterable(names,
        key: (name) => name,
        value: (name) => false);
  }


  Future<void> uploadChecklistToAttendance(String documentId, context) async {
    try {


      await attendanceCollection.doc(documentId).update({
        'checklist': Provider.of<StyleProvider>(context, listen: false).employeeChecklist // Assuming '_checklist' is the map in your StyleProvider
      }).whenComplete(() =>
          showSuccessNotification('Checklist Submitted!', context)
      );

      print('Checklist uploaded successfully');
    } catch (e) {
      print('Error uploading checklist: $e');
    }
  }

  List<String> convertTextToPhoneNumbers(String text, context) {
    // Split the text into lines
    List<String> lines = text.split('\n');
    print("Lines: $lines");
    for(var i =0;i<lines.length;i++){
      if(lines[i]!=""){
        Provider.of<StyleProvider>(context, listen: false).addBulkSmsList(lines[i], "");
      }
    }
    return lines;
  }

  String formatPhoneNumber(String number, countryCode) {

    // Remove leading "0" if present
    if (number.startsWith("0")) {
      number = number.substring(1);
    }
    // Remove leading "+256" if present
    if (number.startsWith(countryCode)) {
      number = number.substring(countryCode.length);
    }
    return number;
  }

  String getFirstWord(String sentence) {
    if (sentence.isNotEmpty) {
      List<String> words = sentence.split(' ');
      return words[0];
    }
    return "";
  }

  Future<bool> showIgnoreNotificationPopup(BuildContext context, List items, List id) async {
    final shouldIgnore = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Ignore Notifications',textAlign: TextAlign.center, style: kNormalTextStyle.copyWith(color: kBlack, fontWeight: FontWeight.bold),),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          // Avoid potential scrolling
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Text('Would you like to turn off notifications for:'),
            for (var item in items)

              Text(item, style: kNormalTextStyle.copyWith(fontWeight: FontWeight.bold, color: kBlack),),

          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel'),
          ),
          TextButton(
            style: ButtonStyle(
              backgroundColor: convertToMaterialStateProperty(kAppPinkColor)
            ),
            onPressed: (){

              updateIgnoreToServer(id, items, context);
              },
            child: Text('Turn Off Notifications', style: kNormalTextStyle.copyWith(color: kPureWhiteColor),),
          ),
        ],
      ),
    );
    return shouldIgnore ?? false;
  }

  Future<void> updateIgnoreToServer(List ids,List names, context) async {
    final firestore = FirebaseFirestore.instance;
    final collection = firestore.collection('stores'); // Replace with your collection name
    final batch = FirebaseFirestore.instance.batch(); // Use named constructor
    for (var id in ids) {
      batch.update(collection.doc(id), {'ignore': true});
    }
    await batch.commit().whenComplete(() {
      showSuccessNotification("Items successfully set to ignored", context);
    });
    Navigator.pop(context);
    Navigator.pop(context);
    Navigator.pop(context);
    var message = "Attention Crew, there has been an update...\n";

    if (names.isEmpty) {
      message += message;
    } else {
      message += "The following items have been removed from notifications: ";
      for (var i = 0; i < ids.length; i++) {
        message += "${names[i]}${i == names.length - 1 ? '.' : ', '} ";
      }
    }
    createChatDocument(message, "normal");

  }

  Future<void> createChatDocument(String message,  String status) async {
    final prefs = await SharedPreferences.getInstance(); 
    final firestore = FirebaseFirestore.instance;
    final collection = firestore.collection('chat');
    final documentId = collection.doc().id; // Generate a unique ID
    final currentTime = Timestamp.now();


    try {
      await collection.doc(documentId).set({
        'id': documentId,
        'message': "", // Empty message since this represents a response
        'replied': true,
        'response': message,
        'time': currentTime,
        'visible': true,
        'status': status,
        'userId': prefs.getString(kStoreIdConstant),
      });
      print("Chat document created successfully");
    } catch (error) {
      print("Error creating chat document: $error");
    }
  }

  String removeLeadingTrailingSpaces(String text) {
    return text.trim();
  }

  // Define the function to find phones for given names
// Define the function to find phones for selected names
  List<String> findPhonesForSelectedNames(Map<String, bool> nameMap, List<AllCustomerData> customerData) {
    List<String> selectedNames = [];

    // Iterate through nameMap to collect selected names
    nameMap.forEach((name, isSelected) {
      if (isSelected) {
        selectedNames.add(name);
      }
    });

    // Filter customerData to find corresponding phone numbers for selected names
    List<String> phones = [];
    for (String name in selectedNames) {
      for (AllCustomerData customer in customerData) {
        if (customer.fullNames == name) {
          // print(customer.fullNames);
          phones.add(customer.phone);
          break; // Stop searching for this name once a match is found
        }
      }
    }
    // print(phones);
    return phones;
  }

  List<String> findFullNamesForSelectedNames(Map<String, bool> nameMap, List<AllCustomerData> customerData) {
    List<String> selectedNames = [];

    // Iterate through nameMap to collect selected names
    nameMap.forEach((name, isSelected) {
      if (isSelected) {
        selectedNames.add(name);
      }
    });

    // Filter customerData to find corresponding phone numbers for selected names
    List<String> fullNames = [];
    for (String name in selectedNames) {
      for (AllCustomerData customer in customerData) {
        if (customer.fullNames == name) {
          // print(customer.fullNames);
          fullNames.add(customer.fullNames);
          break; // Stop searching for this name once a match is found
        }
      }
    }
    // print(fullNames);
    return fullNames;
  }

  List<String> findDocumentIdForSelectedIngredients(Map<String, bool> nameMap, List<AllStockData> storeData) {
    List<String> selectedNames = [];

    // Iterate through nameMap to collect selected names
    nameMap.forEach((name, isSelected) {
      if (isSelected) {
        selectedNames.add(name);
      }
    });

    // Filter customerData to find corresponding phone numbers for selected names
    List<String> id = [];
    for (String name in selectedNames) {
      for (AllStockData ingredients in storeData) {
        if (ingredients.name == name) {
          // print(ingredients.fullNames);
          id.add(ingredients.documentId);
          break; // Stop searching for this name once a match is found
        }
      }
    }
    // print(id);
    return id;
  }

  List<String> findNamesForSelectedIngredients(Map<String, bool> nameMap, List<AllStockData> storeData) {
    List<String> selectedNames = [];

    // Iterate through nameMap to collect selected names
    nameMap.forEach((name, isSelected) {
      if (isSelected) {
        selectedNames.add(name);
      }
    });

    // Filter customerData to find corresponding phone numbers for selected names
    List<String> names = [];

    for (String name in selectedNames) {
      for (AllStockData ingredients in storeData) {
        if (ingredients.name == name) {
          // print(ingredients.fullNames);
          names.add(ingredients.name);
          break; // Stop searching for this name once a match is found
        }
      }
    }
    // print(names);
    return names;
  }

  showSuccessNotification (message, context){
    // snackbar to show success message at the top of the screen
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: kGreenThemeColor,
        content: Text(message, style: kNormalTextStyle.copyWith(color: kPureWhiteColor),),
        duration: Duration(seconds: 3),
      ),
    );
  }

  showFailureNotification (message, context){
    // snackbar to show success message at the top of the screen
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: kRedColor,
        content: Text(message, style: kNormalTextStyle.copyWith(color: kPureWhiteColor),),
        duration: Duration(seconds: 3),
      ),
    );
  }
  List<String> processPhoneNumbers(List<String> phoneNumbers) {
    List<String> processedNumbers = [];

    for (String number in phoneNumbers) {
      String cleanNumber = number.replaceAll(" ", "");

      if (cleanNumber.isEmpty) {
        continue;
      }

      // Check and fix numbers starting with "+256"
      if (cleanNumber.startsWith("+256")) {
        cleanNumber = cleanNumber.substring(4); // Remove the leading "+256"
      }
      if (cleanNumber.startsWith("256")) {
        cleanNumber = cleanNumber.substring(3); // Remove the leading "+256"
      }


      // Standardize remaining formats
      if (cleanNumber.startsWith("0")) {
        cleanNumber = "256" + cleanNumber.substring(1);
      } else {
        cleanNumber = "256" + cleanNumber;
      }

      processedNumbers.add(cleanNumber);
    }

    return processedNumbers;
  }

  int differenceInDays(DateTime startDate, DateTime endDate) {
    // Calculate the difference between endDate and startDate
    Duration difference = endDate.difference(startDate);
    return difference.inDays.abs(); // Use abs() to ensure positive result
  }

// This removes duplicates from Lists
  List removeDuplicates(List originalList) {
    return originalList.toSet().toList();
  }

  // Sign out of work
  Future<void> signOutUser (context,bool forced)async {
    final prefs = await SharedPreferences.getInstance();
    final dateNow = new DateTime.now();
    showDialog(context: context, builder: ( context) {
      return Center(
          child:
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(color: kAppPinkColor,),
              kSmallHeightSpacing,
              DefaultTextStyle(
                style: kNormalTextStyle.copyWith(color: kPureWhiteColor),
                child: Text("Signing out of Work"),
              ),
            ],
          ));
    }
    );
    String? orderId = prefs.getString(kAttendanceCode);
    try {
      await FirebaseFirestore.instance
          .collection('attendance')
          .doc(orderId)
          .update({
        'signOut': dateNow,
        'forced'  : forced

      }); // Await this update

      // Success - now safe to modify the UI
      Navigator.pop(context);
      Navigator.pushNamed(context, SignInUserPage.id);
      CommonFunctions().updateEmployeeSignInAndOutDoc(false);
      prefs.setBool(kIsCheckedIn, false);

    } catch (error) {
      print("THE ERRROORRR goes like this:**** $error *****");
      Navigator.pop(context); // Close the loading dialog

      // Display error using ScaffoldMessenger
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('An error occurred during sign out. Please try again.'),
        backgroundColor: Colors.red, // Adjust as needed
      ));
    }
  }

  void showConfirmationToSendMessageToDialog(BuildContext context, Function() onSendPressed, List numbersToSend) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Center(child: Text('Send SMS Notification?',textAlign: TextAlign.center, style: kNormalTextStyle.copyWith(color: kBlack, fontSize: 14, fontWeight: FontWeight.bold),)),
          content: Text(
              'Would you want to send an SMS notification to the users\nassigned to this task?', textAlign: TextAlign.center, style: kNormalTextStyle.copyWith(color: kBlack),),
          actions: [
            TextButton(
              child: const Text('Cancel'),
              onPressed: () => Navigator.of(context).pop(),

            ),
            TextButton(
              onPressed: () {
                // onSendPressed(); // Call the notification function
                Provider.of<StyleProvider>(context, listen: false).clearBulkSmsList();
                Provider.of<StyleProvider>(context, listen:false).addNormalContactToSmsList(CommonFunctions().removeDuplicates(numbersToSend), CommonFunctions().removeDuplicates(numbersToSend));
                Provider.of<BeauticianData>(context, listen: false).setTextMessage("Hey, a new task has been created for you, Check it out.");

                showModalBottomSheet(context: context,
                    isScrollControlled: true,
                    builder:
                        (context) {return Scaffold(
                        appBar:
                        AppBar(
                          automaticallyImplyLeading: false,
                          elevation: 0,
                          backgroundColor:
                          kPureWhiteColor,
                        ),
                        body:
                        BulkSmsPage());
                    });
                // Navigator.of(context).pop();
              },
              style: TextButton.styleFrom(backgroundColor: kAppPinkColor),
              child: Text('Send', style: kNormalTextStyle.copyWith(color: kPureWhiteColor),),
            ),
          ],
        );
      },
    );
  }

  void checkPeriodAndSignOut(BuildContext context, DateTime givenDate) {
    // Calculate 8 hours from now
    final DateTime eightHoursFromNow = givenDate.add(const Duration(hours: 8));

    // Compare the given date
    if (DateTime.now().isAfter(eightHoursFromNow)) {
      // Navigate to sign-in page (Use the appropriate navigation for your app)
      showSuccessNotification('Automatic Sign out!', context);
      signOutUser(context, true);
    }else{

    }
  }
  Future<void> decreaseBillAmount(String uid,double amountValue, context) async {
    showDialog(context: context, builder: ( context) {return const Center(child: CircularProgressIndicator(
      color: kAppPinkColor,));});
    CollectionReference<Map<String, dynamic>> usersCollection =
    FirebaseFirestore.instance.collection('appointments');

    DocumentReference<Map<String, dynamic>> transactionDoc = usersCollection.doc(uid);

    await FirebaseFirestore.instance.runTransaction((transaction) async {
      DocumentSnapshot<Map<String, dynamic>> snapshot =
      await transaction.get(transactionDoc);

      if (snapshot.exists) {
        double currentAmount = snapshot.data()!['paidAmount'].toDouble() ?? 0;

        double updatedAmount = currentAmount + amountValue;
        String updateRecord ="${amountValue.toString()}?${Provider.of<StyleProvider>(context, listen: false).paymentMethod}:${DateTime.now()}";
        transaction.update(transactionDoc, {
          'paidAmount': updatedAmount,
          'paymentHistory':  FieldValue.arrayUnion([updateRecord]),
          'paymentMethod': Provider.of<StyleProvider>(context, listen: false).paymentMethod

        }

        );
      }
    }).whenComplete(() {
      Provider.of<BeauticianData>(context, listen: false).setLottieImage( 'images/Hi5.json', "Transaction Updated");
      Navigator.pop(context);
      Navigator.pop(context);
      Navigator.pop(context);
      Navigator.pushNamed(context, SuccessPageHiFive.id);
    });
  }

  String generateUniqueID(String name) {
    // Extract initials from the user's name
    final initials = name
        .split(' ')
        .map((word) => word.isNotEmpty ? word[0].toUpperCase() : '')
        .join('');

    // Get current date components
    // Generate a random number between 1 and 100
    final random = Random();
    final randomNumber = random.nextInt(100) + 1;
    final now = DateTime.now();
    final year = DateFormat('yyyy').format(now);
    final month = DateFormat('MM').format(now);
    final day = DateFormat('dd').format(now);

    // Concatenate the components to form the unique ID
    final uniqueID = '${initials}${year}${month}${day}-$randomNumber';

    return uniqueID;
  }

  List separateElements(List elements, currency) {
    List formattedElements = [];
    for (String element in elements) {
      List parts = element.split("?");
      double amount = double.parse(parts[0]);
      String paymentMethod = parts[1].split(":")[0];
      String dateString = parts[1].split(":")[1];
      DateTime date = DateFormat("yyyy-MM-dd").parse(dateString);

      formattedElements.add("${DateFormat.yMMMd().format(date)}\n$currency ${formatter.format(amount)} via $paymentMethod");
    }
    return formattedElements;
  }

  // Sync contacts from the phone
  static Future<void> syncContacts(context,int iterations) async {
    showDialog(context: context, builder: ( context) {return Center(
          child:
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(color: kAppPinkColor,),
              kSmallHeightSpacing,
              DefaultTextStyle(
                style: kNormalTextStyle.copyWith(color: kPureWhiteColor),
                child: Text("Loading Contacts\nThis may take a few seconds.", textAlign: TextAlign.center,),
              )
              // Text("Loading Contacts", style: kNormalTextStyle.copyWith(color: kPureWhiteColor),)
            ],
          ));});

      var contacts = await Future<Iterable<Contact>>(_fetchContacts);
    Provider.of<StyleProvider>(context, listen: false).setSyncedCustomers(contacts);
      if(iterations < 1){
        // Navigator.pop(context);
        Navigator.pop(context);
      } else {
        Navigator.pop(context);
        Navigator.pop(context);
      }

      showModalBottomSheet(
          isScrollControlled: true,
          context: context,
          builder: (context) {
            return SyncCustomersPage();

          });
  }

  // The function to fetch contacts
  static Future<Iterable<Contact>> _fetchContacts() async {
    Iterable<Contact> contacts = await ContactsService.getContacts();
    return contacts;
  }

  Future<dynamic> alertDialogueError(context) {
    return showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error, color: kAppPinkColor,),
              kMediumWidthSpacing,
              Text('Enter all Details', style: kHeading2TextStyle.copyWith(fontWeight: FontWeight.bold),),
            ],
          ),
          content: Text('Ooops looks like something is missing'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context), // Dismisses the dialog
              child: Text('Cancel'),
            ),
          ],
        ));
  }


  Future<void> _configureLocalTimeZone() async {
    tz.initializeTimeZones();
    final String timeZone = 'Africa/Kampala';
    //await FlutterNativeTimezone.getLocalTimezone();
    tz.setLocalLocation(tz.getLocation(timeZone));
  }
  initializeNotification() async {
    _configureLocalTimeZone();
    const

    DarwinInitializationSettings initializationSettingsIOS = DarwinInitializationSettings();

    const AndroidInitializationSettings initializationSettingsAndroid =
    AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings initializationSettings = InitializationSettings(
      iOS: initializationSettingsIOS,
      android: initializationSettingsAndroid,
    );
    await flutterLocalNotificationsPlugin.initialize(initializationSettings);
  }
  scheduledNotification({
    required String heading,
    required String body,
    required int year,required int month,required int day, required int hour, required int minutes, required int id}) async {

    initializeNotification();
    tz.TZDateTime _convertTime(int year, int month, int day, int hour, int minutes) {
      final tz.TZDateTime now = tz.TZDateTime.now(tz.local);
      tz.TZDateTime scheduleDate = tz.TZDateTime(
        tz.local,
        year,
        month,
        day,
        hour,
        minutes,
      );
      // if (scheduleDate.isBefore(now)) {
      //   scheduleDate = scheduleDate.add(const Duration(days: 1));
      // }
      return scheduleDate;
    }

    await flutterLocalNotificationsPlugin.zonedSchedule(id, heading, body,
      _convertTime(year, month, day, hour, minutes),
      NotificationDetails(
        android: AndroidNotificationDetails(
          "$id",
          '$heading',
          sound: RawResourceAndroidNotificationSound('notification'),
          channelDescription: 'your channel description',
          importance: Importance.max,
          priority: Priority.high,
          //  sound: RawResourceAndroidNotificationSound(sound),
        ),
        iOS: DarwinNotificationDetails(sound: 'default')
        // IOSNotificationDetails(sound:'default'),
      ),
      androidAllowWhileIdle: true,
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
      // payload: 'It could be anything you pass',
    );
    print("Scheduled message $heading for $year-$month-$day $hour:$minutes with id: $id");
  }



  void showNotification(String notificationTitle, String notificationBody){
    flutterLocalNotificationsPlugin.show(0, notificationTitle, notificationBody,
        NotificationDetails(
            android: AndroidNotificationDetails(
              channel.id,
              channel.name,
              // channel.description,
              importance: Importance.high,
              // sound: RawResourceAndroidNotificationSound('notification'),
              color: Colors.green,
              playSound: true,
              icon: '@mipmap/ic_launcher',
            ),
            iOS: DarwinNotificationDetails(
                presentAlert: true,
                presentBadge: true,
                presentSound: true,
                subtitle: channel.description

            )
        ));

  }
  // This function signs out the User
  Map<String, dynamic> permissionsMap = {};


  void removeNotificationsIfAdmin()async{
    permissionsMap = await CommonFunctions().convertPermissionsJson();
    final prefs = await SharedPreferences.getInstance();
    String token = prefs.getString(kToken)!;
    String documentId = prefs.getString(kStoreIdConstant)!;

    if (permissionsMap['admin'] == true) {
      FirebaseFirestore.instance.collection('medics').doc(documentId)
          .update({
        'adminTokens': FieldValue.arrayRemove([token]),
      });
    } else {
      print("THIS IS NOT AN ADMIN");
    }
  }

  Future <String> startBarcodeScan(context, String productId, name) async {
    // isScanning = true;
    // while(isScanning) {
    //   isScanning = false;

      String barcodeScanRes = await FlutterBarcodeScanner.scanBarcode(
        "#FF0000", // Custom red color for the scanner
        "Cancel", // Button text for cancelling the scan
        true, // Show flash icon
        ScanMode.BARCODE, // Specify the scan mode (BARCODE, QR)
      );

      if (barcodeScanRes != '-1') {
        playBeepSound();
        ScaffoldMessenger.of(context).showSnackBar( SnackBar(content: Text('Successfully attached to $name')));
        return barcodeScanRes;
      } else {
        return productId;
      }

    // }
  }

  Future<void> signOut() async {
    removeNotificationsIfAdmin();
    await auth.signOut();

    final prefs = await SharedPreferences.getInstance();
    prefs.setBool(kIsLoggedInConstant, false);
    prefs.setBool(kIsFirstTimeUser, true);
  }
  // Animation Timer
  animationTimer(context) {
    Timer(const Duration(milliseconds: 300), () {
      Navigator.pop(context);
      // Navigator.pop(context);
    });
  }

  String smsValue (business, businessNumber, customerName, countryCode) {


    businessNumber = '$countryCode${formatPhoneNumber(businessNumber, countryCode)}';
    var sms = '{"thankyou": "Dear $customerName, Thank you for choosing $business! We appreciate your business. For any assistance, please call $businessNumber.","reminder": "Dear $customerName, kindly make payment for your outstanding purchase with $business. For any assistance, please call $businessNumber.","options": ["We value your business $customerName! Thank you for choosing $business. For any assistance, please call $businessNumber.","Thank you for your support $customerName! $business is here to serve you. For any assistance, please call $businessNumber.","Your order is on its way $customerName! Thank you for choosing $business. For any assistance, please call $businessNumber.","We appreciate your trust in $business! For any assistance, please call $businessNumber."]}';
 return sms;
  }

  String smsJustPaid (business, businessNumber, customerName, countryCode){
    businessNumber = '$countryCode${formatPhoneNumber(businessNumber, countryCode)}';
    var sms = '{"thankyou": "Dear $customerName, Your order has been received. Thank you for choosing $business! For any assistance, contact us on $businessNumber.","reminder": "Dear $customerName, kindly make payment for your outstanding purchase with $business. For any assistance, please call $businessNumber.","options": ["We value your business $customerName! Thank you for choosing $business. For any assistance, reach out on $businessNumber.","Your Order is ready. $customerName! Thank you for your support, $business is here to serve you. For any assistance, contact us on $businessNumber.","Your order is on its way $customerName! Thank you for choosing $business. For any assistance, reach out on $businessNumber.","We appreciate your trust in $business! For any assistance, call $businessNumber."]}';
    return sms;
  }

  Future<void> reduceSmsBalance(double deductionAmount) async {
    print("WE STARTED HERE");
    final prefs = await SharedPreferences.getInstance();
    var docId = prefs.getString(kStoreIdConstant);
    print("The STORE ID is : $docId");
    try {
      FirebaseFirestore firestore = FirebaseFirestore.instance;
      CollectionReference storesCollection = firestore.collection('medics');
      DocumentReference storeRef = storesCollection.doc(docId);

      await storeRef.update({
        'sms': FieldValue.increment(-deductionAmount)
      });

      print('SMS balance updated successfully');
    } on FirebaseException catch (e) {
      print('Error updating SMS balance: ${e.message}');

    }
  }

  void sendCustomerSms(message, number, context) async {
    dynamic serverCallableVariable = await callableSmsCustomer.call(<String, dynamic>{
      "message" : message,
      "number" : number,

    }).catchError((error){
    }).whenComplete(() {
      Provider.of<BeauticianData>(context, listen: false).setLottieImage( 'images/message.json', "Message Sent");
      //  Navigator.pop(context);
      // Navigator.pop(context);
      Navigator.pushNamed(context, SuccessPageHiFive.id);
    });
  }

  CollectionReference messagesCollection = FirebaseFirestore.instance.collection('sms');
  Future<void> uploadMessageToServer (context, String phoneNumber, bool isBulk, List numbers, double cost )async {
    showDialog(context: context, builder:
        ( context) {
      return const Center(child: CircularProgressIndicator(
        color: kAppPinkColor,
      ));
    });

    final prefs =  await SharedPreferences.getInstance();
    var providerData = Provider.of<StyleProvider>(context, listen: false);
    var beauticianDataListen = Provider.of<BeauticianData>(context, listen: false);
    var id = "sms_${CommonFunctions().generateUniqueID(prefs.getString(kBusinessNameConstant)!)}";
    return messagesCollection.doc(id)
        .set({
      'status': true,
      'client': providerData.invoicedCustomer,
      'clientPhone': phoneNumber, // John Doe
      'message': beauticianDataListen.textMessage,
      'sender_id': prefs.getString(kStoreIdConstant),
      'isBulk': isBulk,
      'numbers' : numbers,
      'date': DateTime.now(),
      'sender':  prefs.getString(kLoginPersonName),
      'id': id,
      'cost': cost,
      'delivery': false

    }).then((value) {
      print("WOOOOOOOWWEEE THIS RUN");
      reduceSmsBalance(cost);
      Navigator.pop(context);
      Navigator.pop(context);
      // Navigator.pushNamed(context, SuccessPageHiFive.id);

    } ).catchError((error) {
      print(error);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Check your Internet Connection')));

      Navigator.pop(context);

    } );
  }

  int convertDatesToString(List dateList) {
    // Create a DateFormat object to define the output format
    final DateFormat formatter = DateFormat('dd,MM,yyyy');
    var today = formatter.format(DateTime.now());
    var datesInString = dateList.map((date) => formatter.format(date)).toList();


    // Convert each DateTime to a string and return the list
    return datesInString.indexWhere((date) => date == today);
  }

  String getDateSeparator(DateTime date) {
    if (date.difference(DateTime.now()).inDays == 0) {
      return 'Today';
    } else if (date.difference(DateTime.now()).inDays == -1) {
      return 'Yesterday';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }

  void sendBulkSms(List<String> processedNumbers, String message, String senderId, String priority) async {
    try {
      // Dummy Message Data - Adjust for your actual use case
      List<Map<String, String>> messageData = [];

      for (String number in processedNumbers) {
        messageData.add({
          'number': number,
          'message': message,
          'senderid': senderId,
          'priority': priority
        });
      }

      final HttpsCallable bulkSmsCallable = FirebaseFunctions.instance.httpsCallable(
        'sendBulkSmsToCustomer',
      );

      final results = await bulkSmsCallable.call(<String, dynamic>{
        'messageData': messageData,
      });
      print(messageData);

      print('SMS Response: $results'); // Log the API response

    } on FirebaseFunctionsException catch (e) {
      print('Caught FirebaseFunctionsException: $e');
    } catch (e) {
      print('Other Error occurred: $e');
    }
  }

  double getHighestValue(List array) {
    if (array.isEmpty) {
      throw Exception("The array is empty.");
    }

    double highestValue = array[0];
    for (int i = 1; i < array.length; i++) {
      if (array[i] > highestValue) {
        highestValue = array[i];
      }
    }
    return highestValue;
  }

  //This gets the phone User  token of the user
  String getUserTokenOfPhone (){
    var token = '';
    _firebaseMessaging.getToken().then((value) => token = value!);
    return token;
  }

  Future<void> triggerSendEmail({
    required String name,
    required String emailAddress,
    required String subject,
  }) async {
    try {
      // Get reference to callable Cloud Function
      final callable = FirebaseFunctions.instance.httpsCallable('sendEmail');

      // Call the Cloud Function with the data
      final response = await callable({
        'name': name,
        'emailAddress': emailAddress,
        'subject': subject,
      });

      // Extract the result from the response
      final result = response.data as String;
      print(result);
    } on FirebaseFunctionsException catch (e) {
      print('Error triggering Cloud Function: ${e.code} - ${e.message}');
    }
  }

  Future<void> addCustomer( nameOfCustomer, phoneNumberOfCustomer, context, customerId) async{
    CollectionReference customerProvided = FirebaseFirestore.instance.collection('customers');
    final prefs = await SharedPreferences.getInstance();
    String account = prefs.getString(kLoginPersonName) ?? "";
    String location = prefs.getString(kLocationConstant) ?? "";
    Map<String, String> optionsToUpload = {
      'Joined': '${DateFormat('EE, dd, MMM, hh:mm a').format(DateTime.now())}',
    };

    showDialog(context: context, builder: ( context) {return const Center(child: CircularProgressIndicator(
      color: kAppPinkColor,));});
    // Call the user's CollectionReference to add a new user
    return customerProvided.doc(customerId)
        .set({
      'id':customerId,
      'image':  "https://mcusercontent.com/f78a91485e657cda2c219f659/images/db929836-bf22-1b6d-9c82-e63932ac1fd2.png",
      'active': true,
      'phoneNumber': phoneNumberOfCustomer,
      'location': location,
      'category': 'main',
      'hasOptions': true,
      'info': "",
      'name':  removeLeadingTrailingSpaces(nameOfCustomer),
      'updateBy': account,
      'options':  optionsToUpload,
      'storeId': prefs.getString(kStoreIdConstant),
    })
        .then((value) {

      Navigator.pop(context);
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar( SnackBar(content: Text('${nameOfCustomer??""} Created')));
    })
        .catchError((error) {
      ScaffoldMessenger.of(context).showSnackBar( SnackBar(content: Text('Error creating Customer')));
    });
  }

  Future<Uint8List> fetchLogoBytes(String imageUrl) async {
    final response = await http.get(Uri.parse(imageUrl));
    if (response.statusCode == 200) {

      final Uint8List bytes = response.bodyBytes;
      final String dir = (await getTemporaryDirectory()).path;
      final String path = '$dir/logo.png';
      File(path).writeAsBytesSync(bytes);
      return bytes;
    }
    throw Exception('Failed to fetch logo image');
  }

  Future<dynamic> AlertPopUpDialogueMain(BuildContext context,
      {
        required String imagePath, required String text, required String title, String cancelButtonText = "Cancel",


      }) {
    return CoolAlert.show(
        width: MediaQuery.of(context).size.width > 600 ? 400 : MediaQuery.of(context).size.width * 0.8,
        lottieAsset: imagePath,
        context: context,
        type: CoolAlertType.success,
        text: text,
        title: title,
        confirmBtnText: 'Add',
        cancelBtnText: cancelButtonText,
        showCancelBtn: true,
        confirmBtnColor: Colors.green,
        backgroundColor: kBlueDarkColor,
        onConfirmBtnTap: (){
          Navigator.pop(context);
        }
    );
  }
  // This function uploads the user token to the server
  Future<dynamic> AlertPopUpCustomers(BuildContext context,
      {
        required String imagePath,
        required String text,
        required String title,
        String cancelButtonText = "Cancel",
        required List<Stock> selectedStocks,
        required String currency,

      }) {
    return CoolAlert.show(
        width: MediaQuery.of(context).size.width > 600 ? 400 : MediaQuery.of(context).size.width * 0.8,
        lottieAsset: imagePath,
        context: context,
        type: CoolAlertType.success,
        text: text,
        title: title,
        confirmBtnText: 'Add',
        cancelBtnText: cancelButtonText,
        showCancelBtn: true,
        confirmBtnColor: Colors.green,
        backgroundColor: kBlueDarkColor,
        onCancelBtnTap: (){
          Provider.of<StyleProvider>(context, listen: false).clearSelectedStockItems();
          Provider.of<StyleProvider>(context, listen: false).setSelectedStockItems(selectedStocks);
          Navigator.pop(context);
          Provider.of<StyleProvider>(context, listen: false).setCustomerNameOnly("Customer");
          showModalBottomSheet(
              context: context,
              builder: (context) {
                return PosSummary(currency: currency,);
              });
        },
        onConfirmBtnTap: (){
          Navigator.pop(context);
          // Navigator.pushNamed(context, CustomerSearchPage.id);

          showModalBottomSheet(
              isScrollControlled: true,
              context: context,
              builder: (context) {
                return Scaffold(
                    appBar: AppBar(
                      elevation: 0,
                      backgroundColor: kPureWhiteColor,
                      automaticallyImplyLeading: false,
                    ),
                    body: CustomerSearchPage());
              });

        }
    );
  }

  // Method to calculate the total price from the priceList.
  double calculateTotalPrice(List priceList) {
    double total = 0.0;
    var array = []; // Set the total as double.
    for (var price in priceList) {
      array.add(price);
      total += price.toDouble(); // Convert int to double.
    }
    return total;
  }

  // Loading Store defaults
  Future deliveryStream(context) async {
    var prefs = await SharedPreferences.getInstance();
    var id = prefs.getString(kStoreIdConstant)!;
    print("STREAM RUN");

    var start = FirebaseFirestore.instance
        .collection('medics')
        .where('id', isEqualTo: id)
        .snapshots()
        .listen((QuerySnapshot querySnapshot) {
      querySnapshot.docs.forEach((doc) async {
        prefs.setString(kPhoneNumberConstant, doc['phone']);
        prefs.setString(kImageConstant, doc['image']);
        prefs.setDouble(kSmsAmount, doc['sms'].toDouble());
        prefs.setString(kCurrency,  doc['currency']);
        DateTime subscription = doc['subscriptionEndDate'].toDate();
        print("subrip: $subscription");
        prefs.setInt(kSubscriptionEndDate, doc['subscriptionEndDate'].toDate().millisecondsSinceEpoch);
        Provider.of<StyleProvider>(context, listen: false).setAllStoreDefaults(
            doc['active'],
            doc['blackout'],
            doc['clients'],
            doc['close'],
            doc['open'],
            doc['doesMobile'],
            doc['location'],
            doc['modes'],
            doc['phone'],
            doc['name'],
            doc['image'],
            doc['transport'],
            doc['sms'],



        );
      });
    });

    return start;
  }

  String getCurrencyCode(String countryCode, context) {
    String? currencyCode = Provider.of<StyleProvider>(context, listen: false).countryNumbers[countryCode];
    return currencyCode ?? "USD"; // You can change "USD" to any default value or handle the null scenario as needed.
  }

  String capitalizeFirstLetter(String word) {
    if (word.isEmpty) {
      return word;
    }
    return word[0].toUpperCase() + word.substring(1).toLowerCase();
  }

  setupStoreInFirestore(userId, email, ownerName, location, phone, description, name, countryCode, country, currency, context)async{

    var firestore = FirebaseFirestore.instance;
    CircularProgressIndicator(color: kAppPinkColor,);
    await firestore.collection('medics').doc(userId).set({
      'active': true,
      'adminTokens':[],
      'analysis':"",
      'blackout': [],
      'businessPhone':phone,
      'clients': [],
      'close': 20,
      'cord': [0.3142467, 32.6151695],
      'currency':currency,
      'description': description,
      'distance': 3,
      'doesMobile': true,
      'featured': false,
      'id': userId,
      'image': 'https://mcusercontent.com/f78a91485e657cda2c219f659/images/52f30eb6-c476-adfd-3a24-0831ce256da0.jpg',
      'location': location,
      'modes': ['In-Premise', 'Mobile'],
      'newSpeciality': {},
      'open': 7,
      'phone': phone,
      'promote': false,
      'rating': 3.0,
      'reviewNumber': 1,
      'serviceTime': 10,
      'services': [],
      'speciality': [],
      'transport': 5000,
      'email': email,
      'permissions': '{"transactions": true,"expenses": true,"customers": true,"sales": true,"store": true,"analytics": true,"messages": true,"tasks": true,"admin": true,"summary": true,"employees": true,"notifications": true,"signIn": false,"takeStock": true, "qrCode": false}',
      'name': name,
      'ownerName': ownerName,
      'subscriptionEndDate':DateTime.now(),
      'subscriptionStartDate': DateTime.now(),
      'token': 'userTokenGoesHere',
      'countryCode': countryCode,
      'country': country,
      'sms': 500

    }).whenComplete((){
      Navigator.pop(context);
      Navigator.pushNamed(context, StoreSetup.id);
    });
  }



  // Launch Google Maps to webview
  Future<void> openMap(double latitude, double longitude) async {
    String googleUrl = 'https://www.google.com/maps/search/?api=1&query=$latitude,$longitude';

    launchUrl(Uri.parse(googleUrl));
  }

  void callPhoneNumber (String phoneNumber){
    launchUrl(Uri.parse('tel://$phoneNumber'));
  }

  // Function to add elements in an array (list)
  double sumArrayElements(List<double> array) {
    double sum = 0;
    for (double element in array) {
      sum += element;
    }
    return sum;
  }

  MaterialStateProperty<Color> convertToMaterialStateProperty(Color color) {
    return MaterialStateProperty.all(color);
  }

  Future<void> uploadUserToken(token) async {


    final users = await FirebaseFirestore.instance
        .collection('users').doc(auth.currentUser!.uid)
        .update(
        {
          'token': token
        });
  }
// THIS IS CODE FOR STOCKING AND RESTOCKING AND REDUCING STOCK
  Future<void> uploadRestockedItems(selectedStocks, basketToPost, context, docId, currency) async {
    final prefs = await SharedPreferences.getInstance();
    var now = DateTime.now().toIso8601String();
    showDialog(context: context, builder: ( context) {return const Center(child: CircularProgressIndicator(
      color: kAppPinkColor,));});
    // Loop through the selectedStocks list and update the Firestore documents.
    for (var stock in selectedStocks) {
      print("${stock.name}:${stock.id}");

      try {
        await FirebaseFirestore.instance
            .collection('stores')
            .doc(stock.id)
            .get()
            .then((documentSnapshot) {
          // Get the quantity from the document.
          var quantity = documentSnapshot.data()!['quantity'];
          double updateStock = (stock.restock) + quantity;

          // Concatenate the result and the datetime into a string.
          var result = 'R$updateStock?$now';

          // Add the result to an array in the same document.
          FirebaseFirestore.instance.collection('stores').doc(stock.id)
              .update({
            'quantity': FieldValue.increment(stock.restock),
            'stockTaking': FieldValue.arrayUnion([result]),
          });
        });

        print('Array updated successfully.');
      } catch (e) {
        print('Error updating array: $e');
      }

    }
    if (basketToPost != []) {
      await FirebaseFirestore.instance.collection('purchases').doc(docId)
          .set({
        'id': docId,
        'items': basketToPost,
        'date': DateTime.now(),
        'currency': currency,
        'requestBy': prefs.getString(kLoginPersonName)!,
        'storeId':  prefs.getString(kStoreIdConstant)!,
        'name':  prefs.getString(kBusinessNameConstant)!,
        'activity': "Restocked",
        'supplier': Provider.of<StyleProvider>(context, listen: false).supplierName,
        'supplierId': Provider.of<StyleProvider>(context, listen: false).supplierId,
        'paid':false


      });
    }



    ScaffoldMessenger.of(context).showSnackBar( SnackBar(content: Text('${selectedStocks.length} Items were Restocked')));
    Navigator.pop(context);
    Navigator.pop(context);
  }

  Future<void> updateEmployeeSignInAndOutDoc (bool value)async {
    final deviceInfoPlugin = DeviceInfoPlugin();
    final androidInfo = await deviceInfoPlugin.androidInfo;
    final iosInfo = await deviceInfoPlugin.iosInfo;
    final webInfo = await deviceInfoPlugin.webBrowserInfo;

    String deviceType = "";
    if (androidInfo != null) {
      deviceType = androidInfo.device;
    } else if (iosInfo != null) {
      deviceType = iosInfo.name;
    }else if (webInfo != null){
      deviceType = webInfo.browserName.name;
    }
    final dateNow = new DateTime.now();
    CollectionReference userOrder = FirebaseFirestore.instance.collection('employees');
    final prefs =  await SharedPreferences.getInstance();
    String docId = prefs.getString(kEmployeeId) ?? "";
    print(deviceType);

    return userOrder.doc(docId)
        .update({
      'signedIn': {'${DateFormat('hh:mm a EE, dd, MMM').format(dateNow)}': value},
      'token': prefs.getString(kToken),
      'device': deviceType

    });
  }

  Future<void> uploadUpdatedStockItems(selectedStocks, context, basketToPost, docId) async {
    final prefs = await SharedPreferences.getInstance();
    var now = DateTime.now().toIso8601String();
    showDialog(context: context, builder: ( context) {return const Center(child: CircularProgressIndicator(
      color: kAppPinkColor,));});
    // Loop through the selectedStocks list and update the Firestore documents.
    for (var stock in selectedStocks) {
      print("${stock.name}:${stock.id}");

      try {

          var result = 'U${stock.restock}?$now';

          // Add the result to an array in the same document.
          await FirebaseFirestore.instance.collection('stores').doc(stock.id)
              .update({
            'quantity': stock.restock,
            'stockTaking': FieldValue.arrayUnion([result]),
          });

        print('Array updated successfully.');
      } catch (e) {
        print('Error updating array: $e');
      }

    }
    if (basketToPost != []) {
      await FirebaseFirestore.instance.collection('purchases').doc(docId)
          .set({
        'id': docId,
        'items': basketToPost,
        'date': DateTime.now(),
        'requestBy': prefs.getString(kLoginPersonName)!,
        'storeId':  prefs.getString(kStoreIdConstant)!,
        'name':  prefs.getString(kBusinessNameConstant)!,
        'activity': "Updated"

      });
    }

    ScaffoldMessenger.of(context).showSnackBar( SnackBar(content: Text('${selectedStocks.length} Items were Updated')));
    Navigator.pop(context);
    Navigator.pop(context);
  }

  Future<void> uploadReducedStockItems(selectedStocks, context, basketToPost, docId) async {
    final prefs = await SharedPreferences.getInstance();
    var now = DateTime.now().toIso8601String();
    showDialog(context: context, builder: ( context) {return Center(
          child:
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(color: kAppPinkColor,),
              kSmallHeightSpacing,
              DefaultTextStyle(
                style: kNormalTextStyle.copyWith(color: kPureWhiteColor),
                child: Text("Adjusting Items in Stock", textAlign: TextAlign.center,),
              )
              // Text("Loading Contacts", style: kNormalTextStyle.copyWith(color: kPureWhiteColor),)
            ],
          ));});


    for (var stock in selectedStocks) {
      print("${stock.name}:${stock.id}");

      try {
        await FirebaseFirestore.instance
            .collection('stores')
            .doc(stock.id)
            .get()
            .then((documentSnapshot) {
          // Get the quantity from the document.
          var quantity = documentSnapshot.data()!['quantity'];
          double updateStock = (-stock.restock) + quantity;

          // Concatenate the result and the datetime into a string.
          var result = 'S$updateStock?$now';

          // Add the result to an array in the same document.
          FirebaseFirestore.instance.collection('stores').doc(stock.id)
              .update({
            'quantity': FieldValue.increment(-stock.restock),
            'stockTaking': FieldValue.arrayUnion([result]),
        });
            });

        print('Array updated successfully.');
      } catch (e) {
        print('Error updating array: $e');
      }

    }
    if (basketToPost != []) {
      await FirebaseFirestore.instance.collection('purchases').doc(docId)
          .set({
        'id': docId,
        'items': basketToPost,
        'date': DateTime.now(),
        'requestBy': prefs.getString(kLoginPersonName)!,
        'storeId': prefs.getString(kStoreIdConstant)!,
        'name': prefs.getString(kBusinessNameConstant)!,
        'activity': "Sold"
      });
    }
    ScaffoldMessenger.of(context).showSnackBar( SnackBar(content: Text('${selectedStocks.length} Items stock was Updated')));
    Navigator.pop(context);
    // Navigator.pop(context);
  }

  Future<void> uploadExpense( basketToPost, context, docId, image, supplier, supplierId, currency) async {
    final prefs = await SharedPreferences.getInstance();
    var now = DateTime.now().toIso8601String();
    showDialog(context: context, builder: ( context) {return const Center(child: CircularProgressIndicator(
      color: kAppPinkColor,));});


    if (basketToPost != []) {
      await FirebaseFirestore.instance.collection('purchases').doc(docId)
          .set({
        'id': docId,
        'items': basketToPost,
        'date': DateTime.now(),
        'paid': false,
        'requestBy': prefs.getString(kLoginPersonName)!,
        'supplier': supplier,
        'supplierId': supplierId,
        'storeId':  prefs.getString(kStoreIdConstant)!,
        'name':  prefs.getString(kBusinessNameConstant)!,
        'activity': "Expense",
        'receipt': image,
        'currency': currency


      });
    }



   ScaffoldMessenger.of(context).showSnackBar( SnackBar(content: Text('Expense Recorded')));
    Navigator.pop(context);
    Navigator.pop(context);
    Navigator.pop(context);
  }
// CODE ENDS HERE
  Future<void> testUploader ( )async {

    //final prefs =  await SharedPreferences.getInstance();

    return testingTesting.doc('asdasdasdasdas')
        .set({

      'items': [
        {
          'product':"basketProducts[i].name",
          'description': "basketProducts[i].details",
          'quantity': "basketProducts[i].quantity",
          'totalPrice': 20000,
        }
      ]
    })
        .then((value) {
          print("Done");
      // showNotification('Order Received', '${prefs.getString(kFirstNameConstant)} we have received your order! We shall have it ready for Delivery');
    } )
        .catchError((error) {

      // Navigator.pop(context);
      print(error);

    } );
  }

  Future<File?> compressImage(File file)async {
    File? compressedImage;

    // Wrap the async operation in a try-catch block to handle exceptions
    try {
      final compressedImageFile = await FlutterImageCompress.compressAndGetFile(
        file.absolute.path,
        "${file.path}_compressed.jpg",
        quality: 50,
      );
      compressedImage = compressedImageFile;
    } catch (e) {
      // Handle exceptions if any
      print('Failed to compress image: $e');
    }


    return compressedImage;
  }

  // Check for internet connectivity
  Future<void> execute(InternetConnectionChecker internetConnectionChecker,
      ) async {

    final bool isConnected = await InternetConnectionChecker().hasConnection;
    // ignore: avoid_print
    print(
      isConnected.toString(),
    );
    // returns a bool

    // We can also get an enum instead of a bool
    // ignore: avoid_print
    print(
      'Current status: ${await InternetConnectionChecker().connectionStatus}',
    );
    // Prints either InternetConnectionStatus.connected
    // or InternetConnectionStatus.disconnected

    // actively listen for status updates
    final StreamSubscription<InternetConnectionStatus> listener =
    InternetConnectionChecker().onStatusChange.listen(
          (InternetConnectionStatus status) {
        switch (status) {
          case InternetConnectionStatus.connected:
          // ignore: avoid_print
          //   Get.snackbar('Internet Restored', 'You are back online');
          //   print('PARARARARA we are back on.');
            break;
          case InternetConnectionStatus.disconnected:
          // ignore: avoid_print
            //Get.snackbar('No Internet', 'Please check your internet connection');

            print('OH NOOOOOOO GAGENZE');
            break;
        }
      },
    );

    // close listener after 30 seconds, so the program doesn't run forever
    await Future<void>.delayed(const Duration(seconds: 30));
    await listener.cancel();
  }
  // Removing Appointment from the server
  Future <dynamic> updateInvoiceData(String docId, items,String appointmentId,String client, String clientNumber, String customerId, DateTime appointmentDate, double totalFee, context ){

    return FirebaseFirestore.instance
        .collection('appointments')
        .doc(docId)
        .update({
      'active':  false,
      'items' : items,
      'appointmentId': appointmentId,
      'client': client,
      'appointmentDate': appointmentDate,
      'totalFee': totalFee,
      'clientPhone': clientNumber,
      'customerId': customerId

    })
        .then((value) => Navigator.pop(context));
  }

  double calculateFontSize(BuildContext context) {
    // Calculate font size based on screen width
    double baseFontSize = 16.0;
    double screenWidth = MediaQuery.of(context).size.width;
    double fontSize = baseFontSize;

    if (screenWidth <= 320) {
      fontSize = baseFontSize - 2.0;
    } else if (screenWidth <= 360) {
      fontSize = baseFontSize - 1.0;
    } else if (screenWidth >= 414) {
      fontSize = baseFontSize + 2.0;
    }

    return fontSize;
  }

  // Removing Appointment from the server
  Future <dynamic> removeAppointment(docId ){

    return FirebaseFirestore.instance
        .collection('appointments')
        .doc(docId)
        .update({
      'active':  false
    })
        .then((value) => print("Done"));
  }

  // This removes post favourites
  Future <dynamic> removeDocumentFromServer(docId, collection ){

    return FirebaseFirestore.instance
        .collection(collection)
        .doc(docId).delete()
    //     .update({
    //   'active':  false
    // })
        .then((value) =>print(collection));
  }

  Future <dynamic> updateDocumentFromServer(docId, collection, field, value ){

    return FirebaseFirestore.instance
        .collection(collection)
        .doc(docId)
        //.delete()
        .update({
      field :  value
    })
        .then((value) =>print(collection));
  }

  Future <dynamic> updateTaskInProgress(String docId, String collection, List executionAt, List executionBy, List taskTrack, context){
    showDialog(context: context, builder: ( context) {return const Center(child: CircularProgressIndicator(
      color: kAppPinkColor,));});
    return FirebaseFirestore.instance
        .collection(collection)
        .doc(docId)
        .update({
      "executedBy" :  executionBy,
      "executedAt" :  executionAt,
      "track": taskTrack

    })
        .whenComplete(() {
      Provider.of<BeauticianData>(context, listen: false).setLottieImage( 'images/Hi5.json', "Task Started");
      Navigator.pop(context);
      Navigator.pop(context);
      Navigator.pushNamed(context, SuccessPageHiFive.id);


    });
  }

  Future <dynamic> updateTaskDone(String docId, String collection, List finishedAt, List finishedBy, List taskTrack, List completed, context){
    showDialog(context: context, builder: ( context) {return const Center(child: CircularProgressIndicator(
      color: kAppPinkColor,));});
    return FirebaseFirestore.instance
        .collection(collection)
        .doc(docId)
        .update({
      "finishedBy" :  finishedBy,
      "finishedAt" :  finishedAt,
      "track": taskTrack,
      "completed": completed

    }).whenComplete(() {
      Provider.of<BeauticianData>(context, listen: false).setLottieImage( 'images/tasks.json', "Task Completed");
      Navigator.pop(context);
      Navigator.pop(context);
      Navigator.pushNamed(context, SuccessPageHiFive.id);
    });
  }
  void updateUserNotificationToken(documentId)async{
    var token = "this_is_a_web_token";
    final prefs = await SharedPreferences.getInstance();
    if(kIsWeb){
      token = token;
    }else{
      token = prefs.getString(kToken)??"";
    }
    FirebaseFirestore.instance.collection('employees').doc(documentId)
        .update({
      'token': token,
    });

  }
  Future <dynamic> updateOnlineStoreInfo(docId, field, fieldValue ){

    return FirebaseFirestore.instance
        .collection('medics')
        .doc(docId)
        .update({
      field:  fieldValue
    })
        .then((value) => print("Done"));
  }

  List<int> orderDaysByDescendingValue(List<double> array) {
    if (array.isEmpty) {
      throw ArgumentError("The array cannot be empty.");
    }

    List<int> indices = List.generate(array.length, (index) => index);
    indices.sort((a, b) => array[b].compareTo(array[a]));
    return indices;
  }

  String getDayFromIndex(int index) {
    switch (index) {
      case 0:
        return "Monday";
      case 1:
        return "Tuesday";
      case 2:
        return "Wednesday";
      case 3:
        return "Thursday";
      case 4:
        return "Friday";
      case 5:
        return "Saturday";
      case 6:
        return "Sunday";
      default:
        return "Invalid Index";
    }
  }

  int findIndexOfHighestValue(List<double> array) {
    if (array.isEmpty) {
      throw ArgumentError("The array cannot be empty.");
    }

    double maxValue = array[0];
    int maxIndex = 0;

    for (int i = 1; i < array.length; i++) {
      if (array[i] > maxValue) {
        maxValue = array[i];
        maxIndex = i;
      }
    }
    return maxIndex;
  }

  Map<String, dynamic> convertJsonString(String jsonString){



    Map<String, dynamic> jsonMap = json.decode(jsonString);
    return jsonMap;
  }

  Future<Map<String, dynamic>> convertPermissionsJson()async {
    final prefs = await SharedPreferences.getInstance();
    Map<String, dynamic> jsonMap = json.decode(prefs.getString(kPermissions)??"");
     return jsonMap;
  }
  Future<Map<String, dynamic>> convertWalkthroughVideoJson()async {
    final prefs = await SharedPreferences.getInstance();
    Map<String, dynamic> jsonMap = json.decode(prefs.getString(kWalkthroughVideos)??"");
    return jsonMap;
  }
Map<String, dynamic> convertPermissionsStringToJson(String permission){

    Map<String, dynamic> jsonMap = json.decode(permission);
    return jsonMap;
  }

  void playBeepSound() async {
    await _audioPlayer.play(AssetSource(('beep.mp3'))); // Play the audio file
  }

  Future userSubscription(context) async {

    final prefs = await SharedPreferences.getInstance();
    String storeId = prefs.getString(kStoreIdConstant)??"uuuuuuuu";

    try {
      final docRef = FirebaseFirestore.instance.collection('medics').doc(storeId);
      final docSnapshot = await docRef.get();
      print("WOOWOWOWOOWOWOWOWO $storeId");
      if (docSnapshot.exists) {
        final endDate = docSnapshot.get('subscriptionEndDate').toDate();
        print(endDate);
        Provider.of<StyleProvider>(context,listen: false).setSubscription(
          endDate
        );
      } else {
        print('Document with ID $storeId does not exist');
      }
    } catch (e) {
      print('Error fetching subscriptionEndDate: $e');
    }
  }

  Future transactionStream(context, orderId)async{

    var start = FirebaseFirestore.instance.collection('transactions').where('uniqueID', isEqualTo: orderId).where('payment_status', isEqualTo: true).snapshots().listen((QuerySnapshot querySnapshot) {
      querySnapshot.docs.forEach((doc) async {
        // setState(() {
          Provider.of<StyleProvider>(context, listen: false).setPendingPaymentStatement();

          CoolAlert.show(
              lottieAsset: 'images/thankyou.json',
              context: context,
              type: CoolAlertType.success,
              text: "Your Payment was successfully Received and Updated",
              title: "Payment Received",
              confirmBtnText: 'Ok 👍',
              confirmBtnColor: kAppPinkColor,
              backgroundColor: kBlueDarkColorOld
          );
        });
      });
    // });


    return start;
  }

  String processPhoneNumber(String phoneNumber) {
    if (phoneNumber.startsWith("0")) {
      return phoneNumber.substring(1); // Remove the leading '0'
    } else {
      return phoneNumber; // Number doesn't start with 0, return as-is
    }
  }

  Future<void> downloadTemplate() async {
    // Create an Excel file with predefined headers
    var excel = Excel.createExcel();
    var sheet = excel['Sheet1'];

    // Add headers to the Excel sheet
    sheet.appendRow(['Name', 'Description', 'Amount', 'Saleable', 'Tracking', 'Quantity', 'Minimum']);

    final List<int>? excelData = excel.encode();

    // Create a blob from the bytes and create a download link

    //PLEASE RE PUT THIS CODE WHEN DEALING WITH WEB
    // final blob = html.Blob([excelData]);
    // final blobUrl = html.Url.createObjectUrlFromBlob(blob);
    //
    // // Create a link element and trigger the download
    // final anchor = html.AnchorElement(href: blobUrl)
    //   ..target = 'download'
    //   ..download = 'bulk_upload_data.xlsx';
    //
    // // Trigger the click event to start the download
    // html.document.body?.append(anchor);
    // anchor.click();
    //
    // // Clean up the temporary link
    // html.Url.revokeObjectUrl(blobUrl);
    // anchor.remove();
  }
  Future<void> uploadExcelDataToFirebase(List<ExcelDataRow> dataList, context) async {

    try {
      final prefs = await SharedPreferences.getInstance();

      CollectionReference dataCollection = FirebaseFirestore.instance
          .collection(
          'stores');

      dataList.forEach((rowData) {
        var newDocumentRef = dataCollection
            .doc(); // Firestore generates a unique ID
        newDocumentRef.set({
          'active': true,
          'id': newDocumentRef.id, // Add the unique ID as the 'id' field
          'name': rowData.name,
          'description': rowData.description,
          'approved':true,
          'ignore':false,
          'barcode':newDocumentRef.id,
          'date': DateTime.now(),
          'amount': rowData.amount,
          'saleable': rowData.saleable,
          'tracking': rowData.tracking,
          'quantity': rowData.quantity,
          'minimum': rowData.minimum,
          'image': "https://mcusercontent.com/f78a91485e657cda2c219f659/images/14f4afc4-ffaf-4bb1-3384-b23499cf0df7.png",
          'storeId': prefs.getString(kStoreIdConstant),
          'stockTaking': []
        }).onError((error, stackTrace) =>  ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error! $error'))
        ))
            .whenComplete(() {
          ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Items added Successfully'))
          );
          Navigator.pop(context);

        }
        );
      });


    } catch (e) {
      CommonFunctions().showErrorDialog("$e", context);
    }
  }
  void showErrorDialog(String errorMessage, context) {
    showCupertinoDialog(
      context: context,
      builder: (BuildContext context) {
        return CupertinoAlertDialog(
          title: Text('Error'),
          content: Text(errorMessage),
          actions: [
            CupertinoDialogAction(
              child: Text('OK'),
              onPressed: () {
                Navigator.pop(context); // Close the dialog
              },
            ),
          ],
        );
      },
    );
  }

  Future<List<AllStockData>> retrieveSuppliesData(context) async {

    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('stores')
          .where('storeId', isEqualTo: Provider.of<StyleProvider>(context, listen: false).beauticianId)
          .orderBy('name', descending: false)
          .get();

      final stockDataList = snapshot.docs
          .map((doc) => AllStockData.fromFirestore(doc))
          .toList();
      return stockDataList;
    } catch (error) {
      print('Error retrieving stock data: $error');
      return []; // Return an empty list if an error occurs
    }
  }

  Future<bool> subscriptionActive() async{
    bool allow = false;
    final prefs = await SharedPreferences.getInstance();
    int subscriptionDate = prefs.getInt(kSubscriptionEndDate)?? DateTime.now().millisecondsSinceEpoch;
    if(subscriptionDate>= DateTime.now().millisecondsSinceEpoch){
      allow = true;
    }else{
      allow = false;
    }

    return allow;
  }

  Future<dynamic> buildSubscriptionPaymentModal(BuildContext context) async{
    final prefs = await SharedPreferences.getInstance();
    String businessName = prefs.getString(kBusinessNameConstant)??"";
    return showModalBottomSheet(
        isScrollControlled: true,
        context: context,
        builder: (context) {
          return Scaffold(
            appBar: AppBar(
              elevation: 0,
              backgroundColor: kPureWhiteColor,
              automaticallyImplyLeading: false,
              // title: Text("Subscribe to Premium", style: kNormalTextStyle.copyWith(color: kBlack, fontWeight: FontWeight.bold),),
            ),
            body: Scaffold(
                backgroundColor: kBlack,
                appBar: AppBar(
                  elevation: 0,
                  backgroundColor: kGoldColor,
                  automaticallyImplyLeading: true,
                  centerTitle: true,
                  title: Text("SUBSCRIBE TO PREMIUM", style: kNormalTextStyle.copyWith(color: kBlack, fontWeight: FontWeight.bold),),
                ),
                body: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // kLargeHeightSpacing,
                    Opacity(
                        opacity: 0.4,
                        child: Image.asset('images/liftoff.jpg',height: 120,)),

                    Center(child: SubcriptionEndedWidget(businessName: businessName,)),
                  ],
                )),
          );
        });
  }


}