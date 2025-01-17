import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dropdown_search/dropdown_search.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:stylestore/Utilities/constants/font_constants.dart';
import '../../Utilities/constants/color_constants.dart';
import '../../Utilities/constants/user_constants.dart';
import '../../model/common_functions.dart';
import '../../model/styleapp_data.dart';
import '../../widgets/text_form.dart';


class AddExpenseWidget extends StatefulWidget {



  @override
  State<AddExpenseWidget> createState() => _AddExpenseWidgetState();
}

class _AddExpenseWidgetState extends State<AddExpenseWidget> {
  var expenseName = "";
  var supplierName = "";
  var expenseCost = "0.0";

  var expenseQuantity = "1";
  var expenseOrderNumber = "";
  var originalBasketToPost = [];
  var storeId = "";
  String? selectedDepartment;
  List<String> supplierDisplayNames = [];
  List<String> supplierIds = ["default"];
  List<String> supplierRealNames = ["Supplier"];
  String? selectedSupplierDisplayName;
  String? selectedSupplierId;
  String? selectedSupplierRealName;
  List<String> _filteredSupplierDisplayNames = [];
  late TextEditingController expenseController;
  late TextEditingController quantityController;
  String currency = "";

  File? image;
  var imageUploaded = false;
  final storage = FirebaseStorage.instance;
  UploadTask? uploadTask;

  Future pickImage(ImageSource source)async{
    try {
      final image = await ImagePicker().pickImage(source: source);
      if (image == null){
        return ;
      }else {
        var file = File(image.path);
        final compressedImage = await CommonFunctions().compressImage(File(image.path));
        setState(() {
          imageUploaded = true;
          this.image = compressedImage;
        });
      }
    } on PlatformException catch (e) {
      print('Failed to pick image $e');

    }
  }

  Future<void> fetchSupplierNames() async {
    QuerySnapshot querySnapshot = await FirebaseFirestore.instance
        .collection('suppliers')
        .where("storeId", isEqualTo: storeId)
        .get();
    List<String> supplierData = querySnapshot.docs.map((doc) {
      String name = doc['name'] as String;
      String supplies = doc['supplies'] as String;
      supplierIds.add(doc.id);
      supplierRealNames.add(doc['name']);
      return "$name ($supplies)";
    }).toList();
    setState(() {
      supplierDisplayNames = ["Supplier",...supplierData];
    });
  }

  Future<void> uploadPhoto(String filePath, String fileName)async {
    File file = File(filePath);
    try {
      uploadTask  = storage.ref('receipt/$fileName').putFile(file);
      final snapshot = await uploadTask!.whenComplete((){

      });
      final urlDownload = await snapshot.ref.getDownloadURL();
      CommonFunctions().uploadExpense(originalBasketToPost, context, expenseOrderNumber, urlDownload, selectedSupplierRealName, selectedSupplierId, currency);
    }  catch(e){
      print(e);
    }
  }

  defaultInitilization()async {

    var styleData = Provider.of<StyleProvider>(context, listen: false);
    final prefs = await SharedPreferences.getInstance();
    storeId = prefs.getString(kStoreIdConstant) ?? "";
    expenseOrderNumber = "Expense_${CommonFunctions().generateUniqueID(prefs.getString(kBusinessNameConstant)!)}";
    fetchSupplierNames();
    expenseController = TextEditingController(text: styleData.expense);
    quantityController = TextEditingController(text: expenseQuantity);
    _filteredSupplierDisplayNames = supplierDisplayNames;
    currency = prefs.getString(kCurrency)??"USD"; //Provider.of<StyleProvider>(context, listen: false).storeCurrency;
    setState(() {

    });
  }


  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    defaultInitilization();

  }
  @override
  Widget build(BuildContext context) {



    TextEditingController controller = TextEditingController(text: expenseCost);

    // Move the cursor to the end of the text
    controller.selection = TextSelection.fromPosition(
      TextPosition(offset: controller.text.length),
    );


    return Scaffold(
      backgroundColor: kPureWhiteColor,
      appBar: AppBar(
        title:  Text('Enter Expense Details',textAlign: TextAlign.center, style: kNormalTextStyle.copyWith(fontSize: 18, color: kBlack),),
          backgroundColor: kPureWhiteColor ,
          elevation: 0
      ),
      floatingActionButton: FloatingActionButton.extended(
        splashColor: kBlueDarkColor,
        backgroundColor: kAppPinkColor,
        onPressed: () {
          if(expenseController.text!=""&&expenseCost!="0.0"&&selectedSupplierDisplayName!=null){
            var basketToPost = [
              {
                'product': expenseController.text,
                'description': "",
                'quantity': double.tryParse(quantityController.text) ?? 0,
                'totalPrice': double.tryParse(expenseCost) ?? 0,
                'quality': 'Ok',

              }
            ];
            originalBasketToPost = basketToPost;
            image == null ? CommonFunctions().uploadExpense(basketToPost, context, expenseOrderNumber, "",selectedSupplierRealName, selectedSupplierId, currency) : uploadPhoto(image!.path, expenseOrderNumber,);
            // CommonFunctions().uploadExpense(basketToPost, context, expenseOrderNumber);
          }else {
            showDialog(
              context: context,
              builder: (BuildContext context) {
                return AlertDialog(
                  title: const Text("Missing Information"),
                  content: const Text("Please fill in all required fields (Expense, Cost, Supplier)"),
                  actions: <Widget>[
                    TextButton(
                      child: const Text("OK"),
                      onPressed: () {
                        Navigator.of(context).pop(); // Close the dialog
                      },
                    ),
                  ],
                );
              },
            );
          }

        },
             label: expenseName != ""?Text(
          '$expenseName worth $currency $expenseCost',
          style: kNormalTextStyle.copyWith(color: kPureWhiteColor),
        ):Text("Enter Expense", style: kNormalTextStyle.copyWith(color: kPureWhiteColor)),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.miniCenterFloat,
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.only(left: 20.0, right: 20),
          child: Container(
            height: 450,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                kLargeHeightSpacing,
                Padding(
                  padding: const EdgeInsets.only(left:20.0),
                  child: Row(
                    // mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(currency, style: kNormalTextStyle.copyWith(fontSize: 18),),
                      kSmallWidthSpacing,

                      Expanded(
                        child: TextField(
                          decoration: InputDecoration(
                            border: InputBorder.none,

                          ),
                          controller: controller,
                          // TextEditingController()..text ='${Provider.of<StyleProvider>(context).totalPrice}',
                          textAlign: TextAlign.start,
                          style: kNormalTextStyle.copyWith(fontSize: 50),
                          keyboardType: TextInputType.number,
                          onChanged: (value){
                            expenseCost = value;
                          },
                        ),
                      ),
                    ],
                  ),
                ),
                kLargeHeightSpacing,
                TextForm(label: 'Expense Name',controller: expenseController),
                kLargeHeightSpacing,
                TextForm(label: 'Quantity',controller: quantityController),
                kLargeHeightSpacing,
                DropdownSearch<String>(
                  items: supplierDisplayNames,

                  popupProps:
                  const PopupProps.menu(
                    showSearchBox: true,
                    showSelectedItems: true, // Show selected items at the top
                    searchFieldProps: TextFieldProps(
                      autofocus: true, // Focus the search field when popup opens
                      decoration: InputDecoration(
                        hintText: 'Search...',
                        prefixIcon: Icon(Icons.search),
                      ),

                    ),

                  ),
                  dropdownDecoratorProps: const DropDownDecoratorProps(
                    dropdownSearchDecoration: InputDecoration(
                      labelText: "Select Supplier",
                      hintText: "Supplier for goods",
                    ),
                  ),
                  onChanged: (newValue) {
                    setState(() {
                      selectedSupplierDisplayName = newValue!;
                      int position = supplierDisplayNames.indexOf(newValue);
                      selectedSupplierRealName = supplierRealNames[position];
                      selectedSupplierId = supplierIds[position];
                      print("$selectedSupplierRealName: $selectedSupplierId");
                    });
                  },
                  filterFn: (item, query) {
                    return item.toLowerCase().contains(query!.toLowerCase());
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
