import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../../../config/theme/app_theme.dart';
import '../../../auth/domain/entities/user_entity.dart';

class StudentQrPage extends StatelessWidget {
  final UserEntity student;

  const StudentQrPage({super.key, required this.student});

  @override
  Widget build(BuildContext context) {
    // Determine the secondary info block, typically ID and Email
    final List<String> secondaryInfo = [
      if (student.studentId != null && student.studentId!.isNotEmpty)
        'ID: ${student.studentId}'
      else if (student.id.isNotEmpty)
        'ID: ${student.id}',
      if (student.email != null && student.email!.isNotEmpty)
        student.email!
      else if (student.phone != null && student.phone!.isNotEmpty)
        student.phone!,
    ];

    // Build the payload for the QR code in MECARD format
    // This allows native phone cameras to parse it properly as a contact/identity card
    final String qrData =
        [
          'MECARD:N:${student.name}',
          if (student.college != null && student.college!.isNotEmpty)
            'ORG:${student.college}',
          if (student.email != null && student.email!.isNotEmpty)
            'EMAIL:${student.email}',
          if (student.phone != null && student.phone!.isNotEmpty)
            'TEL:${student.phone}',
          'NOTE:Student ID: ${student.studentId ?? (student.id.isNotEmpty ? student.id : "N/A")}',
          ';', // MECARD ends with double semicolon (the items are joined by ;, and the string ends with ;)
        ].join(';') +
        ';';

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new,
            color: Colors.black,
            size: 20,
          ),
          onPressed: () => context.pop(),
        ),
        title: Text(
          student.name,
          style: const TextStyle(
            color: Colors.black,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 24.0),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 32),

                // Avatar
                ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: student.avatar != null
                      ? Image.network(
                          student.avatar!,
                          width: 80,
                          height: 80,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) =>
                              _buildFallbackAvatar(),
                        )
                      : _buildFallbackAvatar(),
                ),

                const SizedBox(height: 16),

                // Name
                Text(
                  student.name,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.darkCharcoal,
                  ),
                ),

                const SizedBox(height: 4),

                // ID and details
                if (secondaryInfo.isNotEmpty)
                  Column(
                    children: secondaryInfo
                        .map(
                          (info) => Padding(
                            padding: const EdgeInsets.only(bottom: 4.0),
                            child: Text(
                              info,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey.shade700,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        )
                        .toList(),
                  ),

                const SizedBox(height: 24),
                Divider(height: 1, thickness: 1, color: Colors.grey.shade200),
                const SizedBox(height: 32),

                // QR Code
                Center(
                  child: QrImageView(
                    data: qrData,
                    version: QrVersions.auto,
                    size: 240.0,
                    foregroundColor: Colors.black,
                  ),
                ),

                const SizedBox(height: 24),

                // Instructions Text
                Text(
                  'Show this QR code to the bus\nattendant during boarding',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade700,
                    height: 1.5,
                  ),
                ),

                const SizedBox(height: 32),

                // Action Buttons
                // Padding(
                //   padding: const EdgeInsets.symmetric(horizontal: 24.0),
                //   child: Row(
                //     children: [
                //       Expanded(
                //         child: _buildActionButton(
                //           icon: Icons.download_rounded,
                //           label: 'Save',
                //           onTap: () {
                //             // Empty callback for UI placeholder
                //           },
                //         ),
                //       ),
                //       const SizedBox(width: 16),
                //       Expanded(
                //         child: _buildActionButton(
                //           icon: Icons.share_rounded,
                //           label: 'Share',
                //           onTap: () {
                //             // Empty callback for UI placeholder
                //           },
                //         ),
                //       ),
                //     ],
                //   ),
                // ),

                // const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFallbackAvatar() {
    return Container(
      width: 80,
      height: 80,
      color: Colors.grey.shade200,
      child: const Icon(Icons.person, size: 40, color: Colors.grey),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return Container(
      height: 48,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.brightOrange, width: 1.5),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: AppColors.brightOrange, size: 20),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(
                color: AppColors.brightOrange,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
