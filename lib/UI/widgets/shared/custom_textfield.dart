import 'package:flutter/material.dart';
import 'package:letschat/colors.dart';
import 'package:letschat/theme.dart';

class CustomTextField extends StatelessWidget {
  final String hint;
  final Function(String val) onChnaged;
  final double height;
  final TextInputAction inputAction;
  const CustomTextField(
      {this.hint, this.height = 54, this.onChnaged, this.inputAction});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      child: TextField(
        keyboardType: TextInputType.text,
        onChanged: onChnaged,
        textInputAction: inputAction,
        cursorColor: kPrimary,
        decoration: InputDecoration(
            contentPadding: EdgeInsets.only(
              left: 16.0,
              right: 16.0,
              bottom: 8.0,
            ),
            hintText: hint,
            border: InputBorder.none),
      ),
      decoration: BoxDecoration(
          color: isLightTheme(context) ? Colors.white : kBubbleDark,
          borderRadius: BorderRadius.circular(45),
          border: Border.all(
              color:
                  isLightTheme(context) ? Color(0xFFC4C4C4) : Color(0xFF393737),
              width: 1.5)),
    );
  }
}
