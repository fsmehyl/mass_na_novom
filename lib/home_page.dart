import 'package:flutter/material.dart';
import 'fill_form_three.dart';
import 'fill_form_two.dart';
import 'fill_form_one.dart';
import 'create_own_form.dart';
import 'upload_own_form.dart';

class MyHomePage extends StatelessWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 20),
                Image.asset(
                  'assets/Flutter_logo.png',
                  height: 200,
                ),
                const SizedBox(height: 20),
                Text(
                  'Vítajte v aplikácií M.A.S.S.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[800],
                  ),
                ),
                const SizedBox(height: 10),
                const Text(
                  'Vyberte si prosím jednu z možností',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 30),
                // Prvá karta
                _buildCard(
                  title: 'Rôzne prípady detí do 10 rokov',
                  description: 'Fomulár s použitím package',
                  icon: Icons.article_outlined,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const FillFormThree(),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 20),
                _buildCard(
                  title: 'Ukážkový fomulár',
                  description: 'Možnosti využitia rôznych typov otázok',
                  icon: Icons.analytics_outlined,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => FillFormOne(),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 20),
                _buildCard(
                  title: 'Rôzne prípady detí do 5 rokov',
                  description: 'Fomulár bez použitia package',
                  icon: Icons.grading,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => FillFormTwo(),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 30),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blueAccent,
                    padding: const EdgeInsets.symmetric(
                        vertical: 15, horizontal: 30),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  icon: const Icon(
                    Icons.add,
                    color: Color.fromARGB(255, 255, 255, 255),
                  ),
                  label: const Text(
                    'Vytvoriť vlastný formulár',
                    style: TextStyle(fontSize: 16, color: Color.fromARGB(255, 255, 255, 255)),
                  ),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => CreateFormPage(),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 10),
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                        vertical: 15, horizontal: 30),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    side: const BorderSide(color: Colors.blueAccent),
                  ),
                  icon: const Icon(Icons.upload),
                  label: const Text(
                    'Nahrať formulár',
                    style: TextStyle(fontSize: 16, color: Colors.blueAccent),
                  ),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => UploadAndGenerateFormPage(),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 30),
                const Text(
                  'Poháňané nástrojom Flutter',
                  style: TextStyle(
                    color: Colors.grey,
                    fontSize: 12,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCard({
    required String title,
    required String description,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.2),
              blurRadius: 10,
              spreadRadius: 5,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 30,
              backgroundColor: Colors.blueAccent.withOpacity(0.2),
              child: Icon(
                icon,
                size: 30,
                color: Colors.blueAccent,
              ),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    description,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
