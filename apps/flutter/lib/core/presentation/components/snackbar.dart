import "package:flutter/material.dart";

void showUndoSnackbar(
  BuildContext context,
  String message,
  VoidCallback onUndo,
) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(message),
      action: SnackBarAction(label: "Desfazer", onPressed: onUndo),
    ),
  );
}

void showStandardSnackbar(BuildContext context, String message) {
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
}
