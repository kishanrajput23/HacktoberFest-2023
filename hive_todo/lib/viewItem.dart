import 'package:flutter/material.dart';

class viewItem extends StatelessWidget {
  String activity;
  String description;
  Function() onEdit;
  Function() onDelete;
  Function() onTap;
  Color colors;

  viewItem({
    super.key,
    required this.activity,
    required this.description,
    required this.onEdit,
    required this.onDelete,
    required this.onTap,
    required this.colors,
  });

  //random color

  @override
  Widget build(BuildContext context) => Container(
        child: InkWell(
          onTap: onTap,
          child: Row(
            children: [
              Container(
                margin: const EdgeInsets.only(bottom: 10),
                height: 100,
                width: 50,
                decoration: BoxDecoration(
                  color: colors,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(12.0),
                    bottomLeft: Radius.circular(12.0),
                  ),
                ),
                child: Center(
                  child: IconButton(
                    onPressed: onDelete,
                    icon: const Icon(
                      Icons.delete_forever,
                      size: 32.0,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  height: 100,
                  padding: const EdgeInsets.all(16),
                  width: MediaQuery.of(context).size.width * 0.7,
                  decoration: const BoxDecoration(
                    boxShadow: [
                      BoxShadow(
                        color: Color(0x19000000),
                        blurRadius: 24,
                        spreadRadius: 0.5,
                        offset: Offset(0, 12),
                      ),
                    ],
                    color: Colors.white,
                    borderRadius: BorderRadius.only(
                      topRight: Radius.circular(12.0),
                      bottomRight: Radius.circular(12.0),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      SizedBox(
                        width: MediaQuery.of(context).size.width * 0.4,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              activity,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                              ),
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                            ),
                            const SizedBox(
                              height: 6.0,
                            ),
                            Text(
                              description,
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                            ),
                          ],
                        ),
                      ),
                      Center(
                        child: IconButton(
                          onPressed: onEdit,
                          icon: Icon(
                            Icons.edit,
                            size: 24.0,
                            color: colors,
                          ),
                        ),
                      )
                    ],
                  )),
            ],
          ),
        ),
      );
}
