import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:gbpn_dealer/widgets/common_recent_call_view.dart';

import '../../dummy_data/recent_calls_dummies.dart';
import '../../utils/common.dart';

class RecentScreen extends StatefulWidget {
  const RecentScreen({super.key});

  @override
  State<RecentScreen> createState() => _RecentScreenState();
}

class _RecentScreenState extends State<RecentScreen> {
  List<DateTime> dates = [];

  @override
  void initState() {
    super.initState();
    log(recentCalls.toString());
    // recentCalls.map((e) {
    //   DateTime contactDate =
    //       DateTime(e.dateTime.year, e.dateTime.month, e.dateTime.day);
    //   if (!dates.any((d) => d == contactDate)) {
    //     dates.add(e.dateTime);
    //   }
    // }).toList();
    for (int i = 0; i < recentCalls.length; i++) {
      DateTime contactDate = DateTime(recentCalls[i].dateTime.year,
          recentCalls[i].dateTime.month, recentCalls[i].dateTime.day);
      if (!dates.any((d) => d == contactDate)) dates.add(contactDate);
    }
    log(dates.toString());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: ListView.builder(
        shrinkWrap: true,
        itemCount: dates.length,
        itemBuilder: (BuildContext context, int parentIndex) {
          String title = Common.convertIntoDay(dates[parentIndex]);
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 25),
                child: Text(
                  title,
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                ),
              ),
              ListView.separated(
                physics: const NeverScrollableScrollPhysics(),
                shrinkWrap: true,
                itemCount: recentCalls.length,
                itemBuilder: (context, index) {
                  DateTime childDate = DateTime(
                      recentCalls[index].dateTime.year,
                      recentCalls[index].dateTime.month,
                      recentCalls[index].dateTime.day);
                  return dates[parentIndex] == childDate
                      ? Container(
                          padding: EdgeInsets.symmetric(
                              horizontal: 25, vertical: 20),
                          child: InkWell(
                            onTap: () {
                              setState(() {
                                if (recentCalls[index].isSelected) {
                                  recentCalls[index].isSelected = false;
                                } else {
                                  recentCalls
                                      .map((e) => e.isSelected = false)
                                      .toList();
                                  recentCalls[index].isSelected =
                                      !recentCalls[index].isSelected;
                                }
                              });
                            },
                            child: CommonRecentCallView(
                                recentCall: recentCalls[index]),
                          ),
                        )
                      : Container();
                },
                separatorBuilder: (BuildContext context, int index) {
                  DateTime childDate = DateTime(
                      recentCalls[index].dateTime.year,
                      recentCalls[index].dateTime.month,
                      recentCalls[index].dateTime.day);
                  return dates[parentIndex] == childDate
                      ? Padding(
                          padding: EdgeInsets.symmetric(horizontal: 25),
                          child: Divider(
                            color: Colors.grey.withAlpha((0.3 * 255).toInt()),
                            thickness: 1.2,
                          ),
                        )
                      : Container();
                },
              ),
            ],
          );
        },
      ),
    );
  }
}
