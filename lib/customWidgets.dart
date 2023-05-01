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
              padding: icon != null ? const EdgeInsets.fromLTRB(8, 0, 0, 0) : EdgeInsets.zero,
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