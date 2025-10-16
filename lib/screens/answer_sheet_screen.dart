import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/vocabulary.dart';
import '../utils/app_themes.dart';

/// Answer sheet screen showing all questions with user and correct answers
class AnswerSheetScreen extends StatelessWidget {
  final List<Vocabulary> quizWords;
  final Map<int, String?> userAnswers;
  final Map<int, String> correctAnswers;
  final Map<int, List<String>> questionOptions;

  const AnswerSheetScreen({
    super.key,
    required this.quizWords,
    required this.userAnswers,
    required this.correctAnswers,
    required this.questionOptions,
  });

  @override
  Widget build(BuildContext context) {
    // Calculate score for header
    int correctCount = 0;
    for (int i = 0; i < quizWords.length; i++) {
      if (userAnswers[i] == correctAnswers[i]) {
        correctCount++;
      }
    }
    final percentage = (correctCount / quizWords.length * 100).round();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: AppThemes.getBackgroundColor(context),
      appBar: AppBar(
        backgroundColor: AppThemes.getBackgroundColor(context),
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_rounded,
            color: AppThemes.getTextColor(context),
            size: 20,
          ),
          onPressed: () {
            HapticFeedback.lightImpact();
            Navigator.pop(context);
          },
        ),
        title: Row(
          children: [
            Icon(
              Icons.quiz_outlined,
              color: AppThemes.getTextColor(context),
              size: 24,
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Answer Review',
                  style: GoogleFonts.lexend(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: AppThemes.getTextColor(context),
                    letterSpacing: -0.2,
                    height: 1.0,
                  ),
                ),
                Text(
                  'Review your quiz answers',
                  style: GoogleFonts.lexend(
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                    color: AppThemes.getSecondaryTextColor(context),
                    letterSpacing: 0.1,
                    height: 1.0,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
          child: Column(
            children: [
              // Score summary card - following app's card pattern
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: AppThemes.getCardColor(context),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: isDark
                          ? Colors.black.withOpacity(0.4)
                          : Colors.black.withOpacity(0.12),
                      blurRadius: 16,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    // Score display
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        gradient: RadialGradient(
                          colors: [
                            AppThemes.getPerformanceColor(context, percentage),
                            AppThemes.getPerformanceColor(context, percentage).withOpacity(0.7),
                          ],
                        ),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: AppThemes.getPerformanceColor(context, percentage).withOpacity(0.3),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Center(
                        child: Text(
                          '$percentage%',
                          style: GoogleFonts.lexend(
                            fontSize: 24,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                            letterSpacing: -0.5,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      '$correctCount of ${quizWords.length} correct',
                      style: GoogleFonts.lexend(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: AppThemes.getTextColor(context),
                        letterSpacing: -0.3,
                        height: 1.1,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _getPerformanceMessage(percentage),
                      style: GoogleFonts.lexend(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: AppThemes.getSecondaryTextColor(context),
                        letterSpacing: 0.1,
                        height: 1.4,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 24),
              
              // Questions list - following app's card pattern
              ...quizWords.asMap().entries.map((entry) {
                final index = entry.key;
                final question = entry.value;
                final userAnswer = userAnswers[index];
                final correctAnswer = correctAnswers[index] ?? '';
                final isCorrect = userAnswer == correctAnswer;
                final options = questionOptions[index] ?? [];
                
                return _buildQuestionCard(
                  context,
                  index + 1,
                  question,
                  userAnswer,
                  correctAnswer,
                  isCorrect,
                  options,
                );
              }).toList(),
            ],
          ),
        ),
      ),
    );
  }

  String _getPerformanceMessage(int percentage) {
    if (percentage >= 80) return 'Excellent work!';
    if (percentage >= 60) return 'Good progress!';
    return 'Keep practicing!';
  }

  Widget _buildQuestionCard(
    BuildContext context,
    int questionNumber,
    Vocabulary question,
    String? userAnswer,
    String correctAnswer,
    bool isCorrect,
    List<String> options,
  ) {
    final safeUserAnswer = userAnswer ?? '';
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: AppThemes.getCardColor(context),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withOpacity(0.4)
                : Colors.black.withOpacity(0.12),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Question header - clean minimal design
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: isCorrect 
                  ? AppThemes.getSuccessColor(context).withOpacity(0.05)
                  : AppThemes.getErrorColor(context).withOpacity(0.05),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
            ),
            child: Row(
              children: [
                // Question number badge - following app's pattern
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: isCorrect 
                        ? AppThemes.getSuccessColor(context)
                        : AppThemes.getErrorColor(context),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: (isCorrect 
                            ? AppThemes.getSuccessColor(context)
                            : AppThemes.getErrorColor(context)).withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Text(
                      '$questionNumber',
                      style: GoogleFonts.lexend(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                        letterSpacing: 0.1,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'What is the Bengali meaning of:',
                        style: GoogleFonts.lexend(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: AppThemes.getSecondaryTextColor(context),
                          letterSpacing: 0.1,
                          height: 1.3,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        question.word,
                        style: GoogleFonts.lexend(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: AppThemes.getTextColor(context),
                          letterSpacing: -0.3,
                          height: 1.1,
                        ),
                      ),
                    ],
                  ),
                ),
                // Status icon - following app's pattern
                Icon(
                  isCorrect ? Icons.check_circle : Icons.cancel,
                  color: isCorrect 
                      ? AppThemes.getSuccessColor(context)
                      : AppThemes.getErrorColor(context),
                  size: 24,
                ),
              ],
            ),
          ),
          
          // Options - clean minimal design
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: options.map((option) {
                final isUserAnswer = safeUserAnswer == option;
                final isCorrectAnswer = correctAnswer == option;
                
                Color backgroundColor;
                Color textColor;
                IconData? icon;
                
                if (isCorrectAnswer) {
                  backgroundColor = AppThemes.getSuccessColor(context).withOpacity(0.08);
                  textColor = AppThemes.getSuccessColor(context);
                  icon = Icons.check;
                } else if (isUserAnswer && !isCorrectAnswer) {
                  backgroundColor = AppThemes.getErrorColor(context).withOpacity(0.08);
                  textColor = AppThemes.getErrorColor(context);
                  icon = Icons.close;
                } else {
                  backgroundColor = Colors.transparent;
                  textColor = AppThemes.getSecondaryTextColor(context);
                }
                
                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: backgroundColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 20,
                        height: 20,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: (isUserAnswer || isCorrectAnswer) 
                              ? textColor 
                              : Colors.transparent,
                          border: (isUserAnswer || isCorrectAnswer) 
                              ? null 
                              : Border.all(
                                  color: AppThemes.getBorderColor(context).withOpacity(0.3),
                                  width: 1.5,
                                ),
                        ),
                        child: (isUserAnswer || isCorrectAnswer)
                            ? Icon(
                                icon ?? Icons.check,
                                size: 10,
                                color: Colors.white,
                              )
                            : null,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          option,
                          style: GoogleFonts.notoSansBengali(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: textColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}
