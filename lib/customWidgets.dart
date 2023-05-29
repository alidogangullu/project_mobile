import 'package:flutter/material.dart';

Widget textInputField(
  BuildContext context,
  String hintText,
  TextEditingController controller,
  bool isNumeric, {
  IconData? iconData,
  ValueChanged<String>? onChanged,
  GestureTapCallback? onTap,
  GestureTapCallback? iconOnTap,
  FocusNode? focusNode, // Add FocusNode parameter
}) {
  return Padding(
    padding: const EdgeInsets.all(15),
    child: TextField(
      onTap: onTap,
      keyboardType: isNumeric ? TextInputType.number : TextInputType.text,
      controller: controller,
      onChanged: onChanged,
      focusNode: focusNode,
      decoration: InputDecoration(
        hintText: hintText,
        prefixIcon: iconData != null
            ? GestureDetector(
                onTap: iconOnTap,
                child: Icon(iconData),
              )
            : null,
        fillColor: Colors.white,
        filled: true,
        enabledBorder: const OutlineInputBorder(
          borderSide: BorderSide(color: Colors.grey),
        ),
        focusedBorder: OutlineInputBorder(
          borderSide: BorderSide(color: Theme.of(context).primaryColor),
        ),
      ),
    ),
  );
}

Widget menuButton(String text, void Function() onPressed, {Icon? icon}) {
  return Padding(
    padding: const EdgeInsets.fromLTRB(15, 7.5, 15, 7.5),
    child: SizedBox(
      width: double.infinity,
      height: 45,
      child: ElevatedButton(
        onPressed: onPressed,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (icon != null) icon,
            Padding(
              padding: icon != null
                  ? const EdgeInsets.fromLTRB(8, 0, 0, 0)
                  : EdgeInsets.zero,
              child: Text(
                text,
                style: const TextStyle(
                  fontSize: 16,
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

SnackBar customSnackBar(String message) {
  return SnackBar(
    content: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Text(
        message,
        style: const TextStyle(fontSize: 16.0),
      ),
    ),
    behavior: SnackBarBehavior.floating,
    backgroundColor: const Color(0xFF49516F),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(6),
    ),
  );
}