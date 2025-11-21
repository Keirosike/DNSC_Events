import 'package:dnsc_events/student.dart';
import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import 'package:dnsc_events/colors/color.dart';

class Appbar extends StatelessWidget implements PreferredSizeWidget {
  final bool isLoading;
  const Appbar({super.key, required this.isLoading});

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      automaticallyImplyLeading: false,
      backgroundColor: Colors.white,
      scrolledUnderElevation: 0,
      title: isLoading
          ? Shimmer.fromColors(
              baseColor: Colors.grey.shade300,
              highlightColor: Colors.white,
              child: Row(
                children: [
                  Container(
                    width: 150,
                    height: 24,
                    color: Colors.grey.shade300,
                  ),
                  const Spacer(),
                  Container(
                    width: 20,
                    height: 20,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.grey.shade300,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Container(
                    width: 20,
                    height: 20,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.grey.shade300,
                    ),
                  ),
                ],
              ),
            )
          : GestureDetector(
              onTap: () {
                // Go back to Homepage and remove all previous routes
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (context) => const Student()),
                  (route) => false,
                );
              },
              child: Row(
                children: [
                  Image.asset('assets/image/dnscEvents.png', height: 40),
                  const SizedBox(width: 5),
                  Text(
                    'DNSC ',
                    style: TextStyle(
                      fontSize: 18,
                      fontFamily: 'InterExtra',
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  Text(
                    'Events',
                    style: TextStyle(
                      fontSize: 18,
                      fontFamily: 'InterExtra',
                      fontWeight: FontWeight.w800,
                      color: CustomColor.primary,
                    ),
                  ),
                  const Spacer(),
                  const Icon(
                    Icons.shopping_cart_outlined,
                    size: 20,
                    color: Colors.black,
                  ),
                  const SizedBox(width: 6),
                  const Icon(
                    Icons.notifications_none,
                    size: 20,
                    color: Colors.black,
                  ),
                ],
              ),
            ),
    );
  }
}
