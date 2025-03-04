import 'package:flutter/material.dart';
import 'package:flutter_app/car_widget.dart';
import 'package:flutter_app/constants.dart';
import 'package:flutter_app/seller/data.dart';
import 'package:flutter_app/user/book_car.dart';

class AvailableCars extends StatefulWidget {
  const AvailableCars({super.key});

  @override
  _AvailableCarsState createState() => _AvailableCarsState();
}

class _AvailableCarsState extends State<AvailableCars> {
  List<Filter> filters = getFilterList();
  late Filter selectedFilter;
  late List<Car> cars;

  @override
  void initState() {
    super.initState();
    selectedFilter = filters[0];
    cars = getCarList();
  }

  @override
  Widget build(BuildContext context) {
    double aspectRatio = MediaQuery.of(context).size.width /
        (MediaQuery.of(context).size.height / 1.5);

    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  width: 60,
                  height: 55,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(15),
                    border: Border.all(color: Colors.grey.shade300, width: 1),
                  ),
                  child: Icon(Icons.keyboard_arrow_left,
                      color: Colors.black, size: 28),
                ),
              ),
              SizedBox(height: 16),
              Text(
                "Available Cars (${cars.length})",
                style: TextStyle(
                  color: Colors.black,
                  fontSize: 32, // Slightly smaller font for better layout
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 16),
              Expanded(
                child: GridView.builder(
                  physics: BouncingScrollPhysics(),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                    childAspectRatio:
                        aspectRatio * 0.9, // Adjusted for better spacing
                  ),
                  itemCount: cars.length,
                  itemBuilder: (context, index) {
                    return GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => BookCar(car: cars[index])),
                        );
                      },
                      child: buildCar(cars[index], 0),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: Container(
        height: 90,
        decoration: BoxDecoration(color: Colors.white),
        child: Row(
          children: [
            buildFilterIcon(),
            Expanded(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(children: buildFilters()),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget buildFilterIcon() {
    return Container(
      width: 50,
      height: 50,
      margin: EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: kPrimaryColor,
        borderRadius: BorderRadius.circular(15),
      ),
      child: Center(
        child: Icon(Icons.filter_list, color: Colors.white, size: 24),
      ),
    );
  }

  List<Widget> buildFilters() {
    return filters.map((filter) => buildFilter(filter)).toList();
  }

  Widget buildFilter(Filter filter) {
    return GestureDetector(
      onTap: () {
        setState(() {
          selectedFilter = filter;
        });
      },
      child: Padding(
        padding: EdgeInsets.only(right: 16),
        child: Text(
          filter.name,
          style: TextStyle(
            color: selectedFilter == filter ? kPrimaryColor : Colors.grey[400],
            fontSize: 16,
            fontWeight:
                selectedFilter == filter ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}
