import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:readr/controller/pickableItemController.dart';
import 'package:readr/helpers/dataConstants.dart';
import 'package:readr/models/collection.dart';
import 'package:readr/pages/shared/timestamp.dart';

class CollectionInfo extends GetView<PickableItemController> {
  final Collection collection;
  const CollectionInfo(this.collection, {Key? key}) : super(key: key);

  @override
  String get tag => collection.controllerTag;

  @override
  Widget build(BuildContext context) {
    return Obx(
      () {
        List<Widget> children = [];
        if (controller.commentCount.value > 0) {
          children.add(SizedBox(
            height: 17,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const ImageIcon(
                  AssetImage(commentIconPng),
                  size: 17,
                  color: readrBlack50,
                ),
                const SizedBox(width: 3),
                Text(
                  controller.commentCount.value.toString(),
                  style: const TextStyle(
                    fontSize: 12,
                    color: readrBlack50,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ));
          children.add(Container(
            width: 2,
            height: 2,
            margin: const EdgeInsets.fromLTRB(4.0, 1.0, 4.0, 0.0),
            alignment: Alignment.center,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: readrBlack20,
            ),
          ));
        }

        children.add(Timestamp(collection.publishedTime));

        return SizedBox(
          height: 17,
          child: Wrap(
            crossAxisAlignment: WrapCrossAlignment.center,
            children: children,
          ),
        );
      },
    );
  }
}