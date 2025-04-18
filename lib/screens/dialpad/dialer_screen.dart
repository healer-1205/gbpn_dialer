import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gbpn_dealer/utils/extension.dart';

class DialpadScreen extends StatefulWidget {
  const DialpadScreen(
      {required this.phoneNumberController,
      required this.onMakeCall,
      super.key});
  final TextEditingController phoneNumberController;
  final ValueChanged<String> onMakeCall;
  @override
  State<DialpadScreen> createState() => _DialpadScreenState();
}

class _DialpadScreenState extends State<DialpadScreen> {
  late TextEditingController _controller;
  final ScrollController _scrollController = ScrollController();
  final FocusNode _focusNode = FocusNode();

  @override
  void dispose() {
    _scrollController.dispose();
    _focusNode.dispose();

    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _controller = widget.phoneNumberController;
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
          padding: const EdgeInsets.symmetric(horizontal: 40.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              // Align(
              //   alignment: Alignment.centerLeft,
              //   child: Text(
              //     "GBPN Dialer",
              //     style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              //   ),
              // ),
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
    IconData icon = Icons.call;

    return GestureDetector(
      // onTap: _isCallActive ? _hangUpCall : _makeCall,
      onTap: () => widget.onMakeCall(_controller.text),
      child: Container(
        height: context.screenWidth / 5.5,
        width: context.screenWidth / 5.5,
        decoration: const BoxDecoration(
          color: Colors.green,
          shape: BoxShape.circle,
        ),
        child: Icon(
          icon,
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
