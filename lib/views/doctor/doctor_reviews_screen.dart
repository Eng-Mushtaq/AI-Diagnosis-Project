import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/doctor_review_controller.dart';
import '../../controllers/auth_controller.dart';
import '../../models/doctor_review_model.dart';
import '../../constants/app_colors.dart';
import '../../widgets/custom_app_bar.dart';
import '../../widgets/loading_indicator.dart';
import '../../widgets/error_message.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/rating_stars.dart';

class DoctorReviewsScreen extends StatefulWidget {
  const DoctorReviewsScreen({Key? key}) : super(key: key);

  @override
  State<DoctorReviewsScreen> createState() => _DoctorReviewsScreenState();
}

class _DoctorReviewsScreenState extends State<DoctorReviewsScreen> {
  final DoctorReviewController _reviewController = Get.find<DoctorReviewController>();
  final AuthController _authController = Get.find<AuthController>();
  
  @override
  void initState() {
    super.initState();
    _loadReviews();
  }
  
  Future<void> _loadReviews() async {
    final currentUser = _authController.currentUser.value;
    if (currentUser != null) {
      await _reviewController.getDoctorReviews(currentUser.id);
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: 'My Reviews',
        showBackButton: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadReviews,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadReviews,
        child: Obx(() {
          if (_reviewController.isLoading) {
            return const LoadingIndicator();
          }
          
          if (_reviewController.errorMessage.isNotEmpty) {
            return ErrorMessage(
              message: _reviewController.errorMessage,
              onRetry: _loadReviews,
            );
          }
          
          final reviews = _reviewController.reviews;
          
          if (reviews.isEmpty) {
            return const EmptyState(
              icon: Icons.star_border,
              title: 'No Reviews Yet',
              message: 'You haven\'t received any reviews yet.',
            );
          }
          
          return SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildReviewSummary(),
                  const SizedBox(height: 24),
                  const Text(
                    'All Reviews',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: reviews.length,
                    itemBuilder: (context, index) {
                      final review = reviews[index];
                      return _buildReviewCard(review);
                    },
                  ),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }
  
  Widget _buildReviewSummary() {
    final averageRating = _reviewController.averageRating;
    final distribution = _reviewController.ratingDistribution;
    final totalReviews = _reviewController.reviews.length;
    
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 5,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    averageRating.toStringAsFixed(1),
                    style: const TextStyle(
                      fontSize: 48,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primaryColor,
                    ),
                  ),
                  RatingStars(
                    rating: averageRating,
                    size: 20,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '$totalReviews ${totalReviews == 1 ? 'review' : 'reviews'}',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 24),
              Expanded(
                child: Column(
                  children: [
                    _buildRatingBar(5, distribution[5] ?? 0, totalReviews),
                    const SizedBox(height: 8),
                    _buildRatingBar(4, distribution[4] ?? 0, totalReviews),
                    const SizedBox(height: 8),
                    _buildRatingBar(3, distribution[3] ?? 0, totalReviews),
                    const SizedBox(height: 8),
                    _buildRatingBar(2, distribution[2] ?? 0, totalReviews),
                    const SizedBox(height: 8),
                    _buildRatingBar(1, distribution[1] ?? 0, totalReviews),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
  
  Widget _buildRatingBar(int rating, int count, int total) {
    final percentage = total > 0 ? count / total : 0.0;
    
    return Row(
      children: [
        Text(
          '$rating',
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Stack(
            children: [
              Container(
                height: 8,
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              FractionallySizedBox(
                widthFactor: percentage,
                child: Container(
                  height: 8,
                  decoration: BoxDecoration(
                    color: _getRatingColor(rating),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        Text(
          count.toString(),
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }
  
  Widget _buildReviewCard(DoctorReviewModel review) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 5,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: AppColors.primaryColor.withOpacity(0.2),
                backgroundImage: review.isAnonymous
                    ? null
                    : (review.patientImage != null && review.patientImage!.isNotEmpty
                        ? NetworkImage(review.patientImage!)
                        : null),
                child: review.isAnonymous ||
                        review.patientImage == null ||
                        review.patientImage!.isEmpty
                    ? Text(
                        review.isAnonymous
                            ? 'A'
                            : (review.patientName?.substring(0, 1).toUpperCase() ?? 'P'),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primaryColor,
                        ),
                      )
                    : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      review.displayName,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    Text(
                      review.formattedDate,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: _getRatingColor(review.rating).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.star,
                      color: _getRatingColor(review.rating),
                      size: 16,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      review.rating.toString(),
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: _getRatingColor(review.rating),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (review.review != null && review.review!.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              review.review!,
              style: const TextStyle(
                fontSize: 14,
              ),
            ),
          ],
          if (review.appointmentDate != null) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(
                  Icons.calendar_today,
                  size: 14,
                  color: Colors.grey[600],
                ),
                const SizedBox(width: 4),
                Text(
                  'Appointment: ${_formatDate(review.appointmentDate!)}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
  
  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
  
  Color _getRatingColor(int rating) {
    switch (rating) {
      case 5:
        return Colors.green;
      case 4:
        return Colors.lightGreen;
      case 3:
        return Colors.amber;
      case 2:
        return Colors.orange;
      case 1:
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
}
