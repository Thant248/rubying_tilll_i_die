import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:dart_frog_web_socket/dart_frog_web_socket.dart';
import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_frontend/const/permissions.dart';
import 'package:flutter_frontend/services/file_upload/download_file_web.dart';
import 'package:intl/intl.dart';
import 'package:flutter/material.dart';
import 'package:flutter_frontend/constants.dart';
import 'package:flutter_frontend/componnets/Nav.dart';
import 'package:flutter_frontend/model/SessionStore.dart';
import 'package:flutter_frontend/model/direct_message.dart';
import 'package:flutter_frontend/services/directMessage/direct_message_api.dart';
import 'package:flutter_frontend/services/userservice/api_controller_service.dart';
import 'package:flutter_frontend/screens/directThreadMessage/direct_message_thread.dart';
import 'package:flutter_frontend/services/directMessage/directMessage/direct_meessages.dart';
import 'package:path_provider/path_provider.dart';

enum SampleItem { itemOne, itemTwo, itemThree }

class DirectMessageWidget extends StatefulWidget {
  final int userId;
  final String receiverName;
  final bool user_status;

  const DirectMessageWidget({
    Key? key,
    required this.userId,
    this.user_status = false,
    required this.receiverName,
  }) : super(key: key);

  @override
  State<DirectMessageWidget> createState() => _DirectMessageWidgetState();
}

class _DirectMessageWidgetState extends State<DirectMessageWidget>
    with RouteAware {
  final DirectMessageService directMessageService = DirectMessageService();
  final TextEditingController messageTextController = TextEditingController();
  String currentUserName =
      SessionStore.sessionData!.currentUser!.name.toString();
  List<TDirectMessages>? tDirectMessages = [];
  List<TempDirectStarMsgids>? tempDirectStarMsgids = [];
  List<int>? tempStarMsgids = [];
  WebSocketChannel? _channel;

  final _apiService = ApiService(Dio(BaseOptions(headers: {
    'Content-Type': 'application/json',
    'Accept': 'application/json'
  })));

  bool isreading = false;
  bool isSelected = false;
  bool isStarred = false;
  int? _selectedMessageIndex;
  int? selectUserId;
  bool hasFileToSEnd = false;
  List<PlatformFile> files = [];
  late String localpath;
  late bool permissionReady;
  late TargetPlatform platform;
  final PermissionClass permissions = PermissionClass();
  String? fileText;

  @override
  void initState() {
    super.initState();
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
    messageTextController.dispose();
    _channel?.sink.close();
    super.dispose();
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
    var url = 'ws://localhost:3000/cable?user_id=${widget.userId}';
    _channel = WebSocketChannel.connect(Uri.parse(url));

    final subscriptionMessage = jsonEncode({
      'command': 'subscribe',
      'identifier': jsonEncode({'channel': 'ChatChannel'}),
    });

    _channel!.sink.add(subscriptionMessage);
    _channel!.stream.listen(
      (message) {
        var parsedMessage = jsonDecode(message) as Map<String, dynamic>;
        var msg = parsedMessage['message']['message'];
        var dircetmsg = msg['directmsg'];
        int id = msg['id'];
        var date = msg['created_at'];
        String send = parsedMessage['message']['sender_name'];
        String? fileUrl;
        if (parsedMessage['message']['files'] != null) {
          var files = parsedMessage['message']['files'] as List;
          fileUrl = files.map((file) => file['file'] as String).join(', ');
        }
        print(fileUrl);
        setState(() {
          tDirectMessages!.add(TDirectMessages(
              id: id,
              directmsg: dircetmsg,
              createdAt: date,
              name: send,
              fileUrl: fileUrl));
        });
      },
      onDone: () {
        print('WebSocket connection closed');
      },
      onError: (error) {
        print('WebSocket error: $error');
      },
    );
  }

  Future<void> loadMessages() async {
    var token = await getToken();
    try {
      DirectMessages messagess = await _apiService.getAllDirectMessages(
          widget.userId, token.toString());

      setState(() {
        tDirectMessages = messagess.tDirectMessages;
        tempDirectStarMsgids = messagess.tempDirectStarMsgids;
        tempStarMsgids = messagess.tDirectStarMsgids;
        ;
      });
    } catch (e) {
      print('Failed to fetch messages: $e');
    }
  }

  Future<void> sendMessage() async {
    if (messageTextController.text.isNotEmpty || files.isNotEmpty) {
      try {
        await directMessageService.sendDirectMessage(
            widget.userId, messageTextController.text.trimRight(), files);
        messageTextController.clear();
        files.clear();
      } catch (e) {
        print('Failed to send message: $e');
      }
    }
  }

  Future<String?> getToken() async {
    return await AuthController().getToken();
  }

  @override
  Widget build(BuildContext context) {
    List<TDirectMessages> uniqueMessages = [];

    for (var message in tDirectMessages!) {
      if (!uniqueMessages.any((element) => element.id == message.id)) {
        uniqueMessages.add(message);
      }
    }
    return Scaffold(
      backgroundColor: kPriamrybackground,
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        leading: IconButton(
          onPressed: () {
            setState(() {
              isreading = !isreading;
            });
            Navigator.pushReplacement(
                context, MaterialPageRoute(builder: (_) => const Nav()));
          },
          icon: const Icon(
            Icons.arrow_back,
            color: Colors.white,
          ),
        ),
        backgroundColor: navColor,
        title: Row(
          children: [
            Stack(children: [
              Container(
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.amber,
                ),
                height: 50,
                width: 50,
                child: Center(
                  child: Text(
                    widget.receiverName.isNotEmpty
                        ? "${widget.receiverName.characters.first.toUpperCase()}"
                        : "",
                    style: const TextStyle(
                      fontSize: 25,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              Positioned(
                  right: 0,
                  bottom: 0,
                  child: widget.user_status
                      ? Container(
                          height: 14,
                          width: 14,
                          decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(7),
                              border: Border.all(color: Colors.white, width: 1),
                              color: Colors.green),
                        )
                      : Container())
            ]),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "${widget.receiverName.toUpperCase()}",
                  style: const TextStyle(
                      fontSize: 18,
                      color: Colors.white,
                      fontWeight: FontWeight.bold),
                ),
              ],
            )
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
              child: ListView.builder(
            itemCount: uniqueMessages.length ?? 0,
            itemBuilder: (context, index) {
              if (tDirectMessages == null || tDirectMessages!.isEmpty) {
                return Container(); // Return an empty container if the list is null or empty
              }

              var channelStar = uniqueMessages;
              List<int> tempStar = tempStarMsgids?.toList() ?? [];
              bool isStared = tempStar.contains(channelStar[index].id);

              String message = channelStar[index].directmsg ?? "";
              List<String>? files;
              if (channelStar[index].fileUrl is String) {
                files = [channelStar[index].fileUrl!];
              } else if (channelStar[index].fileUrl is List) {
                files = channelStar[index].fileUrl as List<String>;
              } else {
                files = null;
              }

              int count = channelStar[index].count ?? 0;
              String time = channelStar[index].createdAt.toString();
              DateTime date = DateTime.parse(time).toLocal();

              String created_at =
                  DateFormat('MMM d, yyyy hh:mm a').format(date);
              bool isMessageFromCurrentUser =
                  currentUserName == channelStar[index].name;
              int directMsgIds = channelStar[index].id ?? 0;

              return SingleChildScrollView(
                child: InkWell(
                  onTap: () {
                    setState(() {
                      _selectedMessageIndex = channelStar[index].id;
                      isSelected = !isSelected;
                    });
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        vertical: 4.0, horizontal: 8.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (isMessageFromCurrentUser)
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              if (_selectedMessageIndex ==
                                      channelStar[index].id &&
                                  !isSelected)
                                Align(
                                  child: Container(
                                    padding: const EdgeInsets.all(3.0),
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(10.0),
                                    ),
                                    child: Padding(
                                      padding:
                                          const EdgeInsets.only(bottom: 10),
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceEvenly,
                                        children: [
                                          IconButton(
                                            onPressed: () async {
                                              if (_selectedMessageIndex !=
                                                  null) {
                                                await directMessageService
                                                    .deleteMsg(
                                                        _selectedMessageIndex!);
                                              }
                                            },
                                            icon: const Icon(Icons.delete),
                                            color: Colors.red,
                                          ),
                                          IconButton(
                                            onPressed: () async {
                                              Navigator.push(
                                                  context,
                                                  MaterialPageRoute(
                                                      builder: (_) =>
                                                          DirectMessageThreadWidget(
                                                              user_status: widget
                                                                  .user_status,
                                                              receiverId:
                                                                  widget.userId,
                                                              directMsgId:
                                                                  directMsgIds,
                                                              receiverName: widget
                                                                  .receiverName)));
                                            },
                                            icon: const Icon(Icons.reply),
                                            color: const Color.fromARGB(
                                                255, 15, 15, 15),
                                          ),
                                          IconButton(
                                            icon: Icon(
                                              Icons.star,
                                              color: isStared
                                                  ? Colors.yellow
                                                  : Colors.grey,
                                            ),
                                            onPressed: () async {
                                              if (_selectedMessageIndex !=
                                                  null) {
                                                if (isStared) {
                                                  await directMessageService
                                                      .directUnStarMsg(
                                                          _selectedMessageIndex!);
                                                } else {
                                                  await directMessageService
                                                      .directStarMsg(
                                                          widget.userId,
                                                          _selectedMessageIndex!);
                                                }
                                              }
                                            },
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              Container(
                                width: MediaQuery.of(context).size.width * 0.5,
                                decoration: const BoxDecoration(
                                  borderRadius: BorderRadius.only(
                                    topLeft: Radius.circular(10),
                                    topRight: Radius.circular(10),
                                    bottomLeft: Radius.circular(10),
                                    bottomRight: Radius.zero,
                                  ),
                                  color: Color.fromARGB(110, 121, 120, 124),
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      if (message.isNotEmpty)
                                        SelectableText(
                                          message,
                                          style: const TextStyle(
                                            color: Color.fromARGB(255, 0, 0, 0),
                                          ),
                                        ),
                                      if (files != null && files.isNotEmpty)
                                        ...files.length == 1
                                            ? [_buildSingleFile(files.first)]
                                            : [_buildMultipleFiles(files)],
                                      const SizedBox(height: 8),
                                      Text(
                                        created_at,
                                        style: const TextStyle(
                                          fontSize: 10,
                                          color:
                                              Color.fromARGB(255, 15, 15, 15),
                                        ),
                                      ),
                                      RichText(
                                        text: TextSpan(
                                          text: '$count',
                                          style: const TextStyle(
                                            fontSize: 12,
                                            color:
                                                Color.fromARGB(255, 15, 15, 15),
                                          ),
                                          children: const [
                                            WidgetSpan(
                                              child: Padding(
                                                padding:
                                                    EdgeInsets.only(left: 4.0),
                                                child: Icon(Icons.reply),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          )
                        else
                          Row(
                            mainAxisAlignment: MainAxisAlignment.start,
                            children: [
                              Container(
                                width: MediaQuery.of(context).size.width * 0.5,
                                decoration: const BoxDecoration(
                                  borderRadius: BorderRadius.only(
                                    topLeft: Radius.circular(10),
                                    topRight: Radius.circular(10),
                                    bottomRight: Radius.circular(10),
                                    bottomLeft: Radius.zero,
                                  ),
                                  color: Color.fromARGB(111, 113, 81, 228),
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      if (message.isNotEmpty)
                                        SelectableText(
                                          message,
                                          style: const TextStyle(
                                            color: Color.fromARGB(255, 0, 0, 0),
                                          ),
                                        ),
                                      if (files != null && files.isNotEmpty)
                                        ...files.length == 1
                                            ? [_buildSingleFile(files.first)]
                                            : [_buildMultipleFiles(files)],
                                      const SizedBox(height: 8),
                                      Text(
                                        created_at,
                                        style: const TextStyle(
                                          fontSize: 10,
                                          color: Colors.grey,
                                        ),
                                      ),
                                      RichText(
                                        text: TextSpan(
                                          text: '$count',
                                          style: const TextStyle(
                                            fontSize: 12,
                                            color:
                                                Color.fromARGB(255, 15, 15, 15),
                                          ),
                                          children: const [
                                            WidgetSpan(
                                              child: Padding(
                                                padding:
                                                    EdgeInsets.only(left: 4.0),
                                                child: Icon(Icons.reply),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              if (_selectedMessageIndex ==
                                      channelStar[index].id &&
                                  !isSelected)
                                Align(
                                  child: Container(
                                    padding: const EdgeInsets.all(3.0),
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(10.0),
                                    ),
                                    child: Padding(
                                      padding: const EdgeInsets.only(bottom: 8),
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceEvenly,
                                        children: [
                                          IconButton(
                                            icon: Icon(
                                              Icons.star,
                                              color: isStared
                                                  ? Colors.yellow
                                                  : Colors.grey,
                                            ),
                                            onPressed: () async {
                                              if (_selectedMessageIndex !=
                                                  null) {
                                                if (isStared) {
                                                  await directMessageService
                                                      .directUnStarMsg(
                                                          _selectedMessageIndex!);
                                                } else {
                                                  await directMessageService
                                                      .directStarMsg(
                                                          widget.userId,
                                                          _selectedMessageIndex!);
                                                }
                                              }
                                            },
                                          ),
                                          IconButton(
                                            onPressed: () async {
                                              Navigator.push(
                                                  context,
                                                  MaterialPageRoute(
                                                      builder: (_) =>
                                                          DirectMessageThreadWidget(
                                                              user_status: widget
                                                                  .user_status,
                                                              receiverId:
                                                                  widget.userId,
                                                              directMsgId:
                                                                  directMsgIds,
                                                              receiverName: widget
                                                                  .receiverName)));
                                            },
                                            icon: const Icon(Icons.reply),
                                            color: const Color.fromARGB(
                                                255, 15, 15, 15),
                                          ),
                                          IconButton(
                                            onPressed: () async {
                                              if (_selectedMessageIndex !=
                                                  null) {
                                                await directMessageService
                                                    .deleteMsg(
                                                        _selectedMessageIndex!);
                                              }
                                            },
                                            icon: const Icon(Icons.delete),
                                            color: Colors.red,
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
                  ),
                ),
              );
            },
          )),
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
            controller: messageTextController,
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
                      setState(() {
                        isreading = !isreading;
                      });
                      sendMessage();
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
        ],
      ),
    );
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

    String filename = fileUrl.substring(fileUrl.lastIndexOf("/") + 1);

    if (isImage) {
      return Column(
        children: [
          const SizedBox(
            height: 8,
          ),
          Stack(
            alignment: Alignment.topRight,
            children: [
              Container(
                width: MediaQuery.of(context).size.width * 0.5,
                height: MediaQuery.of(context).size.height * 0.3,
                child: Image.network(fileUrl, fit: BoxFit.cover),
              ),
              Positioned(
                top: 8,
                right: 8,
                child: InkWell(
                  onTap: () async {
                    try {
                      if (kIsWeb) {
                        await DownloadFileWeb.downloadFile(fileUrl, filename);
                      } else {
                        permissionReady = await permissions.checkPermission();
                        if (permissionReady) {
                          await _prepareSaveDir();
                          await Dio().download(fileUrl, filename);
                          print("Download Completed.");
                        }
                      }
                    } catch (e) {
                      print("Download Failed.\n\n$e");
                    }
                  },
                  child: const Icon(
                    Icons.download,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
              ),
            ],
          ),
        ],
      );
    } else {
      return _buildFileContainer(fileUrl, isExcel, isTxt, isPdf);
    }
  }

  Widget _buildMultipleFiles(List<String?> files) {
    List<String?> images = files.where((file) => _isImage(file!)).toList();
    List<String?> others = files.where((file) => !_isImage(file!)).toList();

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
              return Stack(
                children: [
                  Container(
                    width: MediaQuery.of(context).size.width * 0.5,
                    height: MediaQuery.of(context).size.height * 0.3,
                    child: Image.network(images[index]!, fit: BoxFit.cover),
                  ),
                  Positioned(
                    top: 8,
                    right: 8,
                    child: InkWell(
                      onTap: () async {
                        String filename = images[index]!
                            .substring(images[index]!.lastIndexOf("/") + 1);
                        try {
                          if (kIsWeb) {
                            await DownloadFileWeb.downloadFile(
                                images[index]!, filename);
                          } else {
                            permissionReady =
                                await permissions.checkPermission();
                            if (permissionReady) {
                              await _prepareSaveDir();
                              await Dio().download(images[index]!, filename);
                              print("Download Completed.");
                            }
                          }
                        } catch (e) {
                          print("Download Failed.\n\n$e");
                        }
                      },
                      child: const Icon(
                        Icons.download,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        const SizedBox(
          height: 8,
        ),
        if (others.isNotEmpty)
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 1,
              childAspectRatio: 5,
            ),
            itemCount: others.length,
            itemBuilder: (context, index) {
              String? fileUrl = others[index];
              final isExcel = _isExcel(fileUrl!);
              final isTxt = _isTxt(fileUrl);
              final isPdf = _isPdf(fileUrl);
              return _buildFileContainer(fileUrl, isExcel, isTxt, isPdf);
            },
          ),
      ],
    );
  }

  Widget _buildFileContainer(
      String fileUrl, bool isExcel, bool isTxt, bool isPdf) {
    return Container(
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
                            style: TextStyle(color: Colors.white, fontSize: 10),
                          ),
                        )
                      : const Icon(Icons.description),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
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
        ],
      ),
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
