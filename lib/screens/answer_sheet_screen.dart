import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/vocabulary.dart';

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
    return Scaffold(
      backgroundColor: const Color(0xFFF6F6F8),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF6F6F8),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Color(0xFF2C3E50)),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Answer Sheet',
          style: GoogleFonts.lexend(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF2C3E50),
          ),
        ),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Header
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Text(
                    'Quiz Answer Sheet',
                    style: GoogleFonts.lexend(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF2C3E50),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Review all questions with your answers and correct answers',
                    style: GoogleFonts.lexend(
                      fontSize: 16,
                      color: const Color(0xFF2C3E50).withOpacity(0.7),
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 20),
            
            // Answer list
            Expanded(
              child: ListView.builder(
                itemCount: quizWords.length,
                itemBuilder: (context, index) {
                  final question = quizWords[index];
                  final userAnswer = userAnswers[index];
                  final correctAnswer = correctAnswers[index];
                  final isCorrect = userAnswer == correctAnswer;
                  final options = questionOptions[index] ?? [];
                  
                  return Container(
                    margin: const EdgeInsets.only(bottom: 20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Question header
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: isCorrect 
                                ? Colors.green.withOpacity(0.1)
                                : Colors.red.withOpacity(0.1),
                            borderRadius: const BorderRadius.only(
                              topLeft: Radius.circular(16),
                              topRight: Radius.circular(16),
                            ),
                            border: Border(
                              bottom: BorderSide(
                                color: isCorrect ? Colors.green : Colors.red,
                                width: 2,
                              ),
                            ),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 32,
                                height: 32,
                                decoration: BoxDecoration(
                                  color: isCorrect ? Colors.green : Colors.red,
                                  shape: BoxShape.circle,
                                ),
                                child: Center(
                                  child: Text(
                                    '${index + 1}',
                                    style: GoogleFonts.lexend(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Text(
                                  'What is the Bengali meaning of "${question.word}"?',
                                  style: GoogleFonts.lexend(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w600,
                                    color: const Color(0xFF2C3E50),
                                  ),
                                ),
                              ),
                              Icon(
                                isCorrect ? Icons.check_circle : Icons.cancel,
                                color: isCorrect ? Colors.green : Colors.red,
                                size: 24,
                              ),
                            ],
                          ),
                        ),
                        
                        // Options list
                        Padding(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Options:',
                                style: GoogleFonts.lexend(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: const Color(0xFF2C3E50),
                                ),
                              ),
                              const SizedBox(height: 12),
                              
                               // Display all options
                               ...options.map((option) {
                                 final isUserAnswer = userAnswer == option;
                                 final isCorrectAnswer = correctAnswer == option;
                                 
                                 Color backgroundColor;
                                 Color borderColor;
                                 Color textColor;
                                 IconData? icon;
                                 
                                 if (isCorrectAnswer) {
                                   backgroundColor = Colors.green.withOpacity(0.1);
                                   borderColor = Colors.green;
                                   textColor = Colors.green.shade700;
                                   icon = Icons.check;
                                 } else if (isUserAnswer && !isCorrectAnswer) {
                                   backgroundColor = Colors.red.withOpacity(0.1);
                                   borderColor = Colors.red;
                                   textColor = Colors.red.shade700;
                                   icon = Icons.close;
                                 } else {
                                   backgroundColor = const Color(0xFFF5F5F5);
                                   borderColor = const Color(0xFFE0E0E0);
                                   textColor = const Color(0xFF2C3E50).withOpacity(0.6);
                                 }
                                 
                                 return Container(
                                   margin: const EdgeInsets.only(bottom: 8),
                                   padding: const EdgeInsets.all(16),
                                   decoration: BoxDecoration(
                                     color: backgroundColor,
                                     borderRadius: BorderRadius.circular(12),
                                     border: Border.all(color: borderColor, width: 2),
                                   ),
                                   child: Row(
                                     children: [
                                       Container(
                                         width: 24,
                                         height: 24,
                                         decoration: BoxDecoration(
                                           shape: BoxShape.circle,
                                           border: Border.all(color: borderColor, width: 2),
                                           color: (isUserAnswer || isCorrectAnswer) 
                                               ? borderColor 
                                               : Colors.transparent,
                                         ),
                                         child: (isUserAnswer || isCorrectAnswer)
                                             ? Icon(
                                                 icon ?? Icons.check,
                                                 size: 12,
                                                 color: Colors.white,
                                               )
                                             : null,
                                       ),
                                       const SizedBox(width: 12),
                                       Expanded(
                                         child: Text(
                                           option,
                                           style: GoogleFonts.lexend(
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
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
