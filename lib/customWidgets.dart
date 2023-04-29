import 'package:flutter/material.dart';

Widget textInputField(
    BuildContext context,
    String hintText,
    TextEditingController controller,
    bool isNumeric,
    {IconData? iconData, ValueChanged<String>? onChanged}
    ) {
  return Padding(
    padding: const EdgeInsets.all(15),
    child: TextField(
      keyboardType: isNumeric ? TextInputType.number : TextInputType.text,
      controller: controller,
      onChanged: onChanged,
      decoration: InputDecoration(
        hintText: hintText,
        prefixIcon: iconData != null ? Icon(iconData) : null,
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