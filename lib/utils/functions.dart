import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:proyecto_verde_participativo/constants/colors.dart';

String hashPassword(String password) {
  final bytes = utf8.encode(password);
  final digest = sha256.convert(bytes);
  return digest.toString();
}

void showCustomBottomSheet(
  BuildContext context,
  Widget Function(ScrollController) contentBuilder, {
  bool canExpand = false,
}) {
  final DraggableScrollableController draggableController =
      DraggableScrollableController();
  bool isClosed = false;

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    barrierColor: Colors.transparent,
    builder: (context) {
      return Stack(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              height: MediaQuery.of(context).size.height * 0.4,
              width: double.infinity,
              color: Colors.transparent,
            ),
          ),
          DraggableScrollableSheet(
            controller: draggableController,
            initialChildSize: !canExpand ? 0.6 : 0.62,
            minChildSize: 0.1,
            maxChildSize: !canExpand ? 0.6 : 1,
            snap: true,
            shouldCloseOnMinExtent: false,
            builder: (context, scrollController) {
              // Agregar un listener para cerrar cuando la altura sea menor a 0.2
              draggableController.addListener(() {
                if (draggableController.size <= 0.2) {
                  if (!isClosed) {
                    isClosed = true;
                    Navigator.pop(context);
                  }
                }
              });

              return Container(
                decoration: BoxDecoration(
                  color: Color(AppColors.darkGreen),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(27),
                    topRight: Radius.circular(27),
                  ),
                ),
                child: contentBuilder(scrollController),
              );
            },
          ),
        ],
      );
    },
  );
}