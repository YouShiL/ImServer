import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

class QRCodeScannerScreen extends StatefulWidget {
  final Function(String) onScan;
  final String title;

  const QRCodeScannerScreen({
    Key? key,
    required this.onScan,
    this.title = '扫码',
  }) : super(key: key);

  @override
  _QRCodeScannerScreenState createState() => _QRCodeScannerScreenState();
}

class _QRCodeScannerScreenState extends State<QRCodeScannerScreen> {
  bool isScanning = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        backgroundColor: Colors.white,
        elevation: 1,
        titleTextStyle: const TextStyle(
          fontFamily: 'Source Han Sans SC',
          color: Color(0xFF333333),
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
        iconTheme: const IconThemeData(color: Color(0xFF333333)),
      ),
      body: Column(
        children: <Widget>[
          Expanded(
            flex: 4,
            child: MobileScanner(
              onDetect: (capture) {
                if (isScanning) {
                  isScanning = false;
                  final String? code = capture.barcodes.first.rawValue;
                  if (code != null) {
                    widget.onScan(code);
                    Navigator.pop(context);
                  }
                }
              },
              overlay: Container(
                decoration: ShapeDecoration(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                    side: const BorderSide(color: Colors.blue, width: 10),
                  ),
                ),
                child: Stack(
                  children: [
                    // 扫描框
                    Center(
                      child: Container(
                        width: 300,
                        height: 300,
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.blue, width: 2),
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                    // 扫描线
                    Positioned(
                      top: 0,
                      left: 0,
                      right: 0,
                      bottom: 0,
                      child: Align(
                        alignment: Alignment.topCenter,
                        child: Container(
                          width: 300,
                          height: 2,
                          color: Colors.blue,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Expanded(
            flex: 1,
            child: Container(
              padding: const EdgeInsets.all(16),
              child: const Text(
                '请将二维码对准扫描框',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Source Han Sans SC',
                  fontSize: 16,
                  color: Color(0xFF666666),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
