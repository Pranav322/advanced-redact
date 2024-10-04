import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:math';
import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'package:share_plus/share_plus.dart';
import 'decrypt_animation.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'dart:convert';
import 'package:video_player/video_player.dart';
import 'package:audioplayers/audioplayers.dart';
import 'dart:typed_data';

class DecryptPage extends StatefulWidget {
  @override
  _DecryptPageState createState() => _DecryptPageState();
}

class _DecryptPageState extends State<DecryptPage> {
  PlatformFile? _file;
  bool _isDecrypting = false;
  String _fileType = '';
  String? _decryptedFilePath;
  final TextEditingController _aesKeyController = TextEditingController();
  final TextEditingController _ivController = TextEditingController();
  VideoPlayerController? _videoPlayerController;
  AudioPlayer _audioPlayer = AudioPlayer();

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

  void _showDecryptionInputs() {
  showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        title: Text('Enter Decryption Details'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _aesKeyController,
                decoration: InputDecoration(labelText: 'AES Key'),
              ),
              SizedBox(height: 10),
              TextField(
                controller: _ivController,
                decoration: InputDecoration(labelText: 'IV Vector'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            child: Text('Cancel'),
            onPressed: () => Navigator.of(context).pop(),
          ),
          ElevatedButton(
            child: Text('Decrypt', style: TextStyle(color: Colors.white)),
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.primary,
            ),
            onPressed: () {
              Navigator.of(context).pop();
              if (_validateInputs()) {
                _startDecryption();
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Invalid AES Key or IV Vector')),
                );
              }
            },
          ),
        ],
      );
    },
  );
}
  bool _validateInputs() {
    // Basic validation: check if inputs are valid base64 strings
    try {
      base64.decode(_aesKeyController.text);
      base64.decode(_ivController.text);
      return true;
    } catch (_) {
      return false;
    }
  }

  void _startDecryption() {
    setState(() {
      _isDecrypting = true;
    });

    // Simulate decryption process
    Future.delayed(Duration(seconds: _getDecryptionDuration(_fileType)), () {
      setState(() {
        _isDecrypting = false;
      });
      _showDecryptedFile();
    });
  }

  int _getDecryptionDuration(String fileType) {
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

  void _showDecryptedFile() async {
  String fileName = 'Decrypted_${_file!.name}';
  String extension = '.${_file!.extension}';

  Directory tempDir = await getTemporaryDirectory();
  _decryptedFilePath = '${tempDir.path}/$fileName$extension';

  // Get the appropriate asset file based on file type
  String assetFile = _getAssetFile(_fileType);

  // Copy the asset file to the temporary directory
  try {
    ByteData data = await rootBundle.load(assetFile);
    List<int> bytes = data.buffer.asUint8List();
    await File(_decryptedFilePath!).writeAsBytes(bytes);
    print('Decrypted file created at: $_decryptedFilePath');
  } catch (e) {
    print('Error creating decrypted file: $e');
    return;
  }

  Widget content;
  if (_fileType == 'image') {
    content = Image.file(File(_decryptedFilePath!));
  } else if (_fileType == 'video') {
    content = _buildVideoPlayer();
  } else if (_fileType == 'audio') {
    content = _buildAudioPlayer();
  } else {
    content = Icon(Icons.insert_drive_file, size: 50);
  }

  showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        title: Text('Decrypted ${_fileType.capitalize()}'),
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
          if (_fileType != 'image')
            TextButton(
              child: Text('Open'),
              onPressed: () {
                OpenFile.open(_decryptedFilePath!);
              },
            ),
          ElevatedButton(
            child: Text('Download', style: TextStyle(color: Colors.white)),
            onPressed: () {
              _downloadDecryptedFile(fileName, extension);
            },
          ),
        ],
      );
    },
  );
}
Future<void> _downloadDecryptedFile(String fileName, String extension) async {
  try {
    Directory? downloadsDirectory;
    if (Platform.isAndroid) {
      downloadsDirectory = Directory('/storage/emulated/0/Download');
    } else if (Platform.isIOS) {
      downloadsDirectory = await getApplicationDocumentsDirectory();
    } else {
      downloadsDirectory = await getDownloadsDirectory();
    }

    if (downloadsDirectory == null) {
      throw Exception('Could not access downloads directory');
    }

    String downloadPath = '${downloadsDirectory.path}/$fileName$extension';
    await File(_decryptedFilePath!).copy(downloadPath);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('File downloaded to: $downloadPath')),
    );
  } catch (e) {
    print('Error downloading file: $e');
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Error downloading file. Please try again.')),
    );
  }
}
  String _getAssetFile(String fileType) {
    String basePath = 'assets/decrypted/';
    switch (fileType) {
      case 'image':
        return '${basePath}image.jpg';
      case 'audio':
        return '${basePath}audio.mp3';
      case 'video':
        return '${basePath}video.mp4';
      case 'document':
        return '${basePath}document.pdf';
      default:
        return '${basePath}default.png';
    }
  }

  Widget _buildVideoPlayer() {
    if (_videoPlayerController == null) {
      _videoPlayerController = VideoPlayerController.file(File(_decryptedFilePath!))
        ..initialize().then((_) {
          setState(() {});
        });
    }
    return AspectRatio(
      aspectRatio: _videoPlayerController!.value.aspectRatio,
      child: VideoPlayer(_videoPlayerController!),
    );
  }

  Widget _buildAudioPlayer() {
    return ElevatedButton(
      onPressed: () {
        _audioPlayer.play(DeviceFileSource(_decryptedFilePath!));
      },
      child: Text('Play Audio'),
    );
  }

  @override
  void dispose() {
    _aesKeyController.dispose();
    _ivController.dispose();
    _videoPlayerController?.dispose();
    _audioPlayer.dispose();
    super.dispose();
  }

 @override
Widget build(BuildContext context) {
  return Scaffold(
    body: _isDecrypting
      ? DecryptAnimation(fileType: _fileType)
      : SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
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
                        Icons.lock_open,
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
                          foregroundColor: Theme.of(context).colorScheme.onPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
                if (_file != null) ...[
                  SizedBox(height: 30),
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
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _previewFile,
                          icon: Icon(Icons.preview),
                          label: Text("Preview"),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Theme.of(context).colorScheme.secondary,
                          ),
                        ),
                      ),
                      SizedBox(width: 16),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _showDecryptionInputs,
                          icon: Icon(Icons.lock_open),
                          label: Text("Decrypt"),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Theme.of(context).colorScheme.primary,
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