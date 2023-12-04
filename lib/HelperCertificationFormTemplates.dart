import 'dart:io';
//import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
//import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:form_verification_with_stripe/HelperCertificationFormPage.dart';
//import 'package:form_verification_with_stripe/AlertDialogManager.dart';
import 'package:form_verification_with_stripe/UserManager.dart';
import 'package:form_verification_with_stripe/enums.dart';
import 'package:path/path.dart';
import 'package:url_launcher/url_launcher.dart';


class HelperCertificationFormTemplates extends StatefulWidget {

  final Function(Map newUpdatedAccount, bool newUpdateFormValidated) onFormConfirmation;
  List listOfRequiredFields;

  HelperCertificationFormTemplates(
      this.onFormConfirmation,
      this.listOfRequiredFields,
      this.bankAccountToken,
      this.personsToken,
      this.accountId
      );

  String bankAccountToken;
  List personsToken;
  String accountId;

  @override
  State<HelperCertificationFormTemplates> createState() => _HelperCertificationFormTemplates(
      this.onFormConfirmation,
      this.listOfRequiredFields,
      this.bankAccountToken,
      this.personsToken,
      this.accountId
  );
}


class _HelperCertificationFormTemplates extends State<HelperCertificationFormTemplates> {

  UserManager _userManager = UserManager();

  late TextEditingController emailController = TextEditingController();
  late TextEditingController ibanController = TextEditingController();
  late TextEditingController codeController = TextEditingController();
  late TextEditingController companyNameController = TextEditingController();
  late TextEditingController cityController = TextEditingController();
  late TextEditingController postalCodeController = TextEditingController();
  late TextEditingController streetNumberController = TextEditingController();
  late TextEditingController streetNameController = TextEditingController();
  late TextEditingController companyPhoneController = TextEditingController();
  late TextEditingController personCityController = TextEditingController();
  late TextEditingController personPostalCodeController = TextEditingController();
  late TextEditingController personStreetNumberController = TextEditingController();
  late TextEditingController personStreetNameController = TextEditingController();


  //final _picker = ImagePicker();
  File? imageRecto = null;
  File? imageVerso = null;
  File? document = null;
  File? documentCompanyExistence = null;
  String filenameRecto = "";
  String filenameVerso = "";
  String filenameDocument = "";

  String filenameDocumentCompanyExistence = "";
  String countryCode = "";
  String dayBirth = "--";
  String monthBirth = "--";
  String yearBirth = "----";
  String accountId = "";
  String bankAccountToken;
  List personsToken;
  bool personDob = false;
  bool personAddressDisplayed = false;
  bool companyAddressDisplayed = false;
  bool newUpdateFormValidated = false;
  bool displayInformation = false;

  final Function(Map newUpdatedAccount, bool newUpdateFormValidated) onFormConfirmation;

  List listOfRequiredFields;
  bool isSaving = false;
  bool isRestarting = false;

  _HelperCertificationFormTemplates(
      this.onFormConfirmation,
      this.listOfRequiredFields,
      this.bankAccountToken,
      this.personsToken,
      this.accountId
      );

  @override
  Widget build(BuildContext context) {
    return
      Column(
        children: [
          Column(
              children: listOfRequiredFields.map(
                      (element) {
                    return getDisplay(
                        element,
                        bankAccountToken,
                        personsToken,
                        context
                    );
                  }).toList()
          ),
          if (displayInformation) SizedBox(height: 30),
          if (displayInformation)
            Padding(
              padding: const EdgeInsets.only(left: 8.0,right: 8.0),
              child: Container(
                padding: EdgeInsets.all(15.0),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20.0),
                  color: Colors.yellowAccent,
                ),
                child: Column(
                  children: [
                    Text(
                      "Tu ne possèdes pas de numéro SIREN, ni de dénomination/raison sociale, ni d'extrait KBIS, ni de code APE ou NAF ?",
                      style: GoogleFonts.poppins(
                        color: Colors.blue,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("👉 "),
                        Expanded(
                          child: Center(
                            child: RichText(
                              text: TextSpan(
                                text: "",
                                children: <TextSpan>[
                                  TextSpan(
                                    text:"Obtiens-les GRATUITEMENT en créant ton compte d'indépendant ou d'auto-entrepreneur dès maintenant ! ",
                                    style: TextStyle(
                                      color: Colors.black,
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  TextSpan(
                                    text:"En cliquant ici",
                                    style: TextStyle(
                                      color: Colors.green,
                                      decoration: TextDecoration.underline,
                                      decorationThickness: 2,
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                    recognizer: TapGestureRecognizer()..onTap = () async {
                                      final Uri _url = Uri.parse("https://www.autoentrepreneur.urssaf.fr/portail/accueil/creer-mon-comptev2.html");
                                      await launchUrl(_url);
                                    },
                                  )
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          if (displayInformation) SizedBox(height: 30),
          Divider(
            thickness: 5,
            color: Colors.black,
          ),
          SizedBox(height: 30),
          InkWell(
            onTap: () async {
              setState(() {
                personDob = false;
                isSaving = true;
              });
              newUpdateFormValidated = true;
              await setChanges();
              setState(() {
                personDob = false;
                isSaving = false;
              });
            },
            child: Container(
              height:50,
              width: 250,
              decoration: BoxDecoration(
                  color: newUpdateFormValidated ? Colors.grey[300] : Colors.purple,
                  borderRadius: BorderRadius.circular(30),
                  boxShadow: [
                    BoxShadow(
                        color: Colors.grey,
                        blurRadius: 4,
                        offset: Offset(0,3)
                    ),
                  ]
              ),
              child: Center(
                child: isSaving ?
                Container(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(color: Colors.white,)
                )
                    :
                Text(
                  newUpdateFormValidated ? "Enregistré ✅" : "Enregistrer",
                  style: GoogleFonts.poppins(
                    color: newUpdateFormValidated ? Colors.grey[600] : Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ),
          SizedBox(height: 30),
          InkWell(
            onTap: () async {
              setState(() {
                personDob = false;
                isRestarting = true;
              });

              HttpsCallable callable = await FirebaseFunctions.instanceFor(app: FirebaseFunctions.instance.app, region: "europe-west1").httpsCallable('deleteCustomConnectAccount');
              final resp = await callable.call(<String, dynamic> {
                "accountId":accountId,
              });

              String finalStatus = resp.data["status"];
              if ("success" == finalStatus){

                await _userManager.updateValue("allUsers", "is_helper_certified", 0);
                await _userManager.updateValue("allHelpers", "is_helper_certified", 0);
                await _userManager.deleteElement("allStripeConnectAccounts", accountId);

                Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                        builder: (BuildContext context) => HelperCertificationFormPage()));

              }else{
                setState(() {
                  personDob = false;
                  isRestarting = false;
                });
                //AlertDialogManager.shortDialog(context,"Réinitialisation impossible", contentMessage: "Il reste encore des revenus  sur ton compte.");
              }
            },
            child: Container(
              height:70,
              width: 250,
              decoration: BoxDecoration(
                  color: Colors.orange,
                  borderRadius: BorderRadius.circular(30),
                  boxShadow: [
                    BoxShadow(
                        color: Colors.grey,
                        blurRadius: 4,
                        offset: Offset(0,3)
                    ),
                  ]
              ),
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: isRestarting ?
                  Container(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(color: Colors.white,)
                  )
                      :
                  Text(
                    "Recommencer mon inscription depuis le début",
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ),
          ),
          SizedBox(height: 30),
        ],
      );
  }

  Widget getDisplay(
      String field,
      String bankAccountToken,
      List personsToken,
      BuildContext context){

    Widget currentWidget = Container();
    //debugPrint("DEBUG_LOG personsToken[0]="+personsToken[0].toString());
    String singlePersonToken = personsToken[0]["id"];

    if(field.contains(singlePersonToken)){

      if(field.contains(singlePersonToken + ".first_name")){
        currentWidget = Column(
          children: [
            Title(person_required_fields["first_name"][0], 100, 30),
            Container(
              decoration: BoxDecoration(
                  border: Border.all(color: Colors.blueAccent, width: 3)
              ),
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Align(
                  alignment: Alignment.center,
                  child: Text(
                    person_required_fields["first_name"][1],
                    style: GoogleFonts.poppins(
                      color: Colors.blue,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ),
            SizedBox(height: 50)
          ],
        );
      }
      if(field.contains(singlePersonToken + ".last_name")){
        currentWidget = Column(
          children: [
            Title(person_required_fields["last_name"][0], 100, 30),
            Container(
              decoration: BoxDecoration(
                  border: Border.all(color: Colors.blueAccent, width: 3)
              ),
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Align(
                    child: Text(
                      person_required_fields["last_name"][1],
                      style: GoogleFonts.poppins(
                        color: Colors.blue,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    )
                ),
              ),
            ),
            SizedBox(height: 50)
          ],
        );
      }
      if(field.contains(singlePersonToken + ".dob")){
        if (!personDob){
          currentWidget = PersonDob();
          personDob = true;
        }
      }
      if(field.contains(singlePersonToken + ".email")){
        currentWidget = PersonEmail();
      }
      if(field.contains(singlePersonToken + ".phone")){
        currentWidget = Column(
          children: [
            Text(person_required_fields["phone"][0]),
            SizedBox(height: 50)
          ],
        );
      }
      if(field.contains(singlePersonToken + ".address")){
        if (!personAddressDisplayed){
          currentWidget = Column(
            children: [
              Title(person_required_fields["address"][0], 120, 30),
              AddressCity(false),
              PostalCode(false),
              AddressLine1(false),
            ],
          );
          personAddressDisplayed = true;
        }
      }
      if(field.contains(singlePersonToken + ".verification.additional_document")){
        currentWidget = VerificationDocument(false);
      }
      if(field.contains(singlePersonToken + ".verification.document")){
        currentWidget = PersonVerificationDocumentIdentity();
      }

    }
    else if (field.contains(bankAccountToken)){
      if(field.contains(bankAccountToken + ".account_number")){
        currentWidget = PersonAccountNumber();
      }
      if(field.contains(bankAccountToken + ".routing_number")){
        //TODO: To be configured as => currentWidget = BankRoutingNumber();
      }
    }
    else if(field.contains("company.address")){
      if (!companyAddressDisplayed){
        currentWidget = Column(
          children: [
            Title(required_fields["address"][0], 260, 30),
            AddressCity(true),
            PostalCode(true),
            AddressLine1(true),
          ],
        );
        companyAddressDisplayed = true;
      }
      //TODO: field.contains("company.address.state") ? currentWidget = AddressState() : currentWidget =Container()
    }else{
      switch(field) {
        case "business_profile.mcc": {
          currentWidget = CompanyMcc(context);
          displayInformation = true;
        }
        break;
        case "company.name": {
          currentWidget = CompanyName();
          displayInformation = true;
        }
        break;
        case "company.owners_provided": {
          //HardCoded value
        }
        break;
        case "company.phone": {
          currentWidget = CompanyPhone();
        }
        break;
        case "company.tax_id": {
          currentWidget = CompanyTaxId();
          displayInformation = true;
        }
        break;
        case "company.verification.document": {
          currentWidget = VerificationDocument(true);
          displayInformation = true;
        }
        break;
        case "external_account": {
          currentWidget = CompanyExternalAccount();
        }
        break;
        case "owners.address.city": {
          //TODO: To be configured as => currentWidget = OwnersAddressCity();
        }
        break;
        case "owners.address.line1": {
          //TODO: To be configured as => currentWidget = OwnersAddressLine1();
        }
        break;
        case "owners.address.postal_code": {
          //TODO: To be configured as => currentWidget = OwnersAddressPostalCode();
        }
        break;
        case "owners.address.state": {
          //TODO: To be configured as => currentWidget = OwnersAddressState();
        }
        break;
        case "owners.dob.day": {
          //TODO: To be configured as => currentWidget = OwnersDob();
        }
        break;
        case "owners.dob.month": {
          //TODO: To be configured as => currentWidget = OwnersDob();
        }
        break;
        case "owners.dob.year": {
          //TODO: To be configured as => currentWidget = OwnersDob();
        }
        break;
        case "owners.email": {
          //TODO: To be configured as => currentWidget = OwnersEmail();
        }
        break;
        case "owners.first_name": {
          //TODO: To be configured as => currentWidget = OwnersFirstName();
        }
        break;
        case "owners.id_number": {
          //TODO: To be configured as => currentWidget = OwnersIdNumber();
        }
        break;
        case "owners.last_name": {
          //TODO: To be configured as => currentWidget = OwnersLastName();
        }
        break;
        case "owners.phone": {
          //TODO: To be configured as => currentWidget = OwnersPhone();
        }
        break;
        case "owners.ssn_last_4": {
          //TODO: To be configured as => currentWidget = OwnersSsnLast4();
        }
        break;
        case "owners.verification.document": {
          //TODO: To be configured as => currentWidget = OwnersVerificationDocument();
        }
        break;
        case "representative.address.city": {
          //TODO: To be configured as => currentWidget = RepresentativeAddressCity();
        }
        break;
        case "representative.address.line1": {
          //TODO: To be configured as => currentWidget = RepresentativeAddressLine1();
        }
        break;
        case "representative.address.postal_code": {
          //TODO: To be configured as => currentWidget = RepresentativeAddressPostalCode();
        }
        break;
        case "representative.address.state": {
          //TODO: To be configured as => currentWidget = RepresentativeAddressState();
        }
        break;
        case "representative.dob.day": {
          //TODO: To be configured as => currentWidget = RepresentativeDob();
        }
        break;
        case "representative.dob.month": {
          //TODO: To be configured as => currentWidget = RepresentativeDob();
        }
        break;
        case "representative.dob.year": {
          //TODO: To be configured as => currentWidget = RepresentativeDob();
        }
        break;
        case "representative.email": {
          //TODO: To be configured as => currentWidget = RepresentativeEmail();
        }
        break;
        case "representative.first_name": {
          //TODO: To be configured as => currentWidget = RepresentativeFirstName();
        }
        break;
        case "representative.id_number": {
          //TODO: To be configured as => currentWidget = RepresentativeIdNumber();
        }
        break;
        case "representative.last_name": {
          //TODO: To be configured as => currentWidget = RepresentativeLastName();
        }
        break;
        case "representative.phone": {
          //TODO: To be configured as => currentWidget = RepresentativePhone();
        }
        break;
        case "representative.relationship.executive": {
          //TODO: To be configured as => currentWidget = RepresentativeRelationshipExecutive();
        }
        break;
        case "representative.relationship.title": {
          //TODO: To be configured as => currentWidget = RepresentativeRelationshipTitle();
        }
        break;
        case "representative.ssn_last_4": {
          //TODO: To be configured as => currentWidget = RepresentativeSsnLast4();
        }
        break;
        case "representative.verification.document": {
          //TODO: To be configured as => currentWidget = RepresentativeVerificationDocument();
        }
        break;
      }
    }
    return currentWidget;
  }

  Future<Map<String,dynamic>> buildMapResponseForUpdate() async {
    List company = [];
    List bank_account = [];
    List person = [];
    bool companyAddressUpdated = false;
    bool personAddressUpdated = false;
    bool personDobUpdated = false;


    Map<String,dynamic> newUpdatedAccount = {
      "company":{},
      "person":{},
      "bank_account":{}
    };

    String uid = _userManager.userId!;
    Reference ref = FirebaseStorage.instance.ref();
    String person_token = personsToken[0]["id"];

    listOfRequiredFields.forEach((element) {
      List requiredElement = element.split(".");
      String key = requiredElement[0];
      if (key.contains("company")){
        company.add(element);
      }else if(key.contains(person_token)){
        person.add(element);
      }else if(key.contains(bankAccountToken)){
        bank_account.add(element);
      }
    });


    for(String element in company){
      List requiredElement = element.split(".");
      if ("name" == requiredElement[1]){
        newUpdatedAccount["company"]["name"] = companyNameController.text.trim();
      }

      if ("phone" == requiredElement[1]){
        newUpdatedAccount["company"]["phone"] = companyPhoneController.text.trim();
      }

      if ("tax_id" == requiredElement[1]){
        newUpdatedAccount["company"]["tax_id"] = codeController.text.trim();
      }

      if ("address" == requiredElement[1]){
        if(!companyAddressUpdated){
          newUpdatedAccount["company"]["address"] = {
            "city":cityController.text.trim(),
            "postal_code":postalCodeController.text.trim(),
            "line1":streetNumberController.text.trim() + " " + streetNameController.text.trim(),
          };
          companyAddressUpdated = true;
        }
      }

      if ("verification" == requiredElement[1]){
        if ("document" == requiredElement[2]){
          var tmpFileNameCompanyProof = "company_registration_verification_" + uid + "." + filenameDocumentCompanyExistence.split(".").last;
          await ref.child("saved_users_files/$uid/$tmpFileNameCompanyProof").putFile(documentCompanyExistence!);

          if (newUpdatedAccount["company"]["verification"] == null){
            newUpdatedAccount["company"]["verification"] =
            {
              "document":{
                "front":tmpFileNameCompanyProof,
              }
            };
          } else {
            newUpdatedAccount["company"]["verification"].putIfAbsent("document", () =>
            {
              "front":tmpFileNameCompanyProof,
            }
            );
          }
        }
      }
    }

    for (String element in person){
      List requiredElement = element.split(".");

      if ("first_name" == requiredElement[1]){
        newUpdatedAccount["person"]["first_name"] = await _userManager.getValue("allUsers", "first_name");
      }

      if ("last_name" == requiredElement[1]){
        newUpdatedAccount["person"]["last_name"] = await _userManager.getValue("allUsers", "last_name");
      }

      if ("dob" == requiredElement[1]){
        if (!personDobUpdated){
          newUpdatedAccount["person"]["dob"] = {
            "day":dayBirth,
            "month":monthBirth,
            "year":yearBirth
          };
          personDobUpdated = true;
        }
      }

      if ("email" == requiredElement[1]){
        newUpdatedAccount["person"]["email"] = emailController.text.trim();
      }

      if ("address" == requiredElement[1]){
        if(!personAddressUpdated){
          newUpdatedAccount["person"]["address"] = {
            "city":personCityController.text.trim(),
            "postal_code":personPostalCodeController.text.trim(),
            "line1":personStreetNumberController.text.trim() + " " + personStreetNameController.text.trim(),
          };
          personAddressUpdated = true;
        }
      }

      if ("verification" == requiredElement[1]){
        if ("document" == requiredElement[2]){
          var tmpFileNameIdFront = "id_front_" + uid + "."+ filenameRecto.split(".").last;
          var tmpFileNameIdBack = "id_back_" + uid + "." + filenameVerso.split(".").last;

          await ref.child("saved_users_files/$uid/$tmpFileNameIdFront").putFile(imageRecto!);
          await ref.child("saved_users_files/$uid/$tmpFileNameIdBack").putFile(imageVerso!);

          if (newUpdatedAccount["person"]["verification"] == null){
            newUpdatedAccount["person"]["verification"] =
            {
              "document":{
                "front":tmpFileNameIdFront,
                "back":tmpFileNameIdBack,
              }
            };
          } else {
            newUpdatedAccount["person"]["verification"].putIfAbsent("document", () =>
            {
              "front":tmpFileNameIdFront,
              "back":tmpFileNameIdBack,
            }
            );
          }
        }

        if ("additional_document" == requiredElement[2]){
          var tmpFileNameHomeProof = "additional_document_" + uid + "." + filenameDocument.split(".").last;
          await ref.child("saved_users_files/$uid/$tmpFileNameHomeProof").putFile(document!);

          if (newUpdatedAccount["person"]["verification"] == null){
            newUpdatedAccount["person"]["verification"] =
            {
              "additional_document":{
                "front":tmpFileNameHomeProof,
              }
            };
          } else {
            newUpdatedAccount["person"]["verification"].putIfAbsent("additional_document", () =>
            {
              "front":tmpFileNameHomeProof,
            }
            );
          }
        }
      }
    }

    for (String element in bank_account){
      List requiredElement = element.split(".");
      if ("account_holder_name" == requiredElement[1]){

        List listOfNeededParams = ["first_name","last_name"];
        Map tmpValues = await _userManager.getMultipleValues("allUsers", listOfNeededParams);

        String firstName = tmpValues[listOfNeededParams[0]];
        String lastName = tmpValues[listOfNeededParams[1]];

        //String firstName = await _userManager.getValueFromDataBase("allUsers", "first_name");
        //String lastName = await _userManager.getValueFromDataBase("allUsers", "last_name");

        newUpdatedAccount["bank_account"]["account_holder_name"] = firstName + " " + lastName;
      }

      if ("account_number" == requiredElement[1]){
        newUpdatedAccount["bank_account"]["account_number"] = ibanController.text.trim();
      }
    }

    //debugPrint("DEBUG_LOG UPDATING STRIPE ACCOUNT, newUpdatedAccount=" + newUpdatedAccount.toString());
    return newUpdatedAccount;
  }

  Future<void> setChanges() async {
    Map tmpNewUpdatedAccount = await buildMapResponseForUpdate();
    onFormConfirmation(tmpNewUpdatedAccount, newUpdateFormValidated);
  }

  Widget Title(String title, double width, double height){
    return Column(
      children: [
        Container(
          width: width,
          height: height,
          padding: const EdgeInsets.all(2.0),
          decoration: BoxDecoration(
            color: Colors.pinkAccent,
            borderRadius: BorderRadius.circular(10),
          ),
          child: FittedBox(
            child: Text(
                title,
                style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.bold
                )
            ),
          ),
        ),
        SizedBox(height: 20),
      ],
    );
  }

  Widget CompanyTaxId(){
    return Column(
      children: [
        Title(required_fields["company.tax_id"][0], 180, 30),
        Padding(
          padding: EdgeInsets.only(left: 30, right: 30),
          child: Container(
            decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(30),
                boxShadow: [
                  BoxShadow(
                      color: Colors.grey,
                      blurRadius: 4,
                      offset: Offset(0,3)
                  ),
                ]
            ),
            child:Padding(
              padding: const EdgeInsets.only(left: 10),
              child: TextField(
                controller: codeController,
                decoration: InputDecoration(
                  hintText: required_fields["company.tax_id"][1],
                  hintStyle: TextStyle(
                      fontSize: 15,
                      fontStyle: FontStyle.italic
                  ),
                  contentPadding: EdgeInsets.all(10),
                  border: InputBorder.none,
                ),
              ),
            ),
          ),
        ),
        SizedBox(height: 50),
      ],
    );
  }

  Widget CompanyName(){
    return Column(
      children: [
        Title(required_fields["company.name"][0], 240, 30),
        Padding(
          padding: EdgeInsets.only(left: 30, right: 30),
          child: Container(
            decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(30),
                boxShadow: [
                  BoxShadow(
                      color: Colors.grey,
                      blurRadius: 4,
                      offset: Offset(0,3)
                  ),
                ]
            ),
            child:Padding(
              padding: const EdgeInsets.only(left: 10),
              child: TextField(
                controller: companyNameController,
                decoration: InputDecoration(
                  hintText: required_fields["company.name"][1],
                  hintStyle: TextStyle(
                    fontSize: 15,
                    fontStyle: FontStyle.italic,
                  ),
                  contentPadding: EdgeInsets.all(10),
                  border: InputBorder.none,
                ),
              ),
            ),
          ),
        ),
        SizedBox(height: 50),
      ],
    );
  }

  Widget CompanyMcc(BuildContext context){
    return Column(
      children: [
        Title(required_fields["business_profile.mcc"][0], 160, 30),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
                height: 50,
                width: 50,
                child: Checkbox(
                  checkColor: Colors.white,
                  value: true,
                  onChanged: (bool? value) {
                    /*AlertDialogManager.shortDialog(
                        context,
                        required_fields["business_profile.mcc"][1],
                        contentMessage: required_fields["business_profile.mcc"][2]);*/
                  },
                )
            ),
            RichText(
              text: TextSpan(
                text: required_fields["business_profile.mcc"][3],
                children: <TextSpan>[
                  TextSpan(
                    text:required_fields["business_profile.mcc"][4],
                    style: TextStyle(
                      color: Colors.black,
                      //decoration: TextDecoration.underline,
                      //decorationThickness: 2,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  )
                ],
                style: GoogleFonts.poppins(
                  color: Colors.black,
                  fontSize: 15,
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: 50)
      ],
    );
  }

  Widget AddressCity(bool isCompany){
    return Column(
      children: [
        Padding(
          padding: EdgeInsets.only(left: 30, right: 30),
          child: Container(
            decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(30),
                boxShadow: [
                  BoxShadow(
                      color: Colors.grey,
                      blurRadius: 4,
                      offset: Offset(0,3)
                  ),
                ]
            ),
            child:Padding(
              padding: const EdgeInsets.only(left: 10),
              child: TextField(
                controller: isCompany ? cityController : personCityController,
                decoration: InputDecoration(
                  hintText: isCompany ? required_fields["company.address.city"][0] : person_required_fields["address_city"][0],
                  hintStyle: TextStyle(
                      fontSize: 15,
                      fontStyle: FontStyle.italic
                  ),
                  contentPadding: EdgeInsets.all(10),
                  border: InputBorder.none,
                ),
              ),
            ),
          ),
        ),
        SizedBox(height: 20),
      ],
    );
  }

  Widget VerificationDocument(bool isCompany){
    return Column(
      children: [
        Title(
            isCompany ? required_fields["company.verification.document"][0] : person_required_fields["additional_document"][0],
            isCompany ? 120 : 220,
            30
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: () async {
                //XFile? localDocument = null;
                //localDocument = await _picker.pickImage(source: ImageSource.gallery);

                FilePickerResult? localDocument = await FilePicker.platform.pickFiles(type: FileType.custom, allowedExtensions: ['png','jpg','pdf']);

                if (localDocument != null){
                  if(isCompany){
                    //documentCompanyExistence = File(localDocument.path);
                    documentCompanyExistence = File(localDocument.files.first.path!);
                  }
                  else{
                    document = File(localDocument.files.first.path!/*localDocument.path*/);
                  }

                  setState(() {
                    personDob = false;
                    if(isCompany){
                      filenameDocumentCompanyExistence = basename(documentCompanyExistence!.path);
                    }
                    else{
                      filenameDocument = basename(document!.path);
                    }
                  });
                }
              },
              child: Icon(Icons.add),
              style: ElevatedButton.styleFrom(
                shape: CircleBorder(),
                primary: Colors.green,
              ),
            ),
            Container(
              width: 200,
              child: Wrap(
                children: [
                  Text(
                      isCompany ?
                      (filenameDocumentCompanyExistence.isEmpty ? required_fields["company.verification.document"][1] : filenameDocumentCompanyExistence)
                          :
                      (filenameDocument.isEmpty ? person_required_fields["additional_document"][1] : filenameDocument),
                      style: GoogleFonts.poppins(
                        color: Colors.black,
                        fontSize: 14,
                      )
                  ),
                ],
              ),
            )
          ],
        ),
        SizedBox(height: 50),
      ],
    );
  }

  Widget PostalCode(bool isCompany){
    return Column(
      children: [
        Padding(
          padding: EdgeInsets.only(left: 30, right: 30),
          child: Container(
            decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(30),
                boxShadow: [
                  BoxShadow(
                      color: Colors.grey,
                      blurRadius: 4,
                      offset: Offset(0,3)
                  ),
                ]
            ),
            child:Padding(
              padding: const EdgeInsets.only(left: 10),
              child: TextField(
                controller: isCompany ? postalCodeController : personPostalCodeController,
                decoration: InputDecoration(
                  hintText: isCompany ? required_fields["company.address.postal_code"][0] : person_required_fields["address_postal_code"][0],
                  hintStyle: TextStyle(
                      fontSize: 15,
                      fontStyle: FontStyle.italic
                  ),
                  contentPadding: EdgeInsets.all(10),
                  border: InputBorder.none,
                ),
              ),
            ),
          ),
        ),
        SizedBox(height: 20),
      ],
    );
  }

  Widget AddressLine1(bool isCompany){
    return Column(
      children: [
        Padding(
          padding: EdgeInsets.only(left: 30, right: 30),
          child: Container(
            decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(30),
                boxShadow: [
                  BoxShadow(
                      color: Colors.grey,
                      blurRadius: 4,
                      offset: Offset(0,3)
                  ),
                ]
            ),
            child:Padding(
              padding: const EdgeInsets.only(left: 10),
              child: TextField(
                controller: isCompany ? streetNumberController : personStreetNumberController,
                decoration: InputDecoration(
                  hintText: isCompany ? required_fields["company.address.line1"][0] : person_required_fields["address_line1"][0],
                  hintStyle: TextStyle(
                      fontSize: 15,
                      fontStyle: FontStyle.italic
                  ),
                  contentPadding: EdgeInsets.all(10),
                  border: InputBorder.none,
                ),
              ),
            ),
          ),
        ),
        SizedBox(height: 20),
        Padding(
          padding: EdgeInsets.only(left: 30, right: 30),
          child: Container(
            decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(30),
                boxShadow: [
                  BoxShadow(
                      color: Colors.grey,
                      blurRadius: 4,
                      offset: Offset(0,3)
                  ),
                ]
            ),
            child:Padding(
              padding: const EdgeInsets.only(left: 10),
              child: TextField(
                controller: isCompany ? streetNameController : personStreetNameController,
                decoration: InputDecoration(
                  hintText: isCompany ? required_fields["company.address.line1"][1] : person_required_fields["address_line1"][1],
                  hintStyle: TextStyle(
                      fontSize: 15,
                      fontStyle: FontStyle.italic
                  ),
                  contentPadding: EdgeInsets.all(10),
                  border: InputBorder.none,
                ),
              ),
            ),
          ),
        ),
        SizedBox(height: 20),
      ],
    );
  }

  Widget CompanyPhone(){
    return Column(
      children: [
        Title(required_fields["company.phone"][0], 260, 30),
        Padding(
          padding: EdgeInsets.only(left: 30, right: 30),
          child: Container(
            decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(30),
                boxShadow: [
                  BoxShadow(
                      color: Colors.grey,
                      blurRadius: 4,
                      offset: Offset(0,3)
                  ),
                ]
            ),
            child:Padding(
              padding: const EdgeInsets.only(left: 10),
              child: TextField(
                controller: companyPhoneController,
                decoration: InputDecoration(
                  hintText: required_fields["company.name"][1],
                  hintStyle: TextStyle(
                    fontSize: 15,
                    fontStyle: FontStyle.italic,
                  ),
                  contentPadding: EdgeInsets.all(10),
                  border: InputBorder.none,
                ),
              ),
            ),
          ),
        ),
        SizedBox(height: 50),
      ],
    );
  }

  Widget CompanyExternalAccount(){
    return Column(
      children: [
        Title(required_fields["external_account"][0], 260, 30),
        Padding(
          padding: EdgeInsets.only(left: 30, right: 30),
          child: Container(
            decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(30),
                boxShadow: [
                  BoxShadow(
                      color: Colors.grey,
                      blurRadius: 4,
                      offset: Offset(0,3)
                  ),
                ]
            ),
            child:Padding(
              padding: const EdgeInsets.only(left: 10),
              child: TextField(
                controller: ibanController,
                decoration: InputDecoration(
                  hintText: required_fields["external_account"][1],
                  hintStyle: TextStyle(
                      fontSize: 15,
                      fontStyle: FontStyle.italic
                  ),
                  contentPadding: EdgeInsets.all(10),
                  border: InputBorder.none,
                ),
              ),
            ),
          ),
        ),
        SizedBox(height: 50),
      ],
    );
  }

  /*PERSONS UPDATES*/

  Widget PersonVerificationDocumentIdentity(){
    return Column(
      children: [
        Title(person_required_fields["document"][0], 180, 30),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: () async {
                //XFile? localImageRecto = null;
                //localImageRecto = await _picker.pickImage(source: ImageSource.gallery);

                FilePickerResult? localImageRecto = await FilePicker.platform.pickFiles(type: FileType.custom, allowedExtensions: ['png','jpg','pdf']);

                if (localImageRecto != null){
                  imageRecto = File(localImageRecto.files.first.path!);
                  setState(() {
                    personDob = false;
                    filenameRecto = basename(imageRecto!.path);
                  });
                }

              },
              child: Icon(Icons.add),
              style: ElevatedButton.styleFrom(
                shape: CircleBorder(),
                primary: Colors.green,
              ),
            ),
            Text(
                filenameRecto.isEmpty ? person_required_fields["document"][1] : filenameRecto,
                overflow: TextOverflow.ellipsis
            )
          ],
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: () async {
                //XFile? localImageVerso = null;
                //localImageVerso = await _picker.pickImage(source: ImageSource.gallery);

                FilePickerResult? localImageVerso = await FilePicker.platform.pickFiles(type: FileType.custom, allowedExtensions: ['png','jpg','pdf']);

                if (localImageVerso != null){
                  imageVerso = File(localImageVerso.files.first.path!);
                  setState(() {
                    personDob = false;
                    filenameVerso = basename(imageVerso!.path);
                  });
                }

              },
              child: Icon(Icons.add),
              style: ElevatedButton.styleFrom(
                shape: CircleBorder(),
                primary: Colors.green,
              ),
            ),
            Text(
              filenameVerso.isEmpty ? person_required_fields["document"][2] : filenameVerso,
              overflow: TextOverflow.ellipsis,
            )
          ],
        ),
        SizedBox(height: 50),
      ],
    );
  }

  Widget PersonEmail(){
    return Column(
      children: [
        Title(person_required_fields["email"][0], 100, 30),
        Padding(
          padding: EdgeInsets.only(left: 30, right: 30),
          child: Container(
            decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(30),
                boxShadow: [
                  BoxShadow(
                      color: Colors.grey,
                      blurRadius: 4,
                      offset: Offset(0,3)
                  ),
                ]
            ),
            child:Padding(
              padding: const EdgeInsets.only(left: 10),
              child: TextField(
                controller: emailController,
                decoration: InputDecoration(
                  hintText: person_required_fields["email"][1],
                  hintStyle: TextStyle(
                      fontSize: 15,
                      fontStyle: FontStyle.italic
                  ),
                  contentPadding: EdgeInsets.all(10),
                  border: InputBorder.none,
                ),
              ),
            ),
          ),
        ),
        SizedBox(height: 50),
      ],
    );
  }

  Widget PersonAccountNumber(){
    return Column(
      children: [
        Title(person_required_fields["account_number"][0], 260, 30),
        Padding(
          padding: EdgeInsets.only(left: 30, right: 30),
          child: Container(
            decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(30),
                boxShadow: [
                  BoxShadow(
                      color: Colors.grey,
                      blurRadius: 4,
                      offset: Offset(0,3)
                  ),
                ]
            ),
            child:Padding(
              padding: const EdgeInsets.only(left: 10),
              child: TextField(
                controller: ibanController,
                decoration: InputDecoration(
                  hintText: person_required_fields["account_number"][1],
                  hintStyle: TextStyle(
                      fontSize: 15,
                      fontStyle: FontStyle.italic
                  ),
                  contentPadding: EdgeInsets.all(10),
                  border: InputBorder.none,
                ),
              ),
            ),
          ),
        ),
        SizedBox(height: 50),
      ],
    );
  }

  Widget PersonDob(){
    List<String> listOfYears = [];
    listOfYears.add("----");
    int startYear = DateTime.now().year;
    for (int i=0; i<150;i++){
      listOfYears.add((startYear).toString());
      startYear--;
    }
    return Column(
      children: [
        Title(person_required_fields["dob"][0], 190, 30),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Column(
              children: [
                Container(
                  width: 50,
                  height: 20,
                  //color: Colors.pinkAccent,
                  child: Center(
                    child: Text(person_required_fields["dob"][1],
                        style: GoogleFonts.poppins(
                          color: Colors.black,
                          fontSize: 15,
                        )
                    ),
                  ),
                ),
                SizedBox(height: 5),
                Container(
                  width: 70,
                  decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(30),
                      boxShadow: [
                        BoxShadow(
                            color: Colors.grey,
                            blurRadius: 4,
                            offset: Offset(0,3)
                        ),
                      ]
                  ),
                  child: Center(
                    child: DropdownButton<String>(
                      value: dayBirth,
                      icon: const Icon(Icons.arrow_drop_down),
                      elevation: 16,
                      style: const TextStyle(color: Colors.deepPurple),
                      underline: Container(
                        color: Colors.transparent,
                      ),
                      onChanged: (String? newValue) {
                        setState(() {
                          personDob = false;
                          dayBirth = newValue!;
                        });
                      },
                      items: <String>[
                        '--', '01', '02', '03', '04', '05','06', '07', '08', '09', '10',
                        '11', '12', '13', '14', '15','16', '17', '18', '19', '20', '21',
                        '22', '23', '24', '25','26', '27', '28', '29', '30', '31'

                      ]
                          .map<DropdownMenuItem<String>>((String value) {
                        return DropdownMenuItem<String>(
                          value: value,
                          child: Text(value,
                              style: GoogleFonts.poppins(
                                color: Colors.black,
                                fontSize: 18,
                              )),
                        );
                      }).toList(),
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(width: 10),
            Column(
              children: [
                Container(
                  width: 50,
                  height: 20,
                  //color: Colors.pinkAccent,
                  child: Center(
                    child: Text(person_required_fields["dob"][2],
                        style: GoogleFonts.poppins(
                          color: Colors.black,
                          fontSize: 15,
                        )
                    ),
                  ),
                ),
                SizedBox(height: 5),
                Container(
                  width: 70,
                  decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(30),
                      boxShadow: [
                        BoxShadow(
                            color: Colors.grey,
                            blurRadius: 4,
                            offset: Offset(0,3)
                        ),
                      ]
                  ),
                  child: Center(
                    child: DropdownButton<String>(
                      value: monthBirth,
                      icon: const Icon(Icons.arrow_drop_down),
                      elevation: 16,
                      style: const TextStyle(color: Colors.deepPurple),
                      underline: Container(
                        color: Colors.transparent,
                      ),
                      onChanged: (String? newValue) {
                        setState(() {
                          personDob = false;
                          monthBirth = newValue!;
                        });
                      },
                      items: <String>[
                        '--', '01', '02', '03', '04', '05','06', '07', '08', '09', '10','11', '12'
                      ]
                          .map<DropdownMenuItem<String>>((String value) {
                        return DropdownMenuItem<String>(
                          value: value,
                          child: Text(value,style: GoogleFonts.poppins(
                            color: Colors.black,
                            fontSize: 18,
                          )),
                        );
                      }).toList(),
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(width: 10),
            Column(
              children: [
                Container(
                  width: 50,
                  height: 20,
                  //color: Colors.pinkAccent,
                  child: Center(
                    child: Text(person_required_fields["dob"][3],
                        style: GoogleFonts.poppins(
                          color: Colors.black,
                          fontSize: 15,
                        )
                    ),
                  ),
                ),
                SizedBox(height: 5),
                Container(
                  width: 90,
                  decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(30),
                      boxShadow: [
                        BoxShadow(
                            color: Colors.grey,
                            blurRadius: 4,
                            offset: Offset(0,3)
                        ),
                      ]
                  ),
                  child: Center(
                    child: DropdownButton<String>(
                      value: yearBirth,
                      icon: const Icon(Icons.arrow_drop_down),
                      elevation: 16,
                      style: const TextStyle(color: Colors.deepPurple),
                      underline: Container(
                        color: Colors.transparent,
                      ),
                      onChanged: (String? newValue) {
                        setState(() {
                          personDob = false;
                          yearBirth = newValue!;
                        });
                      },
                      items: listOfYears.map<DropdownMenuItem<String>>((String value) {
                        return DropdownMenuItem<String>(
                          value: value,
                          child: Text(value,style: GoogleFonts.poppins(
                            color: Colors.black,
                            fontSize: 18,
                          )),
                        );
                      }).toList(),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
        SizedBox(height: 50),
      ],
    );
  }

/*Widget toto3(){
    return Container();
  }

  Widget toto4(){
    return Container();
  }

  Widget toto5(){
    return Container();
  }

  Widget toto3(){
    return Container();
  }

  Widget toto4(){
    return Container();
  }

  Widget toto5(){
    return Container();
  }

  Widget toto3(){
    return Container();
  }

  Widget toto4(){
    return Container();
  }

  Widget toto5(){
    return Container();
  }*/


}