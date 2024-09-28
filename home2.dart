import 'dart:convert';
import 'dart:math';
import 'package:animated_toggle_switch/animated_toggle_switch.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:intl/intl.dart';
import 'package:lottie/lottie.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:store/features/authentication/model/appointment.model.dart';
import 'package:store/features/authentication/view/splash_screen/splash_screen.dart';
import 'package:store/utils/api_routes.dart';
import 'package:zego_uikit_prebuilt_call/zego_uikit_prebuilt_call.dart';

class HomeScreen2 extends StatefulWidget {
  const HomeScreen2({super.key});

  @override
  State<HomeScreen2> createState() => _HomeScreen2State();
}

class _HomeScreen2State extends State<HomeScreen2> {
  String name = "...";
  bool isOnline = false;

  bool isLoading = false;

  List<Appointment> appointments = [];

  bool canCallNow(String formattedDate) {
    List<String> parts = formattedDate.split(' at ');
    DateTime datePart = DateFormat.yMMMMEEEEd().parse(parts[0]);
    DateTime timePart = DateFormat.jm().parse(parts[1]);

    DateTime combinedDateTime = DateTime(datePart.year, datePart.month,
        datePart.day, timePart.hour, timePart.minute);

    DateTime now = DateTime.now();

    return now.isAfter(combinedDateTime);
  }

  loadAllRequests() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    var userId = prefs.getString('userId');
    var name = prefs.getString('name');
    print("Psychologist Name is $name");
    print(userId);
    await http.post(
      Uri.parse(
        APIRoutes.viewRequests,
      ),
      body: {
        "id": userId,
        "userType": "psychologist",
      },
    ).then((val) {
      print(val.body);
      var jsonData = json.decode(val.body);
      setState(() {
        appointments = List<Appointment>.from(
          jsonData['appointments'].map(
            (x) => Appointment.fromJson(x),
          ),
        );
      });
    });
  }

  decideColor(String status) {
    if (status == "pending") {
      return Colors.orange;
    } else if (status == "approved") {
      return Colors.green;
    } else if (status == "denied") {
      return Colors.red;
    } else if (status == "completed") {
      return Colors.blueGrey;
    } else {
      return Colors.grey;
    }
  }

  @override
  void initState() {
    super.initState();
    getPsychologist();
    loadAllRequests();
  }

  getPsychologist() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String userId = prefs.getString("userId")!;
    http.post(
      Uri.parse(APIRoutes.getCyco),
      body: {
        "id": userId,
      },
    ).then((response) {
      if (response.statusCode == 200) {
        var jsonRes = jsonDecode(response.body);
        setState(() {
          name = jsonRes['user']['name'];
          isOnline =
              jsonRes['user']['isOnline'].toString() == "false" ? false : true;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    ThemeData theme = Theme.of(context);
    const green = Color(0xFF45CC0D);
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: 25.0,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                height: 20,
              ),
              Row(
                children: [
                  const Text(
                    "Psychologist Dashboard",
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Spacer(),
                  IconButton(
                    onPressed: () async {
                      SharedPreferences prefs =
                          await SharedPreferences.getInstance();
                      prefs.clear();
                      ZegoUIKitPrebuiltCallInvitationService().uninit();
                      Navigator.pushAndRemoveUntil(
                        context,
                        MaterialPageRoute(
                          builder: (_) => SplashScreen(),
                        ),
                        (route) => false,
                      );
                    },
                    icon: Icon(
                      Icons.logout,
                      color: Colors.red,
                    ),
                  ),
                ],
              ),
              SizedBox(
                height: 20,
              ),
              Card(
                elevation: 3,
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: ListTile(
                    leading: Lottie.asset(
                      "assets/gif/dashboard.json",
                      // height: 60,
                    ),
                    title: Text(
                      "Welcome Back, $name.",
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    subtitle: Text(
                      "Manage your status to receive consultation requests.",
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.black54,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
              SizedBox(
                height: 20,
              ),
              Center(
                child: DefaultTextStyle.merge(
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18.0,
                    fontWeight: FontWeight.bold,
                  ),
                  child: IconTheme.merge(
                    data: const IconThemeData(color: Colors.white),
                    child: AnimatedToggleSwitch<bool>.dual(
                      loading: isLoading,
                      current: isOnline,
                      first: false,
                      second: true,
                      spacing: 45.0,
                      animationDuration: const Duration(milliseconds: 600),
                      style: const ToggleStyle(
                        borderColor: Colors.transparent,
                        indicatorColor: Colors.white,
                        backgroundColor: Colors.black,
                      ),
                      customStyleBuilder: (context, local, global) {
                        if (global.position <= 0.0) {
                          return ToggleStyle(backgroundColor: Colors.red[800]);
                        }
                        return ToggleStyle(
                            backgroundGradient: LinearGradient(
                          colors: [green, Colors.red[800]!],
                          stops: [
                            global.position -
                                (1 - 2 * max(0, global.position - 0.5)) * 0.7,
                            global.position +
                                max(0, 2 * (global.position - 0.5)) * 0.7,
                          ],
                        ));
                      },
                      borderWidth: 6.0,
                      height: 60.0,
                      loadingIconBuilder: (context, global) =>
                          CupertinoActivityIndicator(
                              color: Color.lerp(
                                  Colors.red[800], green, global.position)),
                      onChanged: (b) {
                        setState(() {
                          isLoading = true;
                        });
                        SharedPreferences.getInstance().then((prefs) {
                          http.put(
                            Uri.parse(
                              b ? APIRoutes.markOnline : APIRoutes.markOffline,
                            ),
                            body: {
                              "id": prefs.getString("userId")!,
                            },
                          ).then((response) {
                            if (response.statusCode == 200) {
                              if (b) {
                                Fluttertoast.showToast(
                                    msg:
                                        "You will be able to receive video calls now.");
                              } else {
                                Fluttertoast.showToast(
                                    msg:
                                        "You will not receive any video calls now.");
                              }
                              setState(() {
                                isOnline = b;
                                isLoading = false;
                              });
                            }
                          });
                        });
                      },
                      iconBuilder: (value) => value
                          ? const Icon(
                              Icons.online_prediction,
                              color: green,
                              size: 32.0,
                            )
                          : Icon(
                              Icons.power_settings_new_rounded,
                              color: Colors.red[800],
                              size: 32.0,
                            ),
                      textBuilder: (value) => value
                          ? const Center(
                              child: Text(
                                'Active',
                              ),
                            )
                          : const Center(
                              child: Text(
                                'Inactive',
                              ),
                            ),
                    ),
                  ),
                ),
              ),
              SizedBox(
                height: 20,
              ),
              Text(
                "Your Requests",
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(
                height: 5,
              ),
              const Text(
                "View your appointment requests.",
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(
                height: 20,
              ),
              Expanded(
                child: ListView.builder(
                  itemCount: appointments.length,
                  itemBuilder: (context, index) {
                    return Card(
                      elevation: 3,
                      child: ListTile(
                        title: Row(
                          children: [
                            Text(
                              appointments[index].userEmail,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Card(
                              color: decideColor(
                                appointments[index].status,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(100),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10.0,
                                  vertical: 5,
                                ),
                                child: Text(
                                  appointments[index].status.toUpperCase(),
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        subtitle: Column(
                          children: [
                            Text(
                              appointments[index].appointmentTime.trim(),
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            if (appointments[index].status == "approved")
                              SizedBox(
                                height: 10,
                              ),
                            if (appointments[index].status == "pending")
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceEvenly,
                                children: [
                                  IconButton(
                                    onPressed: () async {
                                      await http.put(
                                        Uri.parse(APIRoutes.updateApptStatus),
                                        body: {
                                          "appointmentId":
                                              appointments[index].id,
                                          "status": "denied",
                                        },
                                      ).then((response) {
                                        if (response.statusCode == 200) {
                                          Fluttertoast.showToast(
                                            msg:
                                                "Appointment updated successfully.",
                                          );
                                          loadAllRequests();
                                        }
                                      });
                                    },
                                    icon: Icon(
                                      Icons.cancel,
                                      size: 50,
                                      color: Colors.red,
                                    ),
                                  ),
                                  IconButton(
                                    onPressed: () {
                                      http.put(
                                        Uri.parse(APIRoutes.updateApptStatus),
                                        body: {
                                          "appointmentId":
                                              appointments[index].id,
                                          "status": "approved",
                                        },
                                      ).then((response) {
                                        if (response.statusCode == 200) {
                                          Fluttertoast.showToast(
                                            msg:
                                                "Appointment updated successfully.",
                                          );
                                          loadAllRequests();
                                        }
                                      });
                                    },
                                    icon: Icon(
                                      Icons.check_circle,
                                      size: 50,
                                      color: Colors.green,
                                    ),
                                  ),
                                ],
                              ),
                            if (appointments[index].status == "approved")
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceEvenly,
                                children: [
                                  if (canCallNow(
                                      appointments[index].appointmentTime))
                                    ZegoSendCallInvitationButton(
                                      onPressed: (code, message, p2) {
                                        setState(() {
                                          appointments.removeAt(index);
                                        });
                                      },
                                      buttonSize: Size(
                                        50,
                                        50,
                                      ),
                                      iconSize: Size(50, 50),
                                      isVideoCall: true,
                                      callID: appointments[index].id +
                                          "_" +
                                          appointments[index].userID,
                                      resourceID: "zegouikit_call",
                                      invitees: [
                                        ZegoUIKitUser(
                                          id: appointments[index].userEmail,
                                          name: appointments[index].userEmail,
                                        ),
                                      ],
                                    ),
                                  IconButton(
                                    onPressed: () async {
                                      await http.put(
                                        Uri.parse(APIRoutes.updateApptStatus),
                                        body: {
                                          "appointmentId":
                                              appointments[index].id,
                                          "status": "denied",
                                        },
                                      ).then((response) {
                                        if (response.statusCode == 200) {
                                          Fluttertoast.showToast(
                                            msg:
                                                "Appointment updated successfully.",
                                          );
                                          loadAllRequests();
                                        }
                                      });
                                    },
                                    icon: Icon(
                                      Icons.cancel,
                                      size: 50,
                                      color: Colors.red,
                                    ),
                                  ),
                                ],
                              )
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
