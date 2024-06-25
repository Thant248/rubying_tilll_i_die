import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:dart_frog_web_socket/dart_frog_web_socket.dart';
import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_frontend/const/permissions.dart';
import 'package:flutter_frontend/services/directMessage/direct_message_api.dart';
import 'package:intl/intl.dart';
import 'package:flutter/material.dart';
import 'package:flutter_frontend/constants.dart';
import 'package:flutter_frontend/progression.dart';
import 'package:flutter_frontend/model/SessionStore.dart';
import 'package:flutter_frontend/componnets/customlogout.dart';
import 'package:flutter_frontend/model/direct_message_thread.dart';
import 'package:flutter_frontend/services/userservice/api_controller_service.dart';
import 'package:flutter_frontend/services/directMessage/directMessageThread/direct_message_thread.dart';
import 'package:path_provider/path_provider.dart';

import '../../services/file_upload/download_file_web.dart';
// ignore_for_file: public_member_api_docs, sort_constructors_first

class DirectMessageThreadWidget extends StatefulWidget {
  final int directMsgId;
  final String receiverName;
  final int receiverId;
  final userStatus;
  const DirectMessageThreadWidget(
      {Key? key,
      required this.directMsgId,
      required this.receiverName,
      required this.receiverId,
      this.userStatus})
      : super(key: key);

  @override
  State<DirectMessageThreadWidget> createState() => _DirectMessageThreadState();
}

class _DirectMessageThreadState extends State<DirectMessageThreadWidget>
    with RouteAware {
  final DirectMsgThreadService _apiService = DirectMsgThreadService(Dio(
      BaseOptions(headers: {
    'Content-Type': 'application/json',
    'Accept': 'application/json'
  })));

  final DirectMessageService _directMessageService = DirectMessageService();
  final TextEditingController replyTextController = TextEditingController();

  int currentUserId = SessionStore.sessionData!.currentUser!.id!.toInt();
  late ScrollController _scrollController;

  int? selectedIndex;

  bool isLoading = false;
  List<TDirectThreads>? tDirectThreads = [];
  List<int>? tDirectStarThreadMsgIds = [];
  String senderName = "";
  String directMessage = "";
  String times = DateTime.now().toString();
  
  WebSocketChannel? _channel;
  final String ipAddress = "192.168.2.79";

  String replaceMinioWithIP(String url, String ipAddress) {
    return url.replaceAll("http://minio:9000", "http://$ipAddress:9000");
  }

  bool hasFileToSEnd = false;
  List<PlatformFile> files = [];
  late String localpath;
  late bool permissionReady;
  TargetPlatform? platform;
  final PermissionClass permissions = PermissionClass();
  String? fileText;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    loadMessages();
    connectWebSocket();
    if (kIsWeb) {
      return;
    } else if (Platform.isAndroid) {
      platform = TargetPlatform.android;
    } else {
      platform = TargetPlatform.iOS;
    }
  }

  @override
  void dispose() {
    super.dispose();

    _scrollController.dispose();
    replyTextController.dispose();
  }

  Future<void> _prepareSaveDir() async {
    localpath = (await _findLocalPath())!;
    print(localpath);
    final saveDir = Directory(localpath);
    bool hasExisted = await saveDir.exists();
    if (!hasExisted) {
      await saveDir.create();
    }
  }

  Future<String?> _findLocalPath() async {
    if (platform == TargetPlatform.android) {
      return "/sdcard/download/";
    } else {
      var directory = await getApplicationDocumentsDirectory();
      return '${directory.path}${Platform.pathSeparator}Download';
    }
  }

  void pickFiles() async {
    FilePickerResult? result = await FilePicker.platform
        .pickFiles(allowMultiple: true, withData: true);
    if (result == null) return;
    setState(() {
      files.addAll(result.files);
      hasFileToSEnd = true;
    });
  }

  void connectWebSocket() {
    var url = 'ws://localhost:3000/cable?user_id=${widget.receiverId}';
    _channel = WebSocketChannel.connect(Uri.parse(url));

    final subscriptionMessage = jsonEncode({
      'command': 'subscribe',
      'identifier': jsonEncode({'channel': 'ThreadchannelChannel'}),
    });

    _channel!.sink.add(subscriptionMessage);

    _channel!.stream.listen(
      (message) {
        try {
          var parsedMessage = jsonDecode(message) as Map<String, dynamic>;

          if (parsedMessage.containsKey('type') &&
              parsedMessage['type'] == 'ping') {
            return;
          }

          if (parsedMessage.containsKey('message')) {
            var messageContent = parsedMessage['message'];

            // Handling chat message
            if (messageContent != null &&
                messageContent.containsKey('message')) {
              var msg = messageContent['message'];

              if (msg != null && msg.containsKey('directthreadmsg')) {
                var directThreadMsg = msg['directthreadmsg'];
                int id = msg['id'];
                var date = msg['created_at'];
                String send = messageContent['sender_name'];
                List<dynamic> fileUrls = [];

                if (messageContent.containsKey('files')) {
                  var files = messageContent['files'];
                  if (files != null) {
                    fileUrls = files.map((file) => file['file']).toList();
                  }
                }
                setState(() {
                  tDirectThreads!.add(TDirectThreads(
                    id: id,
                    directthreadmsg: directThreadMsg,
                    fileUrls: fileUrls,
                    createdAt: date,
                    name: send,
                  ));
                });
              } else {}
            } else if (messageContent.containsKey('messaged_star')) {
              var messageStarData = messageContent['messaged_star'];

              if (messageStarData != null) {
                var directThreadID = messageStarData['directthreadid'];

                setState(() {
                  tDirectStarThreadMsgIds!.add(directThreadID);
                });
              } else {}
            } else if (messageContent.containsKey('unstared_message')) {
              var unstaredMsg = messageContent['unstared_message'];

              var directmsgid = unstaredMsg['directthreadid'];

              setState(() {
                tDirectStarThreadMsgIds!.remove(directmsgid);
              });
            } else {
              var deletemsg = messageContent['delete_msg_thread'];

              var threadId = deletemsg['id'];
              print(threadId);

              setState(() {
                tDirectThreads!.removeWhere((thread) {
                  return thread.id == threadId;
                });
              });
            }
          } else {}
        } catch (e) {}
      },
      onDone: () {},
      onError: (error) {},
    );
  }

  Future<void> loadMessages() async {
    var token = await getToken();
    try {
      DirectMessageThread thread =
          await _apiService.getAllThread(widget.directMsgId, token!);

      setState(() {
        tDirectThreads = thread.tDirectThreads;
        tDirectStarThreadMsgIds = thread.tDirectStarThreadMsgids;
        senderName = thread.senderName!;
        directMessage = thread.tDirectMessage!.directmsg!;
        times = thread.tDirectMessage!.createdAt!;
        isLoading = true;
      });
    } catch (e) {
      print('Failed to fetch messages: $e');
    }
  }

  Future<void> sendReplyMessage() async {
    if (replyTextController.text.isNotEmpty || files.isNotEmpty) {
      await _directMessageService.sendDirectMessageThread(widget.directMsgId,
          widget.receiverId, replyTextController.text, files);
      replyTextController.clear();
      files.clear();
    }
  }

  Future<void> starMsgReply(int threadId) async {
    var token = await getToken();
    await _apiService.starThread(
        widget.receiverId, currentUserId, threadId, widget.directMsgId, token!);
  }

  Future<void> unStarReply(int threadId) async {
    var token = await getToken();
    await _apiService.unStarThread(
        widget.directMsgId, widget.receiverId, threadId, currentUserId, token!);
  }

  Future<void> deleteReply(int threadId) async {
    var token = await getToken();
    await _apiService.deleteThread(
        widget.directMsgId, widget.receiverId, threadId, token!);
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  Future<String?> getToken() async {
    return await AuthController().getToken();
  }

  @override
  Widget build(BuildContext context) {
    if (SessionStore.sessionData!.currentUser!.memberStatus == false) {
      return CustomLogOut();
    } else {
      DateTime dates = DateTime.parse(times!).toLocal();
      String createdAt = DateFormat('MMM d, yyyy hh:mm a').format(dates);
      int maxLines = (directMessage.length / 25).ceil();
      int replyLength = tDirectThreads?.length ?? 0;

      return Scaffold(
          backgroundColor: kPriamrybackground,
          resizeToAvoidBottomInset: true,
          appBar: AppBar(
            backgroundColor: navColor,
            leading: IconButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                icon: const Icon(
                  Icons.arrow_back,
                  color: Colors.white,
                )),
            title: const Text(
              'Thread',
              style: TextStyle(color: Colors.white),
            ),
          ),
          body: isLoading == false
              ? const ProgressionBar(
                  imageName: 'loading.json',
                  height: 200,
                  size: 200,
                  color: Colors.white)
              : Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(children: [
                    SizedBox(
                      height: 100,
                      width: 500,
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(right: 10),
                            child: Stack(
                              children: [
                                Container(
                                  decoration: BoxDecoration(
                                      color: Colors.amber,
                                      borderRadius: BorderRadius.circular(20)),
                                  height: 50,
                                  width: 50,
                                  child: Center(
                                    child: Text(
                                      senderName.characters.first.toUpperCase(),
                                      style: const TextStyle(
                                          color: Colors.black,
                                          fontSize: 25,
                                          fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                ),
                                Positioned(
                                    right: 0,
                                    bottom: 0,
                                    child: widget.userStatus == true
                                        ? Container(
                                            height: 14,
                                            width: 14,
                                            decoration: BoxDecoration(
                                                borderRadius:
                                                    BorderRadius.circular(7),
                                                border: Border.all(
                                                    color: Colors.white,
                                                    width: 1),
                                                color: Colors.green),
                                          )
                                        : Container())
                              ],
                            ),
                          ),
                          SingleChildScrollView(
                            child: Container(
                              width: MediaQuery.of(context).size.width * 0.7,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Row(children: [
                                        Text(
                                          senderName,
                                          style: const TextStyle(fontSize: 16),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        const SizedBox(
                                          width: 10,
                                        ),
                                        Text(
                                          createdAt,
                                          style: const TextStyle(
                                              fontSize: 10, color: Colors.grey),
                                        )
                                      ]),
                                    ],
                                  ),
                                  const SizedBox(
                                    width: 10,
                                  ),
                                  Text(
                                    directMessage,
                                    maxLines: maxLines,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Row(
                      children: [
                        Column(
                          children: [
                            Text(
                              '$replyLength reply',
                              style: const TextStyle(fontSize: 16),
                            ),
                          ],
                        ),
                        const SizedBox(width: 10),
                        const Expanded(
                          child: Divider(),
                        ),
                      ],
                    ),
                    Expanded(
                      child: ListView.builder(
                        controller: _scrollController,
                        itemCount: replyLength,
                        itemBuilder: (context, index) {
                          String replyMessages =
                              tDirectThreads![index].directthreadmsg.toString();
                          String name = tDirectThreads![index].name.toString();

                          List<dynamic>? files = [];
                          files = tDirectThreads![index].fileUrls;

                          int replyMessagesIds =
                              tDirectThreads![index].id!.toInt();
                          List<int> replyStarMsgId =
                              tDirectStarThreadMsgIds!.toList();
                          bool isStar =
                              replyStarMsgId.contains(replyMessagesIds);
                          String time =
                              tDirectThreads![index].createdAt.toString();

                          DateTime date = DateTime.parse(time).toLocal();
                          String createdAt =
                              DateFormat('MMM d, yyyy hh:mm a').format(date);

                          return Container(
                            margin: const EdgeInsets.symmetric(vertical: 10),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Padding(
                                  padding: const EdgeInsets.only(right: 10),
                                  child: Stack(
                                    children: [
                                      Container(
                                        decoration: BoxDecoration(
                                            color: Colors.amber,
                                            borderRadius:
                                                BorderRadius.circular(20)),
                                        height: 50,
                                        width: 50,
                                        child: Center(
                                          child: Text(
                                            name.characters.first.toUpperCase(),
                                            style: const TextStyle(
                                                color: Colors.black,
                                                fontSize: 25,
                                                fontWeight: FontWeight.bold),
                                          ),
                                        ),
                                      ),
                                      Positioned(
                                          right: 0,
                                          bottom: 0,
                                          child: widget.userStatus == true
                                              ? Container(
                                                  height: 14,
                                                  width: 14,
                                                  decoration: BoxDecoration(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              7),
                                                      border: Border.all(
                                                          color: Colors.white,
                                                          width: 1),
                                                      color: Colors.green),
                                                )
                                              : Container())
                                    ],
                                  ),
                                ),
                                Expanded(
                                  child: Container(
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                        color: Colors.grey.shade200,
                                        borderRadius: const BorderRadius.only(
                                            bottomLeft: Radius.circular(13),
                                            bottomRight: Radius.circular(13),
                                            topRight: Radius.circular(13))),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Flexible(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              if (replyMessages.isNotEmpty)
                                                Text(
                                                  replyMessages,
                                                  style: const TextStyle(
                                                      fontSize: 15,
                                                      fontWeight:
                                                          FontWeight.bold),
                                                  maxLines: 100000,
                                                ),
                                              if (files!.length == 1)
                                                _buildSingleFile(files[0]),
                                              if (files.length > 2)
                                                _buildMultipleFiles(files),
                                              const SizedBox(height: 8),
                                              const SizedBox(height: 8),
                                              Text(
                                                createdAt,
                                                style: const TextStyle(
                                                  fontSize: 10,
                                                  color: Color.fromARGB(
                                                      255, 15, 15, 15),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        Row(
                                          // crossAxisAlignment: CrossAxisAlignment.center,
                                          children: [
                                            IconButton(
                                              onPressed: () async {
                                               
                                                if (isStar) {
                                                  await unStarReply(
                                                      replyMessagesIds);
                                                } else {
                                                  await starMsgReply(
                                                      replyMessagesIds);
                                                }
                                              },
                                              icon: const Icon(
                                                Icons.star,
                                                size: 20,
                                              ),
                                              color: isStar
                                                  ? Colors.yellow
                                                  : Colors.grey,
                                            ),
                                            IconButton(
                                              onPressed: () async {
                                                await deleteReply(
                                                    replyMessagesIds);
                                                print("This is a corona ${replyMessagesIds}");
                                              },

                                              icon: const Icon(
                                                Icons.delete,
                                                size: 20,
                                                color: Colors.red,
                                              ),
                                            ),
                                          ],
                                        )
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                    if (hasFileToSEnd && files != null)
                      Visibility(
                          visible: true,
                          child: Container(
                            width: MediaQuery.of(context).size.width,
                            height: calculateGridHeight(files.length),
                            decoration: BoxDecoration(
                              color: Colors.grey[600],
                              borderRadius: BorderRadius.circular(13),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: GridView.builder(
                                physics: const NeverScrollableScrollPhysics(),
                                gridDelegate:
                                    const SliverGridDelegateWithFixedCrossAxisCount(
                                        crossAxisCount: 3,
                                        mainAxisSpacing: 2,
                                        crossAxisSpacing: 3,
                                        mainAxisExtent: 40),
                                itemCount: files.length,
                                itemBuilder: (context, index) {
                                  final file = files[index];
                                  return buildFile(file);
                                },
                              ),
                            ),
                          )),
                    TextFormField(
                      controller: replyTextController,
                      keyboardType: TextInputType.text,
                      textInputAction: TextInputAction.send,
                      maxLines: null,
                      cursorColor: kPrimaryColor,
                      decoration: InputDecoration(
                        hintText: "Sends Messages",
                        suffixIcon: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            GestureDetector(
                                onTap: () {
                                  pickFiles();
                                },
                                child: const Icon(
                                  Icons.attach_file_outlined,
                                  size: 30,
                                )),
                            const SizedBox(
                              width: 5,
                            ),
                            GestureDetector(
                              onTap: () {
                                sendReplyMessage();
                                setState(() {
                                  hasFileToSEnd = false;
                                });
                              },
                              child: const Icon(
                                Icons.telegram_outlined,
                                size: 35,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ])));
    }
  }

  Widget buildFile(PlatformFile file) {
    final kb = file.size / 1024;
    final mb = kb / 1024;
    final filesize =
        mb >= 1 ? '${mb.toStringAsFixed(2)} MB' : '${kb.toStringAsFixed(2)} KB';
    final extension = file.extension?.toLowerCase() ?? 'none';
    final isImage = ['png', 'jpg', 'jpeg', 'gif', 'bmp'].contains(extension);
    final isExcel = extension == 'xlsx' || extension == 'xls';
    final isTxt = extension == 'txt';
    final isPdf = extension == 'pdf';

    return Stack(
      children: [
        Container(
          padding: const EdgeInsets.all(5),
          decoration: BoxDecoration(
              color: Colors.white, borderRadius: BorderRadius.circular(5)),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              isImage
                  ? (!kIsWeb)
                      ? Image.file(
                          File(file.path!),
                          fit: BoxFit.cover,
                        )
                      : Image.memory(file.bytes!)
                  : isExcel
                      ? Container(
                          padding: const EdgeInsets.all(3),
                          alignment: Alignment.center,
                          height: 20,
                          width: 15,
                          decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(8),
                              color: Colors.green),
                          child: const Text(
                            "E",
                            style: TextStyle(color: Colors.white, fontSize: 8),
                          ),
                        )
                      : isTxt
                          ? Container(
                              padding: const EdgeInsets.all(3),
                              alignment: Alignment.center,
                              height: 20,
                              width: 15,
                              decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(8),
                                  color: Colors.blue),
                              child: const Text(
                                "T",
                                style:
                                    TextStyle(color: Colors.white, fontSize: 8),
                              ),
                            )
                          : isPdf
                              ? Container(
                                  padding: const EdgeInsets.all(3),
                                  alignment: Alignment.center,
                                  height: 20,
                                  width: 15,
                                  decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(8),
                                      color: Colors.red),
                                  child: const Text(
                                    "P",
                                    style: TextStyle(
                                        color: Colors.white, fontSize: 8),
                                  ),
                                )
                              : const Icon(Icons.description),
              const SizedBox(
                width: 8,
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      file.name,
                      softWrap: true,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          fontSize: 10, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      filesize,
                      style: const TextStyle(fontSize: 10),
                    )
                  ],
                ),
              ),
            ],
          ),
        ),
        Positioned(
            right: 0,
            top: 0,
            child: GestureDetector(
              onTap: () {
                setState(() {
                  files.remove(file);
                });
              },
              child: const Icon(
                Icons.close,
                size: 13,
              ),
            )),
      ],
    );
  }

  double calculateGridHeight(int itemCount) {
    // Define the height of each grid item
    const double itemHeight = 40.0;
    // Define the number of items per row
    const int itemsPerRow = 3;
    // Calculate the number of rows needed
    int numRows = (itemCount / itemsPerRow).ceil();
    // Calculate the total height, including spacing between rows
    const double spacing = 15.0;
    double totalHeight = (itemHeight + spacing) * numRows;
    return totalHeight;
  }

  Widget _buildSingleFile(String? fileUrl) {
    if (fileUrl == null || fileUrl.isEmpty) {
      return Container();
    }

    final isImage = _isImage(fileUrl);
    final isExcel = _isExcel(fileUrl);
    final isTxt = _isTxt(fileUrl);
    final isPdf = _isPdf(fileUrl);

    String modifiedUrl;

    if (platform == TargetPlatform.android) {
      modifiedUrl = replaceMinioWithIP(fileUrl, ipAddress);
    } else {
      modifiedUrl = fileUrl;
    }

    if (isImage) {
      return Column(
        children: [
          const SizedBox(
            height: 8,
          ),
          Stack(
            alignment: Alignment.topRight,
            children: [
              GestureDetector(
                onTap: () {
                  showDialog(
                    context: context,
                    builder: (context) => Dialog(
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          maxWidth: MediaQuery.of(context).size.width * 0.9,
                          maxHeight: MediaQuery.of(context).size.height * 0.9,
                        ),
                        child: Stack(children: [
                          Image.network(modifiedUrl, fit: BoxFit.contain),
                          Positioned(
                            top: 8,
                            right: 8,
                            child: GestureDetector(
                              onTap: () {
                                Navigator.pop(context);
                              },
                              child: Container(
                                decoration: BoxDecoration(
                                  color: Colors.black54,
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: const Icon(
                                  Icons.close,
                                  size: 24,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ]),
                      ),
                    ),
                  );
                },
                child: Container(
                  width: MediaQuery.of(context).size.width * 0.5,
                  height: MediaQuery.of(context).size.height * 0.3,
                  child: Image.network(modifiedUrl, fit: BoxFit.cover),
                ),
              ),
              Positioned(
                top: 8,
                right: 8,
                child: InkWell(
                  onTap: () async {
                    try {
                      await DownloadFile.downloadFile(
                          modifiedUrl, modifiedUrl.split('/').last, context);
                    } catch (e) {
                      print("Download Failed.\n\n$e");
                    }
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.black54,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(
                      Icons.download,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      );
    } else {
      return _buildFileContainer(modifiedUrl, isExcel, isTxt, isPdf);
    }
  }

   Widget _buildMultipleFiles(List<dynamic> files) {
    List<dynamic> images = files.where((file) => _isImage(file!)).toList();
    List<dynamic> others = files.where((file) => !_isImage(file!)).toList();
    return Column(
      children: [
        const SizedBox(
          height: 8,
        ),
        if (images.isNotEmpty)
          GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 1,
              ),
              itemCount: images.length,
              itemBuilder: (context, index) {
                String modifiedUrl;
                if (platform == TargetPlatform.android) {
                  modifiedUrl = replaceMinioWithIP(images[index]!, ipAddress);
                } else {
                  modifiedUrl = images[index]!;
                }
                return Stack(
                  children: [
                    GestureDetector(
                      onTap: () {
                        showDialog(
                          context: context,
                          builder: (context) => Dialog(
                            child: ConstrainedBox(
                              constraints: BoxConstraints(
                                maxWidth:
                                    MediaQuery.of(context).size.width * 0.9,
                                maxHeight:
                                    MediaQuery.of(context).size.height * 0.9,
                              ),
                              child: Stack(children: [
                                Image.network(modifiedUrl, fit: BoxFit.contain),
                                Positioned(
                                  top: 8,
                                  right: 8,
                                  child: GestureDetector(
                                    onTap: () {
                                      Navigator.pop(context);
                                    },
                                    child: Container(
                                      decoration: BoxDecoration(
                                        color: Colors.black54,
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                      child: const Icon(
                                        Icons.close,
                                        size: 24,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ),
                              ]),
                            ),
                          ),
                        );
                      },
                      child: Container(
                        width: MediaQuery.of(context).size.width * 0.5,
                        height: MediaQuery.of(context).size.height * 0.3,
                        child: Image.network(modifiedUrl, fit: BoxFit.cover),
                      ),
                    ),
                    Positioned(
                      top: 8,
                      right: 8,
                      child: InkWell(
                        onTap: () async {
                          try {
                            await DownloadFile.downloadFile(modifiedUrl,
                                modifiedUrl.split('/').last, context);
                          } catch (e) {
                            print("Download Failed.\n\n$e");
                          }
                        },
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.black54,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: const Icon(
                            Icons.download,
                            color: Colors.white,
                            size: 24,
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              }),
        const SizedBox(
          height: 8,
        ),
        if (others.isNotEmpty)
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: others.length,
            itemBuilder: (context, index) {
              String? fileUrl = others[index];
              String modifiedUrl;
              if (platform == TargetPlatform.android) {
                modifiedUrl = replaceMinioWithIP(fileUrl!, ipAddress);
              } else {
                modifiedUrl = fileUrl!;
              }
              final isExcel = _isExcel(modifiedUrl);
              final isTxt = _isTxt(modifiedUrl);
              final isPdf = _isPdf(modifiedUrl);
              return _buildFileContainer(modifiedUrl, isExcel, isTxt, isPdf);
            },
          ),
      ],
    );
  }

  Widget _buildFileContainer(
      String fileUrl, bool isExcel, bool isTxt, bool isPdf) {
    return Column(
      children: [
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(5),
          decoration: BoxDecoration(
              color: Colors.white, borderRadius: BorderRadius.circular(5)),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              isExcel
                  ? Container(
                      padding: const EdgeInsets.all(5),
                      alignment: Alignment.center,
                      height: 20,
                      width: 20,
                      decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          color: Colors.green),
                      child: const Text(
                        "E",
                        style: TextStyle(color: Colors.white, fontSize: 10),
                      ),
                    )
                  : isTxt
                      ? Container(
                          padding: const EdgeInsets.all(5),
                          alignment: Alignment.center,
                          height: 20,
                          width: 20,
                          decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(8),
                              color: Colors.blue),
                          child: const Text(
                            "T",
                            style: TextStyle(color: Colors.white, fontSize: 10),
                          ),
                        )
                      : isPdf
                          ? Container(
                              padding: const EdgeInsets.all(5),
                              alignment: Alignment.center,
                              height: 20,
                              width: 20,
                              decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(8),
                                  color: Colors.red),
                              child: const Text(
                                "P",
                                style: TextStyle(
                                    color: Colors.white, fontSize: 10),
                              ),
                            )
                          : const Icon(Icons.description),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      fileUrl,
                      softWrap: true,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          fontSize: 10, fontWeight: FontWeight.bold),
                    ),
                    const Text(
                      "Download to get file",
                      style: TextStyle(fontSize: 10),
                    )
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(
                  Icons.download,
                  color: Colors.black,
                  size: 20,
                ),
                onPressed: () async {
                  await DownloadFile.downloadFile(
                      fileUrl, fileUrl.split('/').last, context);
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  bool _isImage(String fileUrl) {
    return fileUrl.endsWith('.png') ||
        fileUrl.endsWith('.jpg') ||
        fileUrl.endsWith('.jpeg') ||
        fileUrl.endsWith('.gif') ||
        fileUrl.endsWith('.bmp');
  }

  bool _isExcel(String fileUrl) {
    return fileUrl.endsWith('.xlsx') || fileUrl.endsWith('.xls');
  }

  bool _isTxt(String fileUrl) {
    return fileUrl.endsWith('.txt');
  }

  bool _isPdf(String fileUrl) {
    return fileUrl.endsWith('.pdf');
  }
}
