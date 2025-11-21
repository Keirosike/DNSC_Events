import 'package:flutter/material.dart';
import 'package:dnsc_events/colors/color.dart';

class Ordersummary extends StatefulWidget {
  const Ordersummary({super.key});

  @override
  State<Ordersummary> createState() => _OrdersummaryState();
}

class _OrdersummaryState extends State<Ordersummary> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Container(
            height: 353,
            decoration: BoxDecoration(
              color: CustomColor.background,
              borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
            ),

            child: Padding(
              padding: EdgeInsets.only(top: 5, bottom: 5, left: 15, right: 15),

              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  Container(
                    height: 4,
                    margin: EdgeInsets.symmetric(horizontal: 125, vertical: 25),
                    decoration: BoxDecoration(
                      color: CustomColor.borderGray1,
                      borderRadius: BorderRadius.circular(50),
                    ),
                  ),
                  Expanded(
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Text(
                              'Order Summary',
                              style: TextStyle(
                                fontFamily: 'InterExtra',
                                fontSize: 24,
                              ),
                            ),
                          ],
                        ),

                        Center(
                          child: Divider(
                            color: CustomColor.borderGray1,
                            thickness: 2,
                          ),
                        ),
                        Row(
                          children: [
                            Text(
                              'General Admission',
                              style: TextStyle(fontSize: 16),
                            ),
                            Spacer(),
                            Text('P30.00', style: TextStyle(fontSize: 16)),
                          ],
                        ),
                        Center(
                          child: Divider(
                            color: CustomColor.borderGray1,
                            thickness: 2,
                          ),
                        ),
                        Row(
                          children: [
                            Text('Subtotal', style: TextStyle(fontSize: 16)),
                            Spacer(),
                            Text('P30.00', style: TextStyle(fontSize: 16)),
                          ],
                        ),
                        Center(
                          child: Divider(
                            color: CustomColor.borderGray1,
                            thickness: 2,
                          ),
                        ),
                        Row(
                          children: [
                            Text('Total', style: TextStyle(fontSize: 16)),
                            Spacer(),
                            Text('P30.00', style: TextStyle(fontSize: 16)),
                          ],
                        ),
                        Center(
                          child: Divider(
                            color: CustomColor.borderGray1,
                            thickness: 2,
                          ),
                        ),
                        Row(
                          children: [
                            Text(
                              'Payment Method',
                              style: TextStyle(fontSize: 16),
                            ),
                            Spacer(),
                            Text('Cash', style: TextStyle(fontSize: 16)),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.symmetric(vertical: 10),
                    child: Container(
                      height: 48,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: CustomColor.primary,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Center(
                        child: Text(
                          'Confirm Purchase',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
