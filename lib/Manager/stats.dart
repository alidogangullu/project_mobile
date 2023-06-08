import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:project_mobile/values.dart';

class ChooseRestaurant extends StatelessWidget {
  ChooseRestaurant({Key? key, required this.userId}) : super(key: key);
  final String userId;
  final FirebaseAuth auth = FirebaseAuth.instance;
  final firestore = FirebaseFirestore.instance;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        iconTheme: const IconThemeData(color: Colors.black),
        backgroundColor: AppColors.white,
        title: const Text('Stats', style: TextStyle(color: Colors.black)),
        elevation: 0,
      ),
      body: FutureBuilder<List<DocumentSnapshot>>(
        future: getRestaurantsForManager(userId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Text('Error: ${snapshot.error}');
          } else {
            final restaurantList = snapshot.data;

            if (restaurantList == null || restaurantList.isEmpty) {
              return const Text('No restaurants found for the manager.');
            }
            return ListView.builder(
              itemCount: restaurantList.length,
              itemBuilder: (context, index) {
                final restaurant = restaurantList[index];

                return ListTile(
                  title: Text(restaurant['name']),
                  subtitle: Text(restaurant['description']),
                  trailing: ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => StatsPage(
                              restaurant: restaurant,
                              restaurantId: restaurant.id),
                        ),
                      );
                    },
                    child: const Text('See Stats'),
                  ),
                );
              },
            );
          }
        },
      ),
    );
  }
}

class StatsPage extends StatelessWidget {
  StatsPage({Key? key, required this.restaurantId, required this.restaurant})
      : super(key: key);
  final String restaurantId;
  final DocumentSnapshot<Object?> restaurant;
  final FirebaseAuth auth = FirebaseAuth.instance;
  final firestore = FirebaseFirestore.instance;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        iconTheme: const IconThemeData(color: Colors.black),
        backgroundColor: AppColors.white,
        title: const Text('Stats', style: TextStyle(color: Colors.black)),
      ),
      body: FutureBuilder<List<QueryDocumentSnapshot>>(
        future: getCompletedOrders(auth.currentUser!.uid),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Text('Error: ${snapshot.error}');
          } else {
            List<QueryDocumentSnapshot> completedOrders = snapshot.data!;
            double totalAmount = 0;
            List<DataRow> rows = [];
            for (int i = 0; i < completedOrders.length; i++) {
              QueryDocumentSnapshot document = completedOrders[i];
              final totalPrice = document['totalPrice'];
              totalAmount += totalPrice;

              DataRow row = DataRow(
                cells: [
                  DataCell(Text('#${i + 1}')),
                  DataCell(Text(totalPrice.toString())),
                ],
              );
              rows.add(row);
            }
            DataRow totalRow = DataRow(
              cells: [
                const DataCell(
                  Text(
                    'Total Amount',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                DataCell(
                  Text(
                    totalAmount.toString(),
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            );
            rows.add(totalRow);
            return OrderStats(
                rows: rows, restaurantId: restaurantId, restaurant: restaurant);
          }
        },
      ),
    );
  }
}

class OrderStats extends StatelessWidget {
  const OrderStats({
    super.key,
    required this.rows,
    required this.restaurantId,
    required this.restaurant,
  });

  final List<DataRow> rows;
  final String restaurantId;
  final DocumentSnapshot<Object?> restaurant;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        return SingleChildScrollView(
          scrollDirection: Axis.vertical,
          child: SizedBox(
            width: constraints.maxWidth,
            child: Column(
              children: [
                buildDataTable(constraints, rows),
                const SizedBox(width: 50, height: 20),
                buildRevenueWidget(constraints, restaurant),
                const SizedBox(width: 50, height: 20),
                buildRatedWidgets(constraints, restaurant),
                const SizedBox(width: 50, height: 20),
              ],
            ),
          ),
        );
      },
    );
  }
}

Widget buildRatedWidgets(
    BoxConstraints constraints, DocumentSnapshot<Object?> restaurant) {
  return SizedBox(
    width: constraints.maxWidth - 50,
    child: Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        MostRatedDrink(restaurant: restaurant),
        const Divider(indent: 10),
        MostRatedFood(restaurant: restaurant),
      ],
    ),
  );
}

Widget buildRevenueWidget(
    BoxConstraints constraints, DocumentSnapshot<Object?> restaurant) {
  return SizedBox(
    width: constraints.maxWidth - 50,
    child: Revenue(restaurant: restaurant),
  );
}

Widget buildDataTable(BoxConstraints constraints, List<DataRow> rows) {
  return SizedBox(
    width: constraints.maxWidth,
    child: DataTable(
      columns: const <DataColumn>[
        DataColumn(
          label: Text(
            'Order',
            style: TextStyle(fontSize: 19.0),
          ),
        ),
        DataColumn(
          label: Text(
            'Price paid',
            style: TextStyle(fontSize: 19.0),
          ),
        ),
      ],
      rows: rows,
      headingRowColor: MaterialStateColor.resolveWith(
          (states) => AppColors.color600), //heading color
      headingTextStyle: const TextStyle(fontWeight: FontWeight.bold),
      dividerThickness: 2,
      columnSpacing: 16,
      horizontalMargin: 16,
      decoration: const BoxDecoration(
        color: AppColors.color200, //cell color
      ),
      dataTextStyle: const TextStyle(fontSize: 16),
      showBottomBorder: true, // Show or hide the bottom border of the table
      showCheckboxColumn: false, // Show or hide the checkbox column
    ),
  );
}

class MostRatedDrink extends StatelessWidget {
  const MostRatedDrink({Key? key, required this.restaurant}) : super(key: key);

  final DocumentSnapshot<Object?> restaurant;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: AppColors.color300,
        borderRadius: BorderRadius.circular(8.0),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            spreadRadius: 2,
            blurRadius: 5,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Most Rated Drink',
            style: TextStyle(
                fontSize: 16.0,
                fontWeight: FontWeight.bold,
                color: AppColors.color900),
          ),
          const SizedBox(height: 8.0),
          FutureBuilder(
            future: getMostRatedDrink(restaurant.id),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              } else if (snapshot.hasError) {
                return Text('Error: ${snapshot.error}');
              } else {
                final drinkDoc = snapshot.data!.docs.first;
                final drinkName = drinkDoc.get('name');
                final drinkRating = drinkDoc.get('rating');

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Name: $drinkName',
                      style: const TextStyle(
                          fontSize: 16.0, color: AppColors.white),
                    ),
                    Text(
                      'Rating: $drinkRating',
                      style: const TextStyle(
                          fontSize: 16.0, color: AppColors.white),
                    ),
                  ],
                );
              }
            },
          ),
        ],
      ),
    );
  }
}

class MostRatedFood extends StatelessWidget {
  const MostRatedFood({Key? key, required this.restaurant}) : super(key: key);

  final DocumentSnapshot<Object?> restaurant;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: AppColors.color300,
        borderRadius: BorderRadius.circular(8.0),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            spreadRadius: 2,
            blurRadius: 5,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Most Rated Food',
            style: TextStyle(
                fontSize: 16.0,
                fontWeight: FontWeight.bold,
                color: AppColors.color900),
          ),
          const SizedBox(height: 8.0),
          FutureBuilder(
            future: getMostRatedFood(restaurant.id),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              } else if (snapshot.hasError) {
                return Text('Error: ${snapshot.error}');
              } else {
                final foodDoc = snapshot.data!.docs.first;
                final foodName = foodDoc.get('name');
                final foodRating = foodDoc.get('rating');

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Name: $foodName',
                      style: const TextStyle(
                          fontSize: 16.0, color: AppColors.white),
                    ),
                    Text(
                      'Rating: $foodRating',
                      style: const TextStyle(
                          fontSize: 16.0, color: AppColors.white),
                    ),
                  ],
                );
              }
            },
          ),
        ],
      ),
    );
  }
}

class Revenue extends StatelessWidget {
  const Revenue({super.key, required this.restaurant});
  final DocumentSnapshot<Object?> restaurant;

  @override
  Widget build(BuildContext context) {
    final totalSales = restaurant['totalSales'];
    const year = '2023';
    const month = '05';
    final daySales = totalSales[year][month];

    final List<FlSpot> chartData = [];

    String salesContent = '';
    daySales.forEach((day, sales) {
      salesContent += 'Day $day: $sales\n';
      double salesAmount = sales.toDouble();
      final dayIndex = double.tryParse(day);
      chartData.add(FlSpot(dayIndex!, salesAmount));
    });

    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: AppColors.color300,
        borderRadius: BorderRadius.circular(8.0),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            spreadRadius: 2,
            blurRadius: 5,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Total sales for $year/$month',
            style: TextStyle(
                fontSize: 19.0,
                fontWeight: FontWeight.bold,
                color: AppColors.color900),
          ),
          const SizedBox(height: 8),
          Text(
            salesContent,
            style: const TextStyle(
              fontSize: 17,
              color: AppColors.white,
            ),
          ),
          const SizedBox(height: 25),
          AspectRatio(
            aspectRatio: 1,
            child: LineChart(
              sampleData(chartData),
              swapAnimationDuration: const Duration(milliseconds: 250),
            ),
          ),
        ],
      ),
    );
  }

  LineChartData sampleData(List<FlSpot> chartData) => LineChartData(
        lineTouchData: lineTouchData1,
        gridData: gridData,
        titlesData: titlesData1,
        borderData: borderData,
        lineBarsData: lineBarsData1(chartData),
        minX: 1,
        maxX: 31,
        maxY: 600,
        minY: 0,
      );

  LineTouchData get lineTouchData1 => LineTouchData(
        handleBuiltInTouches: true,
        touchTooltipData: LineTouchTooltipData(
          tooltipBgColor: Colors.blueGrey.withOpacity(0.8),
        ),
      );
  FlGridData get gridData => FlGridData(show: false);
  FlTitlesData get titlesData1 => FlTitlesData(
        bottomTitles: AxisTitles(
          sideTitles: bottomTitles(),
        ),
        rightTitles: AxisTitles(
          sideTitles: SideTitles(showTitles: false),
        ),
        topTitles: AxisTitles(
          sideTitles: SideTitles(showTitles: false),
        ),
        leftTitles: AxisTitles(
          sideTitles: leftTitles(),
        ),
      );
  FlBorderData get borderData => FlBorderData(
        show: true,
        border: Border(
          bottom:
              BorderSide(color: AppColors.color50.withOpacity(0.2), width: 4),
          left: const BorderSide(color: Colors.transparent),
          right: const BorderSide(color: Colors.transparent),
          top: const BorderSide(color: Colors.transparent),
        ),
      );
  List<LineChartBarData> lineBarsData1(List<FlSpot> chartData) => [
        lineChartBarData(chartData),
      ];
  SideTitles bottomTitles() => SideTitles(
        showTitles: true,
        reservedSize: 32,
        interval: 1,
        getTitlesWidget: bottomTitleWidgets,
      );
  SideTitles leftTitles() => SideTitles(
        getTitlesWidget: leftTitleWidgets,
        showTitles: true,
        interval: 1,
        reservedSize: 40,
      );
  Widget leftTitleWidgets(double value, TitleMeta meta) {
    const style = TextStyle(
      fontWeight: FontWeight.bold,
      fontSize: 14,
    );
    String text;
    switch (value.toInt()) {
      case 0:
        text = '0';
        break;
      case 500:
        text = '500';
        break;
      case 1000:
        text = '1000';
        break;
      default:
        return Container();
    }

    return Text(text, style: style, textAlign: TextAlign.center);
  }

  Widget bottomTitleWidgets(double value, TitleMeta meta) {
    const style = TextStyle(
      fontWeight: FontWeight.bold,
      fontSize: 16,
    );
    int day = value.toInt();
    if (day == 1 || day == 7 || day == 14 || day == 21 || day == 31) {
      return Text(day.toString(), style: style);
    } else {
      return const SizedBox();
    }
  }

  LineChartBarData lineChartBarData(List<FlSpot> chartData) =>
      LineChartBarData(
        isCurved: true,
        color: AppColors.color100,
        barWidth: 2,
        isStrokeCapRound: true,
        dotData: FlDotData(show: true),
        belowBarData: BarAreaData(show: false),
        spots: chartData,
      );
}

Future<List<QueryDocumentSnapshot>> getCompletedOrders(String userId) async {
  final FirebaseFirestore firestore = FirebaseFirestore.instance;
  QuerySnapshot querySnapshot = await firestore
      .collection('users')
      .doc(userId)
      .collection('completedOrders')
      .get();

  return querySnapshot.docs;
}

Future<QuerySnapshot<Object?>> getMostRatedDrink(String restaurant) async {
  final FirebaseFirestore firestore = FirebaseFirestore.instance;
  QuerySnapshot querySnapshot = await firestore
      .collection('Restaurants')
      .doc(restaurant)
      .collection('MenuCategory')
      .doc('Drinks')
      .collection('list')
      .orderBy('rating', descending: true)
      .limit(1)
      .get();

  return querySnapshot;
}

Future<QuerySnapshot<Object?>> getMostRatedFood(String restaurant) async {
  final FirebaseFirestore firestore = FirebaseFirestore.instance;
  QuerySnapshot querySnapshot = await firestore
      .collection('Restaurants')
      .doc(restaurant)
      .collection('MenuCategory')
      .doc('Foods')
      .collection('list')
      .orderBy('rating', descending: true)
      .limit(1)
      .get();

  return querySnapshot;
}

Future<List<DocumentSnapshot>> getRestaurantsForManager(String userId) async {
  final FirebaseFirestore firestore = FirebaseFirestore.instance;
  QuerySnapshot querySnapshot = await firestore.collection('Restaurants').get();

  return querySnapshot.docs;
}
