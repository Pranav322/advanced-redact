import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:math';
import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'package:share_plus/share_plus.dart';
import 'encryption_options_sheet.dart';
import 'redaction_animation.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'dart:typed_data';
import 'package:share_plus/share_plus.dart';
class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _currentRedactionLevel = 1;
  PlatformFile? _file;

  bool _isRedacting = false;
  String _fileType = '';
  String? _redactedFilePath;

  Future<void> _pickFile() async {
    try {
      FileType? fileType = await _showFileTypeDialog();
      
      if (fileType == null) {
        print('File type selection cancelled');
        return;
      }

      FilePickerResult? result;
      if (fileType == FileType.image) {
        result = await FilePicker.platform.pickFiles(
          type: FileType.custom,
          allowedExtensions: ['jpg', 'jpeg', 'png', 'gif', 'bmp'],
        );
        _fileType = 'image';
      } else if (fileType == FileType.audio) {
        result = await FilePicker.platform.pickFiles( 
          type: FileType.audio,
        );
        _fileType = 'audio';
      } else if (fileType == FileType.video) {
        result = await FilePicker.platform.pickFiles(
          type: FileType.video,
        );
        _fileType = 'video';
      } else {
        result = await FilePicker.platform.pickFiles(
          type: FileType.any,
        );
        _fileType = 'document';
      }

      if (result != null && result.files.isNotEmpty) {
        setState(() {
          _file = result?.files.first;
        });
        print('File picked: ${_file!.name}');
      } else {
        print('No file selected');
      }
    } catch (e) {
      print('Error picking file: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error picking file. Please try again.')),
      );
    }
  }

  Future<FileType?> _showFileTypeDialog() async {
    return showDialog<FileType>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Select File Type'),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                _buildFileTypeOption(Icons.image, 'Image', FileType.image),
                _buildFileTypeOption(Icons.description, 'Document', FileType.any),
                _buildFileTypeOption(Icons.audiotrack, 'Audio', FileType.audio),
                _buildFileTypeOption(Icons.video_library, 'Video', FileType.video),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildFileTypeOption(IconData icon, String label, FileType fileType) {
    return ListTile(
      leading: Icon(icon),
      title: Text(label),
      onTap: () {
        Navigator.of(context).pop(fileType);
      },
    );
  }

  String _getFileSize(int bytes) {
    if (bytes <= 0) return "0 B";
    const suffixes = ["B", "KB", "MB", "GB", "TB", "PB", "EB", "ZB", "YB"];
    var i = (log(bytes) / log(1024)).floor();
    return ((bytes / pow(1024, i)).toStringAsFixed(1)) + ' ' + suffixes[i];
  }

  void _previewFile() {
    if (_file != null && _file!.path != null) {
      OpenFile.open(_file!.path!);
    }
  }

  void _showEncryptionOptions() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.6,
          minChildSize: 0.2,
          maxChildSize: 0.9,
          expand: false,
          builder: (_, controller) {
            return EncryptionOptionsSheet(
              onProceed: _onProceed,
              heightFactor: 0.8,
            );
          },
        );
      },
    );
  }

void _onProceed(int selectedOption) {
  Navigator.pop(context);
  print("Selected option in _onProceed: $selectedOption");
  setState(() {
    _isRedacting = true;
    _currentRedactionLevel = selectedOption;
    print("Current redaction level set to: $_currentRedactionLevel");
  });

  // Simulate redaction process
  Future.delayed(Duration(seconds: _getRedactionDuration(_fileType)), () {
    setState(() {
      _isRedacting = false;
    });
    _showRedactedFile(selectedOption);
  });
}
  int _getRedactionDuration(String fileType) {
    switch (fileType) {
      case 'image':
        return 3;
      case 'audio':
        return 5;
      case 'video':
        return 8;
      case 'document':
        return 4;
      default:
        return 5;
    }
  }

  void _showRedactedFile(int selectedOption) async {
     print("Showing redacted file for level: $selectedOption"); // Add this line
  String fileName = 'Redacted_${_file!.name}';
  String extension = '.${_file!.extension}';

  Directory tempDir = await getTemporaryDirectory();
  _redactedFilePath = '${tempDir.path}/$fileName$extension';

  // Get the appropriate asset file based on file type and redaction level
  String assetFile = _getAssetFile(_fileType, selectedOption);

  // Copy the asset file to the temporary directory
  try {
    ByteData data = await rootBundle.load(assetFile);
    List<int> bytes = data.buffer.asUint8List();
    await File(_redactedFilePath!).writeAsBytes(bytes);
    print('Redacted file created at: $_redactedFilePath');
  } catch (e) {
    print('Error creating redacted file: $e');
    return;
  }

  Widget content;
  if (_fileType == 'image') {
    content = Image.file(File(_redactedFilePath!));
  } else {
    content = Icon(
      _fileType == 'audio' ? Icons.audio_file :
      _fileType == 'video' ? Icons.video_file :
      Icons.insert_drive_file,
      size: 100,
    );
  }



  showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        title: Text('Redacted ${_fileType.capitalize()}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            content,
            SizedBox(height: 20),
            Text('$fileName$extension'),
          ],
        ),
        actions: <Widget>[
          TextButton(
            child: Text('Close'),
            onPressed: () {
              Navigator.of(context).pop();
            },
          ),
          TextButton(
            child: Text('Download'),
            onPressed: () async {
              bool success = await _downloadFile(fileName, extension);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(success ? 'File downloaded successfully' : 'Failed to download file')),
              );
            },
          ),
          TextButton(
            child: Text('Share'),
            onPressed: () {
              Navigator.of(context).pop(); // Close the current dialog
              _showShareOptions(fileName, extension);
            },
          ),
          if (_fileType != 'image')
            TextButton(
              child: Text('Open'),
              onPressed: () {
                OpenFile.open(_redactedFilePath!);
              },
            ),
        ],
      );
    },
  );
}

void _showShareOptions(String fileName, String extension) {
  print("Current redaction level in _showShareOptions: $_currentRedactionLevel");
  showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        title: Text('Share Options'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(Icons.lock),
              title: Text('Share without key'),
              subtitle: Text('No one else can decrypt'),
              onTap: () {
                Navigator.of(context).pop();
                _shareFile(fileName, extension, withKey: false);
              },
            ),
            if (_currentRedactionLevel == 1) // Changed to 1 to match your system
              ListTile(
                leading: Icon(Icons.vpn_key),
                title: Text('Share with key'),
                subtitle: Text('Whoever has the key can decrypt'),
                onTap: () {
                  Navigator.of(context).pop();
                  _shareFile(fileName, extension, withKey: true);
                },
              ),
          ],
        ),
      );
    },
  );
}
void _shareFile(String fileName, String extension, {required bool withKey}) async {
  print("Sharing file. WithKey: $withKey, Current redaction level: $_currentRedactionLevel");
  if (withKey && _currentRedactionLevel == 1) { // Changed to 1
    // TODO: Implement key generation and attachment logic
    String key = 'generated_key_here';
    await Share.shareXFiles(
      [XFile(_redactedFilePath!)],
      text: 'Redacted file (with key: $key)',
    );
  } else {
    await Share.shareXFiles(
      [XFile(_redactedFilePath!)],
      text: 'Redacted file (no key attached)',
    );
  }
}

String _getAssetFile(String fileType, int redactionLevel) {
  String basePath = 'assets/redacted/';
  String fileName = '${fileType}_level_$redactionLevel';
  
  switch (fileType) {
    case 'image':
      return '$basePath$fileName.png';
    case 'audio':
      return '$basePath$fileName.mp3';
    case 'video':
      return '$basePath$fileName.mp4';
    case 'document':
      return '$basePath$fileName.pdf';
    default:
      return '$basePath${fileType}_default.png';
  }
}
  Future<bool> _requestPermissions() async {
  if (Platform.isAndroid) {
    if (await _requestAndroidPermissions()) {
      return true;
    }
  } else if (Platform.isIOS) {
    return await Permission.photos.request().isGranted;
  }
  return false;
}

Future<bool> _requestAndroidPermissions() async {
  final androidInfo = await DeviceInfoPlugin().androidInfo;
  if (androidInfo.version.sdkInt <= 32) {
    // For Android 12 and below
    final status = await Permission.storage.request();
    return status.isGranted;
  } else {
    // For Android 13 and above
    final status = await [
      Permission.photos,
      Permission.videos,
      Permission.audio,
    ].request();
    return status.values.every((s) => s.isGranted);
  }
}

Future<bool> _downloadFile(String fileName, String extension) async {
  try {
    if (!await _requestPermissions()) {
      print('Necessary permissions not granted');
      return false;
    }

    Directory? directory;
    if (Platform.isAndroid) {
      directory = await getExternalStorageDirectory();
      String newPath = "";
      List<String> paths = directory!.path.split("/");
      for (int x = 1; x < paths.length; x++) {
        String folder = paths[x];
        if (folder != "Android") {
          newPath += "/" + folder;
        } else {
          break;
        }
      }
      newPath = newPath + "/Download";
      directory = Directory(newPath);
    } else if (Platform.isIOS) {
      directory = await getApplicationDocumentsDirectory();
    } else {
      print('Platform not supported for download');
      return false;
    }

    if (!await directory.exists()) {
      await directory.create(recursive: true);
    }

    String downloadPath = '${directory.path}/$fileName$extension';
    
    // Copy the redacted file to the download directory
    if (_redactedFilePath != null) {
      File redactedFile = File(_redactedFilePath!);
      if (await redactedFile.exists()) {
        int sourceFileSize = await redactedFile.length();
        print('Source redacted file size: $sourceFileSize bytes');
        if (sourceFileSize > 0) {
          await redactedFile.copy(downloadPath);
          File downloadedFile = File(downloadPath);
          int downloadedFileSize = await downloadedFile.length();
          print('Downloaded file size: $downloadedFileSize bytes');
          if (downloadedFileSize > 0 && downloadedFileSize == sourceFileSize) {
            print('File downloaded successfully to: $downloadPath');
            return true;
          } else {
            print('Downloaded file is empty or size mismatch');
            await downloadedFile.delete(); // Delete the invalid downloaded file
            return false;
          }
        } else {
          print('Source redacted file is empty');
          return false;
        }
      } else {
        print('Redacted file does not exist');
        return false;
      }
    } else {
      print('Redacted file path is null');
      return false;
    }
  } catch (e) {
    print('Error downloading file: $e');
    return false;
  }
}
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // appBar: AppBar(title: Text('File Redaction')),
      body: _isRedacting
        ? RedactionAnimation(fileType: _fileType)
        : SingleChildScrollView(
            child: Center(
              child: Padding(
                padding: EdgeInsets.all(10),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(height: 30),
                    Container(
                      width: 300,
                      height: 200,
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.secondary,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(



                            color: Theme.of(context).colorScheme.primary, width: 2),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.cloud_upload,
                            size: 60,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                          SizedBox(height: 20),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 10),
                            child: Text(
                              _file?.name ?? 'No file selected',
                              style: Theme.of(context).textTheme.bodyLarge,
                              textAlign: TextAlign.center,
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                            ),
                          ),
                          SizedBox(height: 20),
                          ElevatedButton(
                            onPressed: _pickFile,
                            child: Text("Choose File"),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Theme.of(context).colorScheme.primary,
                              foregroundColor:
                                  Theme.of(context).colorScheme.onPrimary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 30),
                    if (_file != null) ...[
                      Text(
                        'File Details',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      SizedBox(height: 15),
                      _buildFileDetail('File Name', _file!.name),
                      _buildFileDetail('File Size', _getFileSize(_file!.size)),
                      _buildFileDetail('File Type', _file!.extension ?? 'Unknown'),
                      SizedBox(height: 30),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Flexible(
                            fit: FlexFit.tight,
                            child: ElevatedButton.icon(
                              onPressed: _previewFile,
                              icon: Icon(Icons.preview),
                              label: Text("Preview File"),
                              style: ElevatedButton.styleFrom(
                                backgroundColor:
                                    Theme.of(context).colorScheme.secondary,
                              ),
                            ),
                          ),
                          SizedBox(width: 20),
                          Flexible(
                            fit: FlexFit.tight,
                            child: ElevatedButton.icon(
                              onPressed: _showEncryptionOptions,
                              icon: Icon(Icons.lock),
                              label: Text("Redact"),
                              style: ElevatedButton.styleFrom(
                                backgroundColor:
                                    Theme.of(context).colorScheme.primary,
                                foregroundColor: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
    );
  }

  Widget _buildFileDetail(String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          Expanded(
            child: Text(
              '$label: ',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Colors.white70,
                    fontWeight: FontWeight.w500,
                  ),
            ),
          ),
          Expanded(
            child: Text.rich(
              TextSpan(text: value),
              style: Theme.of(context).textTheme.bodyLarge,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

extension StringExtension on String {
  String capitalize() {
    return "${this[0].toUpperCase()}${this.substring(1)}";
  }
}