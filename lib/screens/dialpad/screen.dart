import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gbpn_dealer/services/storage_service.dart';
import 'package:gbpn_dealer/utils/extension.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:twilio_voice/twilio_voice.dart';

class DialpadScreen extends StatefulWidget {
  const DialpadScreen({super.key});

  @override
  State<DialpadScreen> createState() => _DialpadScreenState();
}

class _DialpadScreenState extends State<DialpadScreen> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _focusNode = FocusNode();
  final StorageService _storageService = StorageService();
  String _twilioAccessToken = "";
  final platform = MethodChannel('twilio_voice');

  @override
  void initState() {
    super.initState();
    _controller.text = "";
    _getTwilioAccessToken();
    requestPermissions();
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> requestPermissions() async {
    await Permission.microphone.request();
    await Permission.phone.request();
  }

  Future<void> _getTwilioAccessToken() async {
    String? twilioAccessToken = await _storageService.getTwilioAccessToken();
    setState(() => _twilioAccessToken = twilioAccessToken!);
  }

  Future<void> _makeCall(String token, String to) async {
    try {
      await TwilioVoice.instance.requestReadPhoneNumbersPermission();
      await TwilioVoice.instance.requestCallPhonePermission();
      await TwilioVoice.instance.registerPhoneAccount();
      await TwilioVoice.instance.openPhoneAccountSettings();
      bool isPhoneAccountEnabled =
          await TwilioVoice.instance.isPhoneAccountEnabled();

      if (isPhoneAccountEnabled) {
        TwilioVoice.instance.requestCallPhonePermission();
        // TwilioVoice.instance.callEventsListener.listen(
        //   (event) {},
        //   onError: (error, stackTrace) {
        //     print("Errortrack: $error");
        //     print("StackTrace: $stackTrace");
        //   },
        //   onDone: () {
        //     print("Call Event Stream Closed.");
        //   },
        // );
        const testtoken = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCIsImN0eSI6InR3aWxpby1mcGE7dj0xIn0.eyJqdGkiOiJTSzkwYjU4ODg5ZWU2OTRlNzlkYmJhOWFiNmE5NTk2Y2EyLTE3NDE5NDk0NTciLCJncmFudHMiOnsiaWRlbnRpdHkiOiJ1c2VyIiwidm9pY2UiOnsiaW5jb21pbmciOnsiYWxsb3ciOnRydWV9LCJvdXRnb2luZyI6eyJhcHBsaWNhdGlvbl9zaWQiOiJBUDhlOTc0YWIxOGYyOGM2M2IyOTliOTFlYTk1ZjNmNjc3In19fSwiaWF0IjoxNzQxOTQ5NDU3LCJleHAiOjE3NDE5NTMwNTcsImlzcyI6IlNLOTBiNTg4ODllZTY5NGU3OWRiYmE5YWI2YTk1OTZjYTIiLCJzdWIiOiJBQzhmOTlhNTM5NjZjZjI4Mjk3YjgyMTcyODE2YzE0MTM1In0.auZZXSUQoEdzpGD8SbneMC894-NMO-TCfN63r4wvFR4";
        await TwilioVoice.instance.setTokens(
            accessToken: testtoken,
            deviceToken:
                "eA1b23C4dEfGhI5j6K7LmNoPqRsTuVwXyZ890ABcDeFgHIJKLMNOP1234567890abcdef");
        print("Token setup successful!");
        try {
          await TwilioVoice.instance.call
              .place(from: "+15093611979", to: "+18042221111");
        } on PlatformException catch (e) {
          print("reason: ${e.message}");
        }
      }
    } on PlatformException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Call failed: ${e.message}")),
      );
    }
  }

  void _onNumberPressed(String number) {
    int cursorPosition = _controller.selection.baseOffset;

    if (cursorPosition < 0) {
      cursorPosition = _controller.text.length;
    }

    String newText = _controller.text.substring(0, cursorPosition) +
        number +
        _controller.text.substring(cursorPosition);

    setState(() {
      _controller.text = newText;
      _controller.selection =
          TextSelection.collapsed(offset: cursorPosition + 1);
    });

    scrollToEndPosition();

    HapticFeedback.lightImpact();
  }

  void _onBackspace() {
    int cursorPosition = _controller.selection.baseOffset;

    if (cursorPosition > 0) {
      String newText = _controller.text.substring(0, cursorPosition - 1) +
          _controller.text.substring(cursorPosition);

      setState(() {
        _controller.text = newText;
        _controller.selection =
            TextSelection.collapsed(offset: cursorPosition - 1);
      });

      scrollToEndPosition();

      HapticFeedback.mediumImpact();
    }
  }

  void _onLongBackspace() {
    if (_controller.text.isNotEmpty) {
      setState(() {
        _controller.text = "";
      });

      HapticFeedback.lightImpact();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 40.0, vertical: 40),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildNumberDisplay(),
              _buildDialpad(),
              _buildActionButtons(),
            ],
          )

          // Old UI
          // Column(
          //   children: [
          //     const SizedBox(height: 50),
          //     const Align(
          //       alignment: Alignment.centerLeft,
          //       child: Text(
          //         "GBPN Dialer",
          //         style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          //       ),
          //     ),
          //     const Spacer(),
          //     _buildNumberDisplay(),
          //     const SizedBox(height: 10),
          //     _buildDialpad(),
          //     const SizedBox(height: 20),
          //     _buildActionButtons(),
          //     const SizedBox(height: 40),
          //   ],
          // ),
          ),
      // bottomNavigationBar: _buildBottomNavigation(),
    );
  }

  Widget _buildNumberDisplay() {
    return TextField(
      controller: _controller,
      focusNode: _focusNode,
      scrollController: _scrollController,
      readOnly: true,
      showCursor: true,
      textAlign: TextAlign.center,
      style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
      decoration: const InputDecoration(
        border: InputBorder.none,
      ),
    );
  }

  Widget _buildDialpad() {
    return Column(
      children: [
        _buildRow(["1", "2", "3"], ["", "ABC", "DEF"]),
        const SizedBox(height: 10),
        _buildRow(["4", "5", "6"], ["GHI", "JKL", "MNO"]),
        const SizedBox(height: 10),
        _buildRow(["7", "8", "9"], ["PQRS", "TUV", "WXYZ"]),
        const SizedBox(height: 10),
        _buildRow(["*", "0", "#"], ["", "+", ""]),
      ],
    );
  }

  Widget _buildRow(List<String> numbers, List<String> subTexts) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: List.generate(3, (index) {
        return _buildDialButton(numbers[index], subTexts[index]);
      }),
    );
  }

  Widget _buildDialButton(String number, String subText) {
    return Expanded(
      child: GestureDetector(
        onTap: () => _onNumberPressed(number),
        child: Container(
          height: context.screenWidth / 5.5,
          alignment: Alignment.center,
          decoration: const BoxDecoration(
            color: Color.fromARGB(255, 187, 186, 186),
            shape: BoxShape.circle,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                number,
                style: const TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Colors.white),
              ),
              if (subText.isNotEmpty)
                Text(
                  subText,
                  style: const TextStyle(fontSize: 12, color: Colors.white70),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionButtons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Spacer(),
        Expanded(
          child: Align(
            alignment: Alignment.center,
            child: _buildCallButton(),
          ),
        ),
        Expanded(
          child: Align(
            alignment: Alignment.centerRight,
            child: _buildBackspaceButton(),
          ),
        ),
      ],
    );
  }

  Widget _buildCallButton() {
    return GestureDetector(
      onTap: () async {
        if (_twilioAccessToken.isNotEmpty && _controller.text.isNotEmpty) {
          await _makeCall(_twilioAccessToken, _controller.text);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text("Enter a valid number and ensure token exists")),
          );
        }
      },
      child: Container(
        height: context.screenWidth / 5.5,
        width: context.screenWidth / 5.5,
        decoration: const BoxDecoration(
          color: Colors.green,
          shape: BoxShape.circle,
        ),
        child: const Icon(
          Icons.call,
          color: Colors.white,
          size: 32,
        ),
      ),
    );
  }

  Widget _buildBackspaceButton() {
    return GestureDetector(
      onTap: _onBackspace,
      onLongPress: _onLongBackspace,
      behavior: HitTestBehavior.translucent,
      child: const SizedBox(
        width: 70,
        height: 70,
        child: Icon(
          Icons.backspace,
          color: Color.fromARGB(255, 187, 186, 186),
          size: 32,
        ),
      ),
    );
  }

  void scrollToEndPosition() {
    _scrollController.animateTo(_scrollController.position.maxScrollExtent + 13,
        curve: Curves.ease, duration: Duration(milliseconds: 100));
    _focusNode.requestFocus();
  }
}
