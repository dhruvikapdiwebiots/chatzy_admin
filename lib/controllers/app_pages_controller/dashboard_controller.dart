import 'dart:async';
import 'dart:developer';

import '../../config.dart';

enum MessageType { text, image, video, doc, location, contact, audio, messageType,gif, link, imageArray,note, chatLoading }
enum StatusType { text, image, video}

class DashboardController extends GetxController{
  int totalUser = 0;
  int totalCalls = 0;
  int videoCall = 0;
  int audioCall = 0;
  int currentPage = 1;
  int lastVisible = 0;
  List<bool>? expanded;
  String? searchKey = "name";

  // ignore: unused_field
  final String selectableKey = "id";
  String lastIndexId ="";
  final List<Map<String, dynamic>> sourceOriginal = [];
  List<Map<String, dynamic>> sourceFiltered = [];
  List<Map<String, dynamic>> source = [];
  String? sortColumn;

  bool sortAscending = true;
  bool isLoading = true;
  final bool showSelect = true;

  final List<int> perPages = [10, 20, 50, 100];
  int total = 100;
  int? currentPerPage = 7;
TextEditingController textSearch = TextEditingController();

  @override
  void onReady() async{
    totalUser = await FirebaseFirestore.instance.collection(collectionName.users).get().then((value) => value.size);
total = totalUser;
update();
    FirebaseFirestore.instance.collection(collectionName.users).get().then((value) {
      if(value.docs.isNotEmpty) {
        value.docs
            .asMap()
            .entries
            .forEach((e) {
          FirebaseFirestore.instance
              .collection(collectionName.calls)
              .doc(e.value.id)
              .collection(collectionName.collectionCallHistory)
              .get().then((value) {
            totalCalls = totalCalls + value.docs.length;
            value.docs.asMap().forEach((key, value) {
                if(value.data()["isVideoCall"] != null &&  value.data()["isVideoCall"] == true) {
                  videoCall++;
                } else {
                  audioCall++;
                }
            });
            update();
          });
        });
      }
    });

    const oneSec = Duration(seconds: 1);
    Timer.periodic(oneSec, (Timer t) async {
        progressValue += 0.1;
        // we "finish" downloading here
        if (progressValue.toStringAsFixed(1) == '1.0') {
          loading = false;
          t.cancel();
          return;
        }
    });

  update();

    // TODO: implement onReady
    super.onReady();
  }
  bool loading = true;
  double progressValue = 0;

  final List<Map<String, dynamic>> listItem = [
    {
      'title': "totalUser",
      'icon': svgAssets.groups
    },
    {
      'title': 'totalCalls',
      'icon': svgAssets.call
    },
    {
      'title': 'videoCalls',
      'icon': svgAssets.videoCall
    },
    {
      'title': 'audioCalls',
      'icon': svgAssets.audioCall
    },
  ];

  Stream getChatsFromRefs() {

    Stream<QuerySnapshot<Map<String, dynamic>>> event = FirebaseFirestore
        .instance
        .collection(collectionName.users)
        .limit(currentPerPage!)
        .snapshots();

    return event;
  }

  userActiveDeActive(id,val)async{
    bool isLoginTest = appCtrl.storage.read(session.isLoginTest);
    if (isLoginTest) {
      accessDenied(fonts.modification.tr);
    }else{
      await FirebaseFirestore.instance.collection(collectionName.users).doc(id).update(
          {"isActive":val});
    }
  }

  deleteData(id) async {
    bool isLoginTest =
    appCtrl.storage.read(session.isLoginTest);
    if (isLoginTest) {
      accessDenied(fonts.modification.tr);
    } else {
      await FirebaseFirestore.instance
          .collection(collectionName.calls)
          .doc(id)
          .delete();
      await FirebaseFirestore.instance
          .collection(collectionName.users)
          .doc(id)
          .collection(collectionName.status)
          .get()
          .then((value) {
        for (QueryDocumentSnapshot<Map<String, dynamic>> ds
        in value.docs) {
          Status status = Status.fromJson(ds.data());
          List<PhotoUrl> photoUrl = status.photoUrl ?? [];
          for (var list in photoUrl) {
            if (list.statusType == StatusType.image.name ||
                list.statusType == StatusType.video.name) {
              FirebaseStorage.instance
                  .refFromURL(list.image!)
                  .delete();
            }
          }
        }
      });
      await FirebaseFirestore.instance
          .collection(collectionName.users)
          .doc(id)
          .collection(collectionName.chats)
          .get()
          .then((value) {
        for (DocumentSnapshot ds in value.docs) {
          ds.reference.delete();
        }
      });
      await FirebaseFirestore.instance
          .collection(collectionName.users)
          .doc(id)
          .collection(collectionName.messages)
          .get()
          .then((value) {
        for (QueryDocumentSnapshot<Map<String, dynamic>> ds
        in value.docs) {
          if (ds.data()["type"] == MessageType.image.name ||
              ds.data()["type"] == MessageType.audio.name ||
              ds.data()["type"] == MessageType.video.name ||
              ds.data()["type"] == MessageType.doc.name ||
              ds.data()["type"] == MessageType.gif.name ||
              ds.data()["type"] == MessageType.imageArray.name) {
            String url = decryptMessage(ds.data()["content"]);
            FirebaseStorage.instance
                .refFromURL(url.contains("-BREAK-")
                ? url.split("-BREAK-")[0]
                : url)
                .delete();
          }
          ds.reference.delete();
        }
      });
      await FirebaseFirestore.instance
          .collection(collectionName.users)
          .doc(id)
          .collection(collectionName.groupMessage)
          .get()
          .then((value) {
        for (QueryDocumentSnapshot<Map<String, dynamic>> ds
        in value.docs) {
          if (ds.data()["type"] == MessageType.image.name ||
              ds.data()["type"] == MessageType.audio.name ||
              ds.data()["type"] == MessageType.video.name ||
              ds.data()["type"] == MessageType.doc.name ||
              ds.data()["type"] == MessageType.gif.name ||
              ds.data()["type"] == MessageType.imageArray.name) {
            String url = decryptMessage(ds.data()["content"]);
            FirebaseStorage.instance
                .refFromURL(url.contains("-BREAK-")
                ? url.split("-BREAK-")[0]
                : url)
                .delete();
          }
          ds.reference.delete();
        }
      });

      await FirebaseFirestore.instance
          .collection(collectionName.users)
          .doc(id)
          .collection(collectionName.broadcastMessage)
          .get()
          .then((value) {
        for (QueryDocumentSnapshot<Map<String, dynamic>> ds
        in value.docs) {
          if (ds.data()["type"] == MessageType.image.name ||
              ds.data()["type"] == MessageType.audio.name ||
              ds.data()["type"] == MessageType.video.name ||
              ds.data()["type"] == MessageType.doc.name ||
              ds.data()["type"] == MessageType.gif.name ||
              ds.data()["type"] == MessageType.imageArray.name) {
            String url = decryptMessage(ds.data()["content"]);
            FirebaseStorage.instance
                .refFromURL(url.contains("-BREAK-")
                ? url.split("-BREAK-")[0]
                : url)
                .delete();
          }
          ds.reference.delete();
        }
      });

      await FirebaseFirestore.instance
          .collection(collectionName.users)
          .doc(id)
          .delete();
    }
  }

 //reset data
  resetData({start = 0}) async {
    isLoading = true;
    update();
    var expandedLen =
    total - start < currentPerPage! ? total - start : currentPerPage;
    Future.delayed(const Duration(seconds: 0)).then((value) {
      expanded = List.generate(expandedLen as int, (index) => false);
      source.clear();
      source = sourceFiltered.getRange(start, start + expandedLen).toList();
      isLoading = false;
      update();
    });
  }

  //filter data
  filterData(value) {
    isLoading = true;
    update();
    getChatsFromRefs();
    try {
      if (value == "" || value == null) {
        sourceFiltered = sourceOriginal;
      } else {
        sourceFiltered = sourceOriginal
            .where((data) =>
        data[searchKey!]
            .toString()
            .toLowerCase()
            .contains(value.toString().toLowerCase()) ||
            data["name"]
                .toString()
                .toLowerCase()
                .contains(value.toString().toLowerCase()))
            .toList();
      }

      total = sourceFiltered.length;
      var rangeTop = total < currentPerPage! ? total : currentPerPage!;
      expanded = List.generate(rangeTop, (index) => false);
      source = sourceFiltered.getRange(0, rangeTop).toList();
    } catch (e) {

    }
    isLoading = false;
    update();
  }


}