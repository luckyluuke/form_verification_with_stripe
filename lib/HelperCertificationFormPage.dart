import 'dart:convert';
import 'dart:io';

//import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:country_code_picker/country_code_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
//import 'package:form_verification_with_stripe/AlertDialogManager.dart';
import 'package:form_verification_with_stripe/HelperCertificationFormTemplates.dart';
import 'package:form_verification_with_stripe/UserManager.dart';
import 'package:form_verification_with_stripe/enums.dart';
import 'package:path/path.dart';
import 'package:url_launcher/url_launcher.dart';

class HelperCertificationFormPage extends StatefulWidget {

  HelperCertificationFormPage({bool disableAppBar = false}){
    this.disableAppBar = disableAppBar;
  }

  bool? disableAppBar;

  @override
  _HelperCertificationFormPageState createState() => _HelperCertificationFormPageState();
}


class _HelperCertificationFormPageState extends State<HelperCertificationFormPage> {

  String selectedPage = "introduction_page";
  bool isLoading = false;
  var allStripeConnectAccountsCollection = FirebaseFirestore.instance.collection("allStripeConnectAccounts");

  late TextEditingController emailController = TextEditingController();
  late TextEditingController ibanController = TextEditingController();
  late TextEditingController codeController = TextEditingController();
  late TextEditingController phoneController = TextEditingController();
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
  String countryCode = "FR";
  String dialCodeDigits = "+33";
  String dayBirth = "--";
  String monthBirth = "--";
  String yearBirth = "----";
  String accountId = "";
  UserManager _userManager = UserManager();
  Map<String,dynamic> newUpdatedAccount = {};
  bool newUpdateFormValidated = false;


  String fieldsAreCorrect(){

    if(_userManager.phoneNumber == null){
      if (phoneController.text.trim().isEmpty){
        return "Tu dois saisir ton numéro de téléphone portable !";
      }
    }else{
      if (emailController.text.trim().isEmpty){
        return "Tu dois remplir le champs Email !";
      }

      if (!emailController.text.trim().contains("@")){
        return "Il manque un \'@\' dans ton email !";
      }
    }


    if ("--" == dayBirth){
      return "Tu dois saisir ton JOUR de naissance";
    }

    if ("--" == monthBirth){
      return "Tu dois saisir ton MOIS de naissance";
    }

    if ("----" == yearBirth){
      return "Tu dois saisir ton ANNEE de naissance";
    }

    if (personCityController.text.trim().isEmpty){
      return "Tu dois remplir le champs VILLE !";
    }

    if (postalCodeController.text.trim().isEmpty){
      return "Tu dois remplir le champs CODE POSTAL !";
    }

    if (streetNumberController.text.trim().isEmpty){
      return "Tu dois remplir le champs NUMERO DE RUE/VOIE !";
    }

    if (int.tryParse(streetNumberController.text.trim()) == null) {
      return "Le champs NUMERO DE RUE/VOIE doit uniquement être un nombre !";
    }

    if (streetNameController.text.trim().isEmpty){
      return "Tu dois remplir le champs NOM DE RUE/VOIE !";
    }

    if (!RegExp(r'^[a-zA-Z ]+$').hasMatch(streetNameController.text)){
      return "Le champs NOM DE RUE/VOIE doit contenir uniquement que des lettres";
    }

    if (ibanController.text.trim().isEmpty){
      return "Tu dois remplir le champs IBAN !";
    }

    if (imageRecto == null){
      return "Il manque la photo RECTO de ta carte d'identité";
    }

    if (imageVerso == null){
      return "Il manque la photo VERSO de ta carte d'identité";
    }

    if (document == null){
      return "Il manque ton JUSTIFICATIF DE DOMICILE";
    }

    if (!g_countriesCurrenciesRates.keys.contains(countryCode)){
      return "Le pays selectionné n'est pas éligible à la monétisation pour le moment.";
    }



    //Do not delete code below. Reference to other needed fields.

    /*if (codeController.text.trim().isEmpty){
      return "Il manque ton numéro SIREN !";
    }

    if (companyNameController.text.trim().isEmpty){
      return "Il manque ta DENOMINATION/RAISON SOCIALE !";
    }

    if (documentCompanyExistence == null){
      return "Il manque ton extrait KBIS";
    }*/

    return "SUCCESS";
  }

  Future<Map> getAccountState () async {

    HttpsCallable firstCallable = await FirebaseFunctions.instanceFor(app: FirebaseFunctions.instance.app, region: "europe-west1").httpsCallable("getResultWhere");
    var result = await firstCallable.call(
        {
          'limit':1,
          'collectionName':'allStripeConnectAccounts',
          'comparedField':'userId',
          'comparisonSign': '==',
          'toValue':_userManager.userId
        }
    );

    final accountExists = (result.data == null ? false : true);
    if (accountExists){
      debugPrint("Info: User StripeAccount already exists");
      accountId = result.data["0"]["accountId"];
    }else{
      debugPrint("Info: A new StripeAccount will be created for user="+ _userManager.userId!);
    }

    countryCode  =  await _userManager.getValue("allUsers", "countryCode");

    HttpsCallable callable = await FirebaseFunctions.instanceFor(app: FirebaseFunctions.instance.app, region: "europe-west1").httpsCallable('getCustomConnectAccountRequirements');
    final resp = await callable.call(<String, dynamic>{
      "accountId": accountId,
      "countryCode": countryCode,
    });

    //debugPrint("DEBUG_LOG getAccountState="+ resp.data.toString());
    return resp.data;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: widget.disableAppBar! ? null : AppBar(
        title: FittedBox(
          child: Text("Certification de compte ",
            textAlign: TextAlign.center,
            style: GoogleFonts.nunito(
              color: Colors.black,
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.yellow,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_rounded ,
            color: Colors.black,
            size: 30,
          ),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      body: FutureBuilder<Map>(
          future: getAccountState(),
          builder: (context, AsyncSnapshot<Map>? snapshot) {
            //debugPrint("DEBUG_LOG selectedPage=" + selectedPage);

          if (snapshot != null && snapshot.hasData){

            List listOfRequiredFields = snapshot.data!["needed_fields"];
            String bankAccountToken = snapshot.data!["bank_account_token"];
            List personsToken = snapshot.data!["persons_token"];

            return SingleChildScrollView(
              child: (("introduction_page" == selectedPage) && (accountId == "")) ?
              IntroductionPage()
                  :
              (("form_page" == selectedPage) || ((accountId != "") && ("confirmation_page" != selectedPage))) ? FormPage(listOfRequiredFields,bankAccountToken,personsToken,context) : ConfirmationPage(),
            );
          }
          else
          {
            return Center(
              child: SizedBox(
                  width: 40.0,
                  height: 40.0,
                  child: const CircularProgressIndicator(
                    backgroundColor: Colors.yellow,
                  )
              )
            );
          }
        }
      ),
    );
  }

  Widget ConfirmationPage(){
    return Column(
        children: [
          Container(
            padding: EdgeInsets.all(30),
            child: Center(
                child: Image.asset("images/validated_action.png")
            ),
          ),
          SizedBox(height:10),
          Container(
            padding: EdgeInsets.only(left: 10.0, right: 10.0),
            child: Text(
                "Félicitations ! Ton formulaire a été envoyé ! Nous allons traiter les informations que tu nous as fourni dans les plus brefs délais, puis nous t'enverrons une réponse par mail/notification.",
              style: GoogleFonts.poppins(
              color: Colors.blue,
              fontSize: 17,
              fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            )
          )
        ]
    );
  }

  Widget FormPage(
      List listOfRequiredFields,
      String bankAccountToken,
      List personsToken,
      BuildContext context){

    List<String> listOfYears = [];
    listOfYears.add("----");
    int startYear = DateTime.now().year;
    for (int i=0; i<150;i++){
      listOfYears.add((startYear).toString());
      startYear--;
    }
    void onFormConfirmation(_newUpdatedAccount,_newUpdateFormValidated){
        newUpdatedAccount = _newUpdatedAccount;
        newUpdateFormValidated = _newUpdateFormValidated;
    }

    //debugPrint("DEBUG_LOG listOfRequiredFields=" + listOfRequiredFields.toString());
    return Column(
        children: [
          SizedBox(height: 20),
          Align(
            alignment: Alignment.center,
            child: FittedBox(
              child: Text(
                (accountId != "") ? "A COMPLETER" : "CERTIFICATION SIMPLE ET RAPIDE",
                style: GoogleFonts.poppins(
                  color: Colors.blue,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(left: 8.0, right: 8.0),
            child: Align(
              alignment: Alignment.center,
              child: Text(
                (accountId != "") ?
                "Il te manque encore des choses 😊"
                :
                "Pour commencer, dis-nous en plus sur toi 😊"
                ,
                style: GoogleFonts.poppins(
                  color: Colors.blue,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
          SizedBox(height: 30),
          /*(accountId != "") ?
          HelperCertificationFormTemplates(
              onFormConfirmation,
              listOfRequiredFields,
              bankAccountToken,
              personsToken,
              accountId
          )
          :*/
          Column(
            children: [
              Container(
                width: (_userManager.phoneNumber != null) ? 100 : 190,
                height: 30,
                padding: const EdgeInsets.all(3.0),
                decoration: BoxDecoration(
                  color: Colors.pinkAccent,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: FittedBox(
                  child: Text(
                      (_userManager.phoneNumber != null) ? "Ton Email" : "Ton numéro de téléphone",
                      style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontSize: 17,
                          fontWeight: FontWeight.bold
                      )
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
                      controller: (_userManager.phoneNumber != null) ? emailController : phoneController,
                      decoration: InputDecoration(
                        hintText: (_userManager.phoneNumber != null) ? 'EMAIL' : 'N° DE TELEPHONE PORTABLE',
                        hintStyle: TextStyle(
                            fontSize: 15,
                            fontStyle: FontStyle.italic
                        ),
                        contentPadding: EdgeInsets.all(10),
                        border: InputBorder.none,
                      ),
                      keyboardType: (_userManager.phoneNumber != null)  ? null : TextInputType.number,
                    ),
                  ),
                ),
              ),
              SizedBox(height: 50),
              Container(
                width: 190,
                height: 30,
                padding: const EdgeInsets.all(3.0),
                decoration: BoxDecoration(
                  color: Colors.pinkAccent,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: FittedBox(
                  child: Text(
                      "Ta date de naissance",
                      style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontSize: 25,
                          fontWeight: FontWeight.bold
                      )
                  ),
                ),
              ),
              SizedBox(height: 20),
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
                          child: Text("Jour",
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
                          child: Text("Mois",
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
                          child: Text("Année",
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
              Container(
                width: 120,
                height: 30,
                padding: const EdgeInsets.all(3.0),
                decoration: BoxDecoration(
                  color: Colors.pinkAccent,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: FittedBox(
                  child: Text(
                      "Ton adresse",
                      style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontSize: 25,
                          fontWeight: FontWeight.bold
                      )
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
                  child:CountryCodePicker(
                      onChanged: (country){
                        setState(() {
                          countryCode = country.code!;
                          dialCodeDigits = country.dialCode!;
                        });
                      },
                      initialSelection: "FR",
                      showCountryOnly: false,
                      showOnlyCountryWhenClosed: false,
                      favorite: ["+33","FR"],
                      searchDecoration: InputDecoration(
                        hintText: 'Rechercher',
                        contentPadding: EdgeInsets.all(10),
                      ),
                      builder: (context) {
                        String? urlImage = context!.flagUri;
                        return Padding(
                          padding: const EdgeInsets.only(left:20,right:20),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text("PAYS",
                                  style: TextStyle(
                                      color: Colors.grey[700],
                                      fontSize: 15,
                                      fontStyle: FontStyle.italic
                                  )),
                              Container(
                                width: 40,
                                height: 50,
                                child: Image.asset(
                                  urlImage!,
                                  package: 'country_code_picker',
                                ),
                              ),

                              Icon(
                                Icons.arrow_drop_down,
                                color: Colors.grey[800],
                                size: 40,
                              ),
                            ],
                          ),
                        );
                      }

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
                      controller: personCityController,
                      decoration: InputDecoration(
                        hintText: 'VILLE',
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
                      controller: postalCodeController,
                      decoration: InputDecoration(
                        hintText: 'CODE POSTAL',
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
                      controller: streetNumberController,
                      decoration: InputDecoration(
                        hintText: 'NUMERO DE RUE/VOIE',
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
                      controller: streetNameController,
                      decoration: InputDecoration(
                        hintText: 'NOM DE RUE/VOIE',
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
              Container(
                width: 260,
                height: 30,
                padding: const EdgeInsets.all(2.0),
                decoration: BoxDecoration(
                  color: Colors.pinkAccent,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: FittedBox(
                  child: Text(
                      "Ton IBAN (Coordonnées bancaires)",
                      style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontSize: 17,
                          fontWeight: FontWeight.bold
                      )),
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
                      controller: ibanController,
                      decoration: InputDecoration(
                        hintText: 'IBAN',
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
              Container(
                width: 180,
                height: 30,
                padding: const EdgeInsets.all(2.0),
                decoration: BoxDecoration(
                  color: Colors.pinkAccent,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: FittedBox(
                  child: Text(
                      "Ta carte d'identité",
                      style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontSize: 17,
                          fontWeight: FontWeight.bold
                      )
                  ),
                ),
              ),
              SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton(
                    onPressed: () async {

                      FilePickerResult? resultImageRecto = await FilePicker.platform.pickFiles(type: FileType.custom, allowedExtensions: ['png','jpg','pdf']);

                      if (resultImageRecto != null){
                        imageRecto = File(resultImageRecto.files.first.path!);
                        setState(() {
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
                      filenameRecto.isEmpty ? "RECTO" : filenameRecto,
                      overflow: TextOverflow.ellipsis
                  )
                ],
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton(
                    onPressed: () async {

                      FilePickerResult? resultImageVerso = await FilePicker.platform.pickFiles(type: FileType.custom, allowedExtensions: ['png','jpg','pdf']);

                      if (resultImageVerso != null){
                        imageVerso = File(resultImageVerso.files.first.path!);
                        setState(() {
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
                    filenameVerso.isEmpty ? "VERSO" : filenameVerso,
                    overflow: TextOverflow.ellipsis,
                  )
                ],
              ),
              SizedBox(height: 50),
              Container(
                width: 220,
                height: 30,
                padding: const EdgeInsets.all(2.0),
                decoration: BoxDecoration(
                  color: Colors.pinkAccent,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: FittedBox(
                  child: Text(
                      "Justificatif de domicile",
                      style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontSize: 17,
                          fontWeight: FontWeight.bold
                      )
                  ),
                ),
              ),
              SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton(
                    onPressed: () async {

                      FilePickerResult? result = await FilePicker.platform.pickFiles(type: FileType.custom, allowedExtensions: ['png','jpg','pdf']);

                      if (result != null){
                        document = File(result.files.first.path!);
                        setState(() {
                          filenameDocument = basename(document!.path);
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
                            filenameDocument.isEmpty ? "Exemple: facture de téléphone, d'électricité, etc..." : filenameDocument,
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
              SizedBox(height: 40),
              Divider(
                thickness: 5,
                color: Colors.black,
              ),
              SizedBox(height: 40),
              Padding(
                padding: const EdgeInsets.only(left: 8.0, right: 8.0),
                child: Align(
                  alignment: Alignment.center,
                  child: Text(
                    "Enfin, si tu possèdes un compte d'indépendant ou d'auto-entrepreneur, dis nous en plus 😊",
                    style: GoogleFonts.poppins(
                      color: Colors.blue,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
              SizedBox(height: 40),
              Column(
                children: [
                  Container(
                    width: 180,
                    height: 30,
                    padding: const EdgeInsets.all(2.0),
                    decoration: BoxDecoration(
                      color: Colors.pinkAccent,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: FittedBox(
                      child: Text(
                          "Ton numéro SIREN",
                          style: GoogleFonts.poppins(
                              color: Colors.white,
                              fontSize: 17,
                              fontWeight: FontWeight.bold
                          )
                      ),
                    ),
                  ),
                  SizedBox(height: 2),
                  Container(
                      child: Text(
                        "(facultatif)",
                          style: GoogleFonts.poppins(
                              color: Colors.orange,
                              fontSize: 17,
                              fontWeight: FontWeight.bold
                          )
                      )
                  )
                ],
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
                      controller: codeController,
                      decoration: InputDecoration(
                        hintText: 'SIREN',
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
              Column(
                children: [
                  Container(
                    width: 240,
                    height: 30,
                    padding: const EdgeInsets.all(2.0),
                    decoration: BoxDecoration(
                      color: Colors.pinkAccent,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: FittedBox(
                      child: Text(
                        "Dénomination/Raison sociale",
                        style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontSize: 17,
                            fontWeight: FontWeight.bold
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                  SizedBox(height: 2),
                  Container(
                      child: Text(
                          "(facultatif)",
                          style: GoogleFonts.poppins(
                              color: Colors.orange,
                              fontSize: 17,
                              fontWeight: FontWeight.bold
                          )
                      )
                  )
                ],
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
                      controller: companyNameController,
                      decoration: InputDecoration(
                        hintText: "DENOMINATION OU RAISON SOCIALE",
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
              Column(
                children: [
                  Container(
                    width: 120,
                    height: 30,
                    padding: const EdgeInsets.all(2.0),
                    decoration: BoxDecoration(
                      color: Colors.pinkAccent,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: FittedBox(
                      child: Text(
                          "Extrait KBIS",
                          style: GoogleFonts.poppins(
                              color: Colors.white,
                              fontSize: 17,
                              fontWeight: FontWeight.bold
                          )
                      ),
                    ),
                  ),
                  SizedBox(height: 2),
                  Container(
                      child: Text(
                          "(facultatif)",
                          style: GoogleFonts.poppins(
                              color: Colors.orange,
                              fontSize: 17,
                              fontWeight: FontWeight.bold
                          )
                      )
                  )
                ],
              ),
              SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton(
                    onPressed: () async {

                      FilePickerResult? resultDocumentCompanyExistence = await FilePicker.platform.pickFiles(type: FileType.custom, allowedExtensions: ['png','jpg','pdf']);

                      if (resultDocumentCompanyExistence != null){
                        documentCompanyExistence = File(resultDocumentCompanyExistence.files.first.path!);
                        setState(() {
                          filenameDocumentCompanyExistence = basename(documentCompanyExistence!.path);
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
                            filenameDocumentCompanyExistence.isEmpty ? "Aucun fichier ajouté" : filenameDocumentCompanyExistence,
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
              Column(
                children: [
                  Container(
                    width: 160,
                    height: 30,
                    padding: const EdgeInsets.all(2.0),
                    decoration: BoxDecoration(
                      color: Colors.pinkAccent,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: FittedBox(
                      child: Text(
                          "Code APE ou NAF",
                          style: GoogleFonts.poppins(
                              color: Colors.white,
                              fontSize: 17,
                              fontWeight: FontWeight.bold
                          )
                      ),
                    ),
                  ),
                  SizedBox(height: 2),
                  Container(
                      child: Text(
                          "(facultatif)",
                          style: GoogleFonts.poppins(
                              color: Colors.orange,
                              fontSize: 17,
                              fontWeight: FontWeight.bold
                          )
                      )
                  )
                ],
              ),
              SizedBox(height: 20),
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
                              "Cette condition ne peut pas être décochée !",
                              contentMessage: "Ton code APE ou NAF doit obligatoirement correspondre au 8299. Si tel n'est pas le cas, contactes ton CFE pour procéder à la modification !");*/
                        },
                      )
                  ),
                  RichText(
                    text: TextSpan(
                      text: "Mon code est bien le ",
                      children: <TextSpan>[
                        TextSpan(
                          text:"8299",
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
              SizedBox(height: 30),
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
                        "*** Pour information ***",
                        style: GoogleFonts.poppins(
                          color: Colors.purple,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: 10),
                      Text(
                        "Tu recherches un numéro SIREN, une dénomination/raison sociale, un extrait KBIS, ou bien un code APE/NAF ?",
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
            ],
          ),
          accountId != "" ? SizedBox(height: 10) : SizedBox(height: 60),
          Center(
            child: StatefulBuilder(
                builder: (context, changeState) {
                  return Container(
                    width: 250,
                    height: 60,
                    child: ElevatedButton(
                      onPressed: () async {

                        changeState(() {
                          isLoading = true;
                        });

                        if (accountId != ""){
                          if (newUpdateFormValidated){
                            HttpsCallable callable = await FirebaseFunctions.instanceFor(app: FirebaseFunctions.instance.app, region: "europe-west1").httpsCallable('createCustomConnectAccountCompany');

                            final resp = await callable.call(<String, dynamic> {
                              "accountId":accountId,
                              "userId":_userManager.userId!,
                              "bankAccountToken":bankAccountToken,
                              "personToken":personsToken[0]["id"],
                              "newUpdatedAccount":json.encode(newUpdatedAccount)
                            });

                            String finalStatus = resp.data["status"];
                            if ("success" == finalStatus){
                              await _userManager.updateValue("allUsers", "is_helper_certified", 1);
                              setState(() {
                                selectedPage = "confirmation_page";
                              });
                            }else{
                              //AlertDialogManager.shortDialog(context,"Il semble que la saisie soit incorrecte. Vérifies bien le(s) champ(s)");
                            }

                          }else{
                            //AlertDialogManager.shortDialog(context,"Tu dois enregistrer les informations avant d'envoyer le formulaire");
                            changeState(() {
                              isLoading = false;
                            });
                          }
                        }
                        else{
                          final resultStatus = fieldsAreCorrect();
                          if ("SUCCESS" == resultStatus){

                            String uid = _userManager.userId!;

                            List listOfNeededParams = ["last_name","first_name"];
                            Map tmpValues = await _userManager.getMultipleValues("allUsers", listOfNeededParams);
                            String lastName = tmpValues[listOfNeededParams[0]];//await currentUser.getValueFromDataBase("allHelpers", "avatar_url");
                            String firstName = tmpValues[listOfNeededParams[1]];

                            //String lastName = await _userManager.getValueFromDataBase("allUsers", "last_name");
                            //String firstName = await _userManager.getValueFromDataBase("allUsers", "first_name");

                            String email =  (_userManager.phoneNumber != null) ? emailController.text.trim() : _userManager.details!.email!;
                            String iban =  ibanController.text.trim();
                            String code =  codeController.text.trim();
                            String city =  personCityController.text.trim();
                            String phone =  (_userManager.phoneNumber != null) ? _userManager.phoneNumber! : (dialCodeDigits + phoneController.text.trim());
                            String streetNumber =  streetNumberController.text.trim();
                            String streetName =  streetNameController.text.trim();
                            String postalCode =  postalCodeController.text.trim();
                            String companyName =  companyNameController.text.trim();

                            Reference ref = FirebaseStorage.instance.ref();

                            var tmpFileNameIdFront = "id_front_" + uid + "."+ filenameRecto.split(".").last;
                            var tmpFileNameIdBack = "id_back_" + uid + "." + filenameVerso.split(".").last;
                            var tmpFileNameHomeProof = "additional_document_" + uid + "." + filenameDocument.split(".").last;
                            var tmpFileNameCompanyProof = "company_registration_verification_" + uid + "." + filenameDocumentCompanyExistence.split(".").last;

                            await ref.child("saved_users_files/$uid/$tmpFileNameIdFront").putFile(imageRecto!);
                            await ref.child("saved_users_files/$uid/$tmpFileNameIdBack").putFile(imageVerso!);
                            await ref.child("saved_users_files/$uid/$tmpFileNameHomeProof").putFile(document!);

                            if (documentCompanyExistence != null){
                              await ref.child("saved_users_files/$uid/$tmpFileNameCompanyProof").putFile(documentCompanyExistence!);
                            }

                            HttpsCallable callable = await FirebaseFunctions.instanceFor(app: FirebaseFunctions.instance.app, region: "europe-west1").httpsCallable('createCustomConnectAccountCompany');
                            final resp = await callable.call(<String, dynamic>{
                              "first_name": firstName,
                              "last_name": lastName,
                              "countryCode": countryCode,
                              "dob": dayBirth+"-"+monthBirth+"-"+yearBirth,
                              "email":email,
                              "phone":phone,
                              "city":city,
                              "line1": streetNumber + " " + streetName,
                              "postal_code": postalCode,
                              "id_front":tmpFileNameIdFront,
                              "id_back":tmpFileNameIdBack,
                              "additional_document":tmpFileNameHomeProof,
                              "company_name":companyName,
                              "company_registration_verification": (filenameDocumentCompanyExistence.isNotEmpty)? tmpFileNameCompanyProof : "",
                              "tax_id":code,
                              "iban":iban,
                              "currency": "eur",
                              "userId":uid,
                              "accountId":accountId
                            });

                            String finalStatus = resp.data["status"];

                            if ("success" == finalStatus){
                              await _userManager.updateValue("allUsers", "is_helper_certified", 1);
                              setState(() {
                                selectedPage = "confirmation_page";
                              });
                            }else{
                              changeState(() {
                                isLoading = false;
                              });

                              if (error_codes[resp.data["code"]] != null){
                                //AlertDialogManager.shortDialog(context, "Champs obligatoire",contentMessage: error_codes[resp.data["code"]]!);
                              }else if(error_messages[resp.data["error"]] != null){
                                //AlertDialogManager.shortDialog(context, "Champs obligatoire",contentMessage: error_messages[resp.data["error"]]!);
                              } else{
                                //AlertDialogManager.shortDialog(context, "Champs obligatoire",contentMessage: "Il semblerait qu'il y'ait une erreur dans le formulaire... Vérifies-bien tous les champs.");
                              }
                            }

                          }else{
                            changeState(() {
                              isLoading = false;
                            });
                            //AlertDialogManager.shortDialog(context, "Champs obligatoire",contentMessage: resultStatus);
                          }
                        }

                      },
                      style: ElevatedButton.styleFrom(
                        shape: StadiumBorder(),
                        primary: Colors.red,
                      ),
                      child: isLoading ?
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Flexible(
                            child: Text(
                              'TRAITEMENT EN COURS',
                              style: GoogleFonts.poppins(
                                color: Colors.white,
                                fontSize: 15,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          SizedBox(width: 5),
                          SizedBox(
                              width: 20.0,
                              height: 20.0,
                              child: CircularProgressIndicator(color: Colors.white,)
                          ),
                        ],
                      )
                          :
                      Text(
                        'VALIDER',
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  );
                }
            ),
          ),
          SizedBox(height: 40),
        ]
    );
  }


  Widget IntroductionPage() {
    return Column(
      children: [
        SizedBox(height: 10),
        Row(
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 8.0),
              child: Text(
                widget.disableAppBar! ? "Certifier son compte: à quoi ça sert ?" : "A quoi sert la certification ?",
                style: GoogleFonts.poppins(
                  color: Colors.orange[600],
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: 10),
        Row(
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 8.0),
              child: Text(
                "La certification permet:",
                style: GoogleFonts.poppins(
                  color: Colors.black,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: 10),
        Padding(
          padding: const EdgeInsets.only(left: 16.0),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Wrap(
              children: [
                Text(
                  "1)  d'assurer ton identité et éviter toute fraude",
                  style: GoogleFonts.poppins(
                    color: Colors.black,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
        SizedBox(height: 10),
        Padding(
          padding: const EdgeInsets.only(left: 16.0),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Wrap(
              children: [
                Text(
                  "2) de récupérer les fonds que tu as gagné directement dans ton compte bancaire. Une fois certifié, tes revenus te seront versés de manière automatique chaque mois.",
                  style: GoogleFonts.poppins(
                    color: Colors.black,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
        SizedBox(height: 10),
        Padding(
          padding: const EdgeInsets.only(left: 16.0),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Wrap(
              children: [
                Text(
                  "3) d'acquérir le précieux badge de certification! Ce badge sera visible par tous les utilisateurs et témoignera de ton sérieux auprès de la communauté. Les utilisateurs qui verront ce badge auront tendance à lancer beaucoup plus de LIVEs avec toi. L'obtention du badge te permet ainsi donc d'augmenter considérablement tes revenus !",
                  style: GoogleFonts.poppins(
                    color: Colors.black,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
        SizedBox(height: 40),
        Container(
          width: 250,
          height: 60,
          child: ElevatedButton(
            onPressed: (){
              setState(() {
                selectedPage = "form_page";
              });
            },
            style: ElevatedButton.styleFrom(
              shape: StadiumBorder(),
              primary: Colors.red,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'CONTINUER',
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Icon(Icons.arrow_right_alt, size: 25),
              ],
            ),
          ),
        )
      ],
    );
  }


}