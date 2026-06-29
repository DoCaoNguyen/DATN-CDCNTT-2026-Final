import 'package:flutter/material.dart';
import 'tabs/buy_card_tab.dart';
import 'tabs/phone_topup_tab.dart';
import 'tabs/data_topup_tab.dart';

class TopupMainScreen extends StatelessWidget {
  final String token;

  const TopupMainScreen({Key? key, required this.token}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: const Color(0xFFF5F5F9),
        appBar: AppBar(
          backgroundColor: const Color(0xFFFFE4EE),
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.black),
            onPressed: () => Navigator.pop(context),
          ),
          title: const Text(
            'Điện thoại - Data 4G/5G',
            style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.star_border, color: Colors.black),
              onPressed: () {},
            ),
            IconButton(
              icon: const Icon(Icons.headset_mic_outlined, color: Colors.black),
              onPressed: () {},
            ),
          ],
          bottom: const TabBar(
            labelColor: Colors.pink,
            unselectedLabelColor: Colors.grey,
            indicatorColor: Colors.pink,
            indicatorWeight: 3,
            labelStyle: TextStyle(fontWeight: FontWeight.bold),
            tabs: [
              Tab(text: 'Mã thẻ'),
              Tab(text: 'Nạp điện thoại'),
              Tab(text: 'Nạp data'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            BuyCardTab(token: token),
            PhoneTopupTab(token: token),
            DataTopupTab(token: token),
          ],
        ),
      ),
    );
  }
}
