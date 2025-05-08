import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../constants/app_colors.dart';
import '../models/doctor_model.dart';

// Doctor card widget for displaying doctor information
class DoctorCard extends StatelessWidget {
  final DoctorModel doctor;
  final VoidCallback onTap;
  final bool isDetailed;

  const DoctorCard({
    super.key,
    required this.doctor,
    required this.onTap,
    this.isDetailed = false,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: isDetailed ? _buildDetailedCard() : _buildCompactCard(),
        ),
      ),
    );
  }

  Widget _buildCompactCard() {
    return Row(
      children: [
        _buildDoctorAvatar(),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                doctor.name,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Text(
                doctor.specialization,
                style: TextStyle(color: Colors.grey[600], fontSize: 14),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  _buildRatingIndicator(),
                  const SizedBox(width: 16),
                  Icon(Icons.business, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      doctor.hospital,
                      style: TextStyle(color: Colors.grey[600], fontSize: 12),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              _buildVerificationStatus(),
            ],
          ),
        ),
        SizedBox(
          width: 100, // Fixed width for the right column
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                doctor.formattedConsultationFee,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: AppColors.primaryColor,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Text(
                '${doctor.experience} yrs exp',
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (doctor.isAvailableForVideo)
                    const Icon(
                      Icons.videocam,
                      color: AppColors.secondaryColor,
                      size: 18,
                    ),
                  if (doctor.isAvailableForVideo && doctor.isAvailableForChat)
                    const SizedBox(width: 4),
                  if (doctor.isAvailableForChat)
                    const Icon(
                      Icons.chat,
                      color: AppColors.accentColor,
                      size: 18,
                    ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDetailedCard() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            _buildDoctorAvatar(radius: 40),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    doctor.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    doctor.specialization,
                    style: const TextStyle(
                      color: AppColors.primaryColor,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  _buildRatingIndicator(),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        const Divider(),
        const SizedBox(height: 8),
        _buildInfoRow(Icons.business, 'Hospital', doctor.hospital),
        const SizedBox(height: 8),
        _buildInfoRow(Icons.location_on, 'Location', doctor.city),
        const SizedBox(height: 8),
        _buildInfoRow(Icons.work, 'Experience', '${doctor.experience} years'),
        const SizedBox(height: 8),
        _buildInfoRow(
          Icons.attach_money,
          'Consultation Fee',
          doctor.formattedConsultationFee,
        ),
        const SizedBox(height: 8),
        _buildInfoRow(
          _getVerificationIcon(),
          'Verification Status',
          _getVerificationText(),
          textColor: _getVerificationColor(),
        ),
        const SizedBox(height: 16),
        if (doctor.about != null && doctor.about!.isNotEmpty) ...[
          const Text(
            'About',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 8),
          Text(
            doctor.about!,
            style: TextStyle(color: Colors.grey[700], fontSize: 14),
          ),
          const SizedBox(height: 16),
        ],
        Row(
          children: [
            Expanded(
              child: _buildAvailabilityChip(
                'Video Consultation',
                Icons.videocam,
                doctor.isAvailableForVideo,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildAvailabilityChip(
                'Chat Consultation',
                Icons.chat,
                doctor.isAvailableForChat,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDoctorAvatar({double radius = 30}) {
    return CircleAvatar(
      radius: radius,
      backgroundColor: Colors.grey[200],
      child: ClipOval(
        child: CachedNetworkImage(
          imageUrl: doctor.profileImage,
          width: radius * 2,
          height: radius * 2,
          fit: BoxFit.cover,
          placeholder: (context, url) => const CircularProgressIndicator(),
          errorWidget:
              (context, url, error) =>
                  Icon(Icons.person, size: radius, color: Colors.grey[400]),
        ),
      ),
    );
  }

  Widget _buildRatingIndicator() {
    return Row(
      children: [
        const Icon(Icons.star, color: Colors.amber, size: 16),
        const SizedBox(width: 4),
        Text(
          doctor.formattedRating,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
        ),
      ],
    );
  }

  Widget _buildInfoRow(
    IconData icon,
    String label,
    String value, {
    Color? textColor,
  }) {
    return Row(
      children: [
        Icon(icon, size: 18, color: textColor ?? AppColors.secondaryColor),
        const SizedBox(width: 8),
        Text(
          '$label:',
          style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              color: textColor ?? Colors.grey[700],
              fontSize: 14,
              fontWeight:
                  textColor != null ? FontWeight.w500 : FontWeight.normal,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  // Helper methods for verification status
  IconData _getVerificationIcon() {
    switch (doctor.verificationStatus.toLowerCase()) {
      case 'approved':
        return Icons.verified;
      case 'rejected':
        return Icons.cancel;
      case 'pending':
      default:
        return Icons.pending;
    }
  }

  String _getVerificationText() {
    return doctor.formattedVerificationStatus;
  }

  Color _getVerificationColor() {
    switch (doctor.verificationStatus.toLowerCase()) {
      case 'approved':
        return Colors.green;
      case 'rejected':
        return Colors.red;
      case 'pending':
      default:
        return Colors.orange;
    }
  }

  Widget _buildAvailabilityChip(String label, IconData icon, bool isAvailable) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      decoration: BoxDecoration(
        color:
            isAvailable
                ? AppColors.successColor.withValues(alpha: 0.1)
                : Colors.grey.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isAvailable ? AppColors.successColor : Colors.grey,
          width: 1,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: 16,
            color: isAvailable ? AppColors.successColor : Colors.grey,
          ),
          const SizedBox(width: 4),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: isAvailable ? AppColors.successColor : Colors.grey,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVerificationStatus() {
    // Define colors and icons based on verification status
    Color statusColor;
    IconData statusIcon;
    String statusText;

    switch (doctor.verificationStatus.toLowerCase()) {
      case 'approved':
        statusColor = Colors.green;
        statusIcon = Icons.verified;
        statusText = 'Verified';
        break;
      case 'rejected':
        statusColor = Colors.red;
        statusIcon = Icons.cancel;
        statusText = 'Rejected';
        break;
      case 'pending':
      default:
        statusColor = Colors.orange;
        statusIcon = Icons.pending;
        statusText = 'Pending Verification';
        break;
    }

    return Row(
      children: [
        Icon(statusIcon, size: 14, color: statusColor),
        const SizedBox(width: 4),
        Text(
          statusText,
          style: TextStyle(
            color: statusColor,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
