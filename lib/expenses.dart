import 'package:flutter/material.dart';

class ExpensesScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFF1F8F6),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(
          "Expenses",
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black),
        ),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildExpenseForm(),
            SizedBox(height: 20),
            Text(
              "Expense History",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10),
            _buildExpenseHistory(),
          ],
        ),
      ),
    );
  }

  Widget _buildExpenseForm() {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Submit New Expense",
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: TextField(
                  decoration: InputDecoration(
                    labelText: "Amount (₹)",
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                ),
              ),
              SizedBox(width: 10),
              Expanded(
                child: TextField(
                  decoration: InputDecoration(
                    labelText: "Category",
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 10),
          TextField(
            decoration: InputDecoration(
              labelText: "Description",
              border: OutlineInputBorder(),
            ),
            maxLines: 2,
          ),
          SizedBox(height: 10),
          Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.upload_file, color: Colors.grey),
                SizedBox(width: 10),
                Text("Click to upload receipt"),
              ],
            ),
          ),
          SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.teal),
              onPressed: () {},
              child: Text("Submit Expense"),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExpenseHistory() {
    return Column(
      children: [
        _expenseItem("Travel", "15 Jun 2023 • ₹1,250", "Approved"),
        _expenseItem("Equipment", "02 Jun 2023 • ₹3,500", "Approved"),
      ],
    );
  }

  Widget _expenseItem(String title, String date, String status) {
    return Container(
      margin: EdgeInsets.only(bottom: 10),
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(Icons.receipt_long, color: Colors.teal),
              SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: TextStyle(fontWeight: FontWeight.bold)),
                  Text(date, style: TextStyle(color: Colors.grey)),
                ],
              ),
            ],
          ),
          Container(
            padding: EdgeInsets.symmetric(vertical: 4, horizontal: 8),
            decoration: BoxDecoration(
              color: Colors.green.shade100,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              status,
              style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
}
