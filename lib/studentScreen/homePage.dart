import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';
import 'package:dnsc_events/colors/color.dart';
import 'package:shimmer/shimmer.dart';
import 'package:dnsc_events/widget/calendar.dart';
import 'package:dnsc_events/widget/appbar.dart';

class Homepage extends StatefulWidget {
  const Homepage({super.key});

  @override
  State<Homepage> createState() => _HomepageState();
}

class _HomepageState extends State<Homepage> {
  final List<String> images = [
    'assets/image/backgroundLogin.jpg',
    'assets/image/example.png',
    'assets/image/backgroundLogin.jpg',
    'assets/image/example.png',
  ];

  bool isLoading = true;

  @override
  void initState() {
    super.initState();

    Future.delayed(const Duration(seconds: 2), () {
      setState(() => isLoading = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: CustomColor.background,

      appBar: Appbar(isLoading: isLoading),

      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Column(
            children: [
              isLoading
                  ? Shimmer.fromColors(
                      baseColor: Colors.grey.shade300,
                      highlightColor: Colors.white,
                      child: Row(
                        children: [
                          Container(
                            height: 26,
                            width: 180,
                            color: Colors.grey.shade300,
                          ),
                        ],
                      ),
                    )
                  : Row(
                      children: [
                        Text(
                          "Welcome ",
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontFamily: 'InterExtra',
                            fontSize: 24,
                          ),
                        ),
                        Text(
                          "Back",
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontFamily: 'InterExtra',
                            fontSize: 24,
                            color: CustomColor.primary,
                          ),
                        ),
                        Text(
                          "!",
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontFamily: 'InterExtra',
                            fontSize: 24,
                          ),
                        ),
                      ],
                    ),

              SizedBox(height: 10),

              isLoading
                  ? Shimmer.fromColors(
                      baseColor: Colors.grey.shade300,
                      highlightColor: Colors.white,
                      child: _shimmerStatsLayout(),
                    )
                  : realStatsLayout(),
              const SizedBox(height: 10),

              isLoading
                  ? Shimmer.fromColors(
                      baseColor: Colors.grey.shade300,
                      highlightColor: Colors.white,
                      child: Row(
                        children: [
                          Container(
                            height: 16,
                            width: 130,
                            color: Colors.grey.shade300,
                          ),

                          Spacer(),
                          Container(
                            height: 16,
                            width: 80,
                            color: Colors.grey.shade300,
                          ),
                          const SizedBox(height: 10),
                        ],
                      ),
                    )
                  : Row(
                      children: [
                        Text(
                          "Upcoming",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          " Events",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: CustomColor.primary,
                          ),
                        ),
                        Spacer(),
                        Text("View all", style: TextStyle(fontSize: 12)),
                        Icon(
                          Icons.chevron_right_outlined,
                          color: CustomColor.primary,
                          size: 20,
                        ),
                      ],
                    ),
              SizedBox(height: 10),
              isLoading
                  ? Shimmer.fromColors(
                      baseColor: Colors.grey.shade300,
                      highlightColor: Colors.white,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: List.generate(4, (index) {
                          return Container(
                            height: 150,
                            width:
                                MediaQuery.of(context).size.width *
                                0.4, // approximate width
                            margin: EdgeInsets.symmetric(horizontal: 3),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade300,
                              borderRadius: BorderRadius.circular(12),
                            ),
                          );
                        }),
                      ),
                    )
                  : CarouselSlider.builder(
                      itemCount: images.length,
                      itemBuilder: (context, index, realIndex) {
                        return Container(
                          margin: EdgeInsets.symmetric(horizontal: 3),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            image: DecorationImage(
                              image: AssetImage(images[index]),
                              fit: BoxFit.cover,
                            ),
                          ),
                        );
                      },
                      options: CarouselOptions(
                        height: 150,
                        viewportFraction: 0.40,
                        autoPlay: true,
                        autoPlayInterval: Duration(seconds: 5),
                        autoPlayAnimationDuration: Duration(seconds: 5),
                        enableInfiniteScroll: true,
                      ),
                    ),
              SizedBox(height: 10),

              isLoading
                  ? Align(
                      alignment: Alignment.centerLeft,
                      child: Shimmer.fromColors(
                        baseColor: Colors.grey.shade300,
                        highlightColor: Colors.white,

                        child: Container(
                          width: 150,
                          height: 18,
                          color: Colors.grey.shade300,
                        ),
                      ),
                    )
                  : Row(
                      children: [
                        Text(
                          "Event ",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          "Calendar",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: CustomColor.primary,
                          ),
                        ),
                      ],
                    ),

              SizedBox(height: 10),

              const Calendar(),
            ],
          ),
        ),
      ),
    );
  }
}

Widget _shimmerStatsLayout() {
  return Wrap(
    spacing: 10,
    runSpacing: 10,
    children: List.generate(4, (_) {
      return Container(
        height: 90,
        width: 165,
        decoration: BoxDecoration(
          color: Colors.grey.shade300,
          borderRadius: BorderRadius.circular(12),
        ),
      );
    }),
  );
}

Widget realStatsLayout() {
  return Wrap(
    spacing: 10,
    runSpacing: 10,
    children: [
      //upper-left
      Container(
        height: 90,
        width: 165,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(width: 1, color: CustomColor.borderGray),
          color: Colors.white,
        ),
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Ticket Purchases",
                style: TextStyle(fontSize: 13, color: CustomColor.subtextColor),
              ),
              Spacer(),

              Image.asset('assets/icon/ticketIcon.png'),
            ],
          ),
        ),
      ),
      //upper-right
      Container(
        height: 90,
        width: 165,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(width: 1, color: CustomColor.borderGray),
          color: Colors.white,
        ),
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Total Spent",
                style: TextStyle(fontSize: 13, color: CustomColor.subtextColor),
              ),
              Spacer(),

              Image.asset('assets/icon/cash.png'),
            ],
          ),
        ),
      ),

      //bottom-left
      Container(
        height: 90,
        width: 165,

        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(width: 1, color: CustomColor.borderGray),
          color: Colors.white,
        ),
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Events Attended",
                style: TextStyle(fontSize: 13, color: CustomColor.subtextColor),
              ),
              Spacer(),

              Image.asset('assets/icon/dollarCoin.png'),
            ],
          ),
        ),
      ),

      //bottom-right
      Container(
        height: 90,
        width: 165,

        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(width: 1, color: CustomColor.borderGray),
          color: Colors.white,
        ),
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Pending Payments",
                    style: TextStyle(
                      fontSize: 13,
                      color: CustomColor.subtextColor,
                    ),
                  ),
                  Spacer(),

                  Image.asset('assets/icon/shield.png'),
                ],
              ),
              SizedBox(height: 6),
              Text(
                "2",
                style: TextStyle(
                  fontSize: 24,
                  fontFamily: 'InterExtra',
                  fontWeight: FontWeight.w800,
                  color: CustomColor.green,
                ),
              ),
            ],
          ),
        ),
      ),
    ],
  );
}
