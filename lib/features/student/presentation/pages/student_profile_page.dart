import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import 'package:myprojectflut/core/models/student.dart';

import '../widgets/logout_card.dart';
import '../widgets/profile_header.dart';
import '../widgets/profile_info_card.dart';
import '../widgets/profile_settings_card.dart';

class StudentProfilePage extends StatelessWidget {
  const StudentProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final isDesktop = width >= 900;

    final student = Student(
      id: "1",
      fullName: "Héritier Bamumi",
      matricule: "21007",
      faculty: "Sciences et Technologies",
      department: "Génie Informatique",
      promotion: "L3",
      academicYear: "2025-2026",
      photoUrl: "",
      expiryDate: DateTime(2027, 2, 23),
      paymentValidated: true,
      examAuthorized: true,
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text("Mon profil"),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(
            horizontal: isDesktop ? 80 : 24,
            vertical: 30,
          ),
          child: Column(
            children: [
              ProfileHeader(
                student: student,
              )
                  .animate()
                  .fadeIn()
                  .slideY(begin: .15),

              const SizedBox(height: 24),

              ProfileInfoCard(
                student: student,
              )
                  .animate()
                  .fadeIn(delay: 150.ms)
                  .slideY(begin: .15),

              const SizedBox(height: 24),

              const ProfileSettingsCard()
                  .animate()
                  .fadeIn(delay: 300.ms)
                  .slideY(begin: .15),

              const SizedBox(height: 24),

              const LogoutCard()
                  .animate()
                  .fadeIn(delay: 450.ms)
                  .slideY(begin: .15),
            ],
          ),
        ),
      ),
    );
  }
}