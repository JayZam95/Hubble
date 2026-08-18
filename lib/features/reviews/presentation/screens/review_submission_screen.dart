import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../providers/review_provider.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

class ReviewSubmissionScreen extends ConsumerStatefulWidget {
  final String revieweeId;
  final String revieweeName;
  final String jobId;

  const ReviewSubmissionScreen({
    super.key,
    required this.revieweeId,
    required this.revieweeName,
    required this.jobId,
  });

  @override
  ConsumerState<ReviewSubmissionScreen> createState() => _ReviewSubmissionScreenState();
}

class _ReviewSubmissionScreenState extends ConsumerState<ReviewSubmissionScreen> {
  int _selectedRating = 0;
  final TextEditingController _commentController = TextEditingController();
  bool _isProcessing = false;
  String _errorMessage = '';
  bool _showSuccess = false;

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _submitReview() async {
    if (_selectedRating == 0) return;

    setState(() {
      _isProcessing = true;
      _errorMessage = '';
    });

    try {
      final authState = ref.read(authStateProvider);
      final clientId = authState.user?.uid ?? '';
      if (clientId.isEmpty) throw Exception('User not logged in');

      final repository = ref.read(reviewRepositoryProvider);
      await repository.submitReview(
        bookingId: widget.jobId,
        reviewerId: clientId,
        revieweeId: widget.revieweeId,
        rating: _selectedRating.toDouble(),
        comment: _commentController.text,
      );

      setState(() {
        _showSuccess = true;
      });

      await Future.delayed(const Duration(milliseconds: 1500));
      if (mounted) {
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      setState(() {
        _errorMessage = e.toString().replaceAll('Exception: ', '');
        _isProcessing = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Submit Review'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Stack(
        children: [
          Positioned.fill(
            child: Container(
              color: isDark ? AppColors.bgDark : const Color(0xFFF8FAFC),
            ),
          ),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // --- HEADER SUMMARY ---
                  Text(
                    'Rate Your Experience',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: isDark ? AppColors.textDarkPrimary : AppColors.textLightPrimary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'How was your service with ${widget.revieweeName}?',
                    style: TextStyle(
                      fontSize: 16,
                      color: isDark ? AppColors.textDarkSecondary : AppColors.textLightSecondary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 36),

                  // --- STAR RATING ---
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(5, (index) {
                      final starVal = index + 1;
                      final isSelected = starVal <= _selectedRating;
                      return GestureDetector(
                        key: Key('rating_star_$starVal'),
                        onTap: () {
                          setState(() {
                            _selectedRating = starVal;
                          });
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          curve: Curves.easeOutBack,
                          margin: const EdgeInsets.symmetric(horizontal: 8.0),
                          transform: isSelected
                              ? Matrix4.diagonal3Values(1.15, 1.15, 1.0)
                              : Matrix4.identity(),
                          child: Icon(
                            isSelected ? Icons.star_rounded : Icons.star_border_rounded,
                            size: 48,
                            color: isSelected ? Colors.amber : Colors.grey.withValues(alpha: 0.4),
                          ),
                        ),
                      );
                    }),
                  ),
                  const SizedBox(height: 40),

                  // --- COMMENTS SECTION ---
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Leave a comment (Optional)',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: isDark ? AppColors.textDarkPrimary : AppColors.textLightPrimary,
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        key: const Key('review_comment_field'),
                        controller: _commentController,
                        maxLines: 4,
                        decoration: InputDecoration(
                          hintText: 'Share details of your experience...',
                          fillColor: isDark ? AppColors.bgDarkCard : Colors.white,
                          filled: true,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide(
                              color: Colors.grey.withValues(alpha: 0.2),
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide(
                              color: Colors.grey.withValues(alpha: 0.2),
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: const BorderSide(
                              color: AppColors.primary,
                              width: 2.0,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 40),

                  // --- SUBMIT WORK BUTTON ---
                  if (_errorMessage.isNotEmpty) ...[
                    Text(
                      _errorMessage,
                      style: const TextStyle(color: Colors.red, fontSize: 14),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                  ],
                  ElevatedButton(
                    key: const Key('review_submit_button'),
                    onPressed: (_selectedRating == 0 || _isProcessing) ? null : _submitReview,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _selectedRating == 0 ? Colors.grey.withValues(alpha: 0.3) : AppColors.primary,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 0,
                    ),
                    child: _isProcessing
                        ? const CircularProgressIndicator(color: Colors.white)
                        : _showSuccess
                            ? const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.check_circle_outline, color: Colors.white),
                                  SizedBox(width: 8),
                                  Text(
                                    'Review Submitted',
                                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                                  ),
                                ],
                              )
                            : const Text(
                                'Submit Review',
                                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                              ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
