import 'package:flutter/material.dart';
import 'monkey_face.dart';

class EncryptionOption {
  final String title;
  final String tag;
  final List<String> description;

  EncryptionOption(
      {required this.title, required this.tag, required this.description});
}

class EncryptionOptionsSheet extends StatefulWidget {
  final Function(int) onProceed;
  final double heightFactor;

  const EncryptionOptionsSheet(
      {Key? key, required this.onProceed, this.heightFactor = 0.8})
      : super(key: key);

  @override
  _EncryptionOptionsSheetState createState() => _EncryptionOptionsSheetState();
}

class _EncryptionOptionsSheetState extends State<EncryptionOptionsSheet> {
  int? _selectedOption;
  int _expandedIndex = 0;
  double _eyeOpenness = 1.0;

  final List<EncryptionOption> _options = [
    EncryptionOption(
      title: "Pixel Scramble",
      tag: "Offline & Irrecoverable",
      description: [
        "Sensitive content is hidden behind black bars",
        "For multimedia: pixelated areas where faces",
        "Quick and basic redaction for immediate privacy"
      ],
    ),
    EncryptionOption(
      title: "Encrypted Mask",
      tag: "Offline & Recoverable",
      description: [
        "The sensitive content of your file is locked up with a secret key.",
        "Without a key it's just a bunch of random, unreadable text.",
        "Only people who have permission can view or change that information.",
        "Keep your key safe it's Irrecoverable",
      ],
    ),
    EncryptionOption(
      title: "Synthetic Shield",
      tag: "Online & Irrecoverable",
      description: [
        "Sensitive details are swapped with fake, random information.",
        "The overall structure stays intact",
        "Privacy-preserving anonymization with synthetic data"
      ],
    ),
    EncryptionOption(
      title: "Blockchain Guard",
      tag: "Online and Recoverable",
      description: [
        "Verifiable, tamper-proof  redaction",
        "Auditing is possible",
        "Redaction Without Revelation",
        "Guarantees document integrity and compliance with GDPR"
      ],
    ),
    EncryptionOption(
      title: "Secure Shred",
      tag: "Offline and Irrecoverable",
      description: [
        "Irrecoverable deletion to permanently destroy sensitive data.",
        "Data cannot be leaked or recovered, even with advanced forensic tools.",
        "Guarantees Sensitive data cannot be reconstructed."
      ],
    ),
  ];

  void _updateEyeOpenness(int? option) {
    if (option != null) {
      setState(() {
        _selectedOption = option;
        _eyeOpenness = (option / (_options.length - 1));
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      return Column(
        children: [
          Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              children: [
                Text(
                  "Choose Redaction Option",
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                SizedBox(height: 16),
                MonkeyFace(eyeOpenness: _eyeOpenness),
              ],
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              physics: AlwaysScrollableScrollPhysics(),
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ..._options.asMap().entries.map((entry) {
                      int index = entry.key;
                      EncryptionOption option = entry.value;
                      return _buildAccordion(index, option);
                    }),
                    SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _selectedOption != null
                          ? () => widget.onProceed(_selectedOption!)
                          : null,
                      child: Text("Proceed"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).colorScheme.primary,
                        foregroundColor: Colors.white,
                        minimumSize: Size(double.infinity, 50),
                      ),
                    ),
                    SizedBox(height: 100),
                  ],
                ),
              ),
            ),
          ),
        ],
      );
    });
  }

  Widget _buildAccordion(int index, EncryptionOption option) {
    bool isExpanded = _expandedIndex == index;
    return Column(
      children: [
        ListTile(
          title: Row(
            children: [
              Expanded(
                child: Text(option.title),
              ),
              SizedBox(width: 8),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.secondary,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  option.tag,
                  style: TextStyle(color: Colors.white, fontSize: 12),
                ),
              ),
            ],
          ),
          trailing: Icon(isExpanded ? Icons.expand_less : Icons.expand_more),
          onTap: () {
            setState(() {
              _expandedIndex = isExpanded ? -1 : index;
            });
          },
        ),
        AnimatedCrossFade(
          firstChild: SizedBox(height: 0),
          secondChild: _buildAccordionContent(option, index),
          crossFadeState:
              isExpanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
          duration: Duration(milliseconds: 300),
        ),
      ],
    );
  }

  Widget _buildAccordionContent(EncryptionOption option, int index) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ...option.description.map((desc) => Padding(
                padding: EdgeInsets.only(bottom: 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("• "),
                    Expanded(child: Text(desc)),
                  ],
                ),
              )),
          SizedBox(height: 8),
          Row(
            children: [
              Radio<int>(
                value: index,
                groupValue: _selectedOption,
                onChanged: (int? value) {
                  _updateEyeOpenness(value);
                },
              ),
              Text("Agree and would like to proceed"),
            ],
          ),
        ],
     ),
);
}
}