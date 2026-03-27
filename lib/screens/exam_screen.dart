import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:math';
import '../services/api_service.dart';
import '../widgets/app_snackbar.dart';

class ExamScreen extends StatefulWidget {
  final Map<String, dynamic>? eligibilityData;

  const ExamScreen({
    super.key,
    this.eligibilityData,
  });

  @override
  State<ExamScreen> createState() => _ExamScreenState();
}

class _ExamScreenState extends State<ExamScreen> {
  // Exam state
  Map<String, dynamic>? examData;
  bool isLoadingExam = false;
  bool isSubmittingExam = false;

  // Navigation
  int currentQuestionIndex = 0;
  Map<String, dynamic> answers = {};

  // Timer
  late DateTime examStartTime;
  int examDurationSeconds = 1200; // Always 20 minutes = 1200 seconds
  int remainingSeconds = 1200;
  bool examFinished = false;
  bool showSubmitConfirm = false;
  
  // Question navigation scroll
  late ScrollController questionScrollController;

  @override
  void initState() {
    super.initState();
    print('📝 [ExamScreen] Initializing exam screen');
    
    questionScrollController = ScrollController();
    
    // Disable system features to prevent cheating
    _disableCheating();
    
    // Start exam loading (timer will start after exam loads)
    _generateExam();
  }

  void _disableCheating() {
    // Disable screenshots
    SystemChrome.setEnabledSystemUIMode(
      SystemUiMode.immersiveSticky,
      overlays: [SystemUiOverlay.top],
    );
    
    // Disable copy/paste
    // This is handled at the widget level for text selection
  }

  void _startTimer() {
    print('⏱️ [ExamScreen] Timer starting... Duration: $examDurationSeconds seconds (${examDurationSeconds ~/ 60}:${(examDurationSeconds % 60).toString().padLeft(2, '0')})');
    examStartTime = DateTime.now();
    // Reset remaining seconds to full duration
    setState(() {
      remainingSeconds = examDurationSeconds;
    });
    _scheduleTimerTick();
  }

  void _scheduleTimerTick() {
    Future.delayed(Duration(milliseconds: 1000), () {
      if (mounted && !examFinished) {
        // Calculate elapsed time from the exact moment exam started
        final elapsedDuration = DateTime.now().difference(examStartTime);
        final elapsedSeconds = elapsedDuration.inSeconds;
        final newRemaining = max(0, examDurationSeconds - elapsedSeconds);
        
        // Debug: log every 5 seconds
        if (elapsedSeconds % 5 == 0) {
          print('⏱️ [Timer] Elapsed: ${elapsedSeconds}s, Remaining: ${newRemaining}s (${newRemaining ~/ 60}:${(newRemaining % 60).toString().padLeft(2, '0')})');
        }
        
        setState(() {
          remainingSeconds = newRemaining;
        });
        
        // Auto-submit when time is up
        if (remainingSeconds <= 0 && !examFinished) {
          examFinished = true;
          print('⏱️ [ExamScreen] TIME UP! Auto-submitting exam...');
          _autoSubmitExam();
          return;
        }
        
        // Continue ticking if time remains and exam not finished
        if (!examFinished && remainingSeconds > 0) {
          _scheduleTimerTick();
        }
      }
    });
  }

  Future<void> _generateExam() async {
    setState(() => isLoadingExam = true);

    try {
      print('🚀 [ExamScreen] Generating exam...');
      final response = await ApiService.generateExam(
        category: 'all',
        difficulty: 'all',
        numberOfQuestions: 20,
      );

      print('✅ [ExamScreen] Exam response: $response');

      if (!mounted) return;

      if (response['success'] != true) {
        throw Exception(response['message'] ?? 'Failed to generate exam (success=false)');
      }

      final examSession = response['examSession'];
      if (examSession == null) {
        throw Exception('No examSession in response');
      }

      final questions = examSession['questions'];
      if (questions == null || questions is! List || questions.isEmpty) {
        throw Exception('Invalid questions: ${questions.runtimeType}');
      }

      setState(() {
        examData = examSession;
        // ALWAYS use 20 minutes (1200 seconds) regardless of API response
        examDurationSeconds = 1200; // 20 minutes = 1200 seconds
        remainingSeconds = examDurationSeconds;
        print('📋 [ExamScreen] Exam duration: 20 minutes = 1200 seconds (FIXED)');
        isLoadingExam = false;
      });

      print('✅ [ExamScreen] Exam loaded with ${examData?['questions']?.length} questions');
      
      // Start timer NOW - after exam is loaded and ready
      _startTimer();
      
      if (mounted) {
        AppSnackbar.success(context, '✅ Exam started! Good luck!');
      }
    } catch (e) {
      print('❌ [ExamScreen] Error generating exam: $e');
      
      if (mounted) {
        setState(() => isLoadingExam = false);
        
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Text('Error Starting Exam'),
            content: Text('$e\n\nPlease try again.'),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.pop(context);
                },
                child: Text('Go Back'),
              )
            ],
          ),
        );
      }
    }
  }

  Future<void> _autoSubmitExam() async {
    print('⏱️ [ExamScreen] Time is up! Auto-submitting exam...');
    await _submitExam();
  }

  Future<void> _submitExam() async {
    if (examData == null || answers.isEmpty) {
      AppSnackbar.error(context, 'No answers to submit');
      return;
    }

    setState(() => isSubmittingExam = true);

    try {
      print('📤 [ExamScreen] Submitting exam...');
      print('📊 Answered: ${answers.length} questions');
      
      final timeSpent = examDurationSeconds - remainingSeconds;
      
      final response = await ApiService.submitExam(
        answers: answers,
        timeSpent: timeSpent,
        examData: {
          'questions': examData?['questions'],
          'totalQuestions': examData?['totalQuestions'],
          'category': examData?['category'],
          'difficulty': examData?['difficulty'],
        },
      );

      print('✅ [ExamScreen] Submit response: $response');

      if (!mounted) return;

      if (response['success'] == true) {
        // Show results screen
        _showResultsDialog(response);
      } else {
        AppSnackbar.error(context, 
          response['message'] ?? 'Failed to submit exam');
      }
    } catch (e) {
      print('❌ [ExamScreen] Error submitting exam: $e');
      if (mounted) {
        AppSnackbar.error(context, 'Error: ${e.toString()}');
      }
    } finally {
      if (mounted) {
        setState(() => isSubmittingExam = false);
      }
    }
  }

  void _showResultsDialog(Map<String, dynamic> results) {
    final score = results['score'] ?? 0;
    final passed = results['passed'] ?? false;
    final correctAnswers = results['correctAnswers'] ?? 0;
    final totalQuestions = results['totalQuestions'] ?? 0;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                passed ? Icons.check_circle : Icons.cancel,
                size: 64,
                color: passed ? Colors.green.shade600 : Colors.red.shade600,
              ),
              SizedBox(height: 16),
              Text(
                passed ? '🎉 Congratulations!' : '😔 Keep Practicing!',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: Colors.grey.shade900,
                ),
              ),
              SizedBox(height: 8),
              Text(
                'Score: $score%',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.w700,
                  color: passed ? Colors.green.shade600 : Colors.red.shade600,
                ),
              ),
              SizedBox(height: 8),
              Text(
                '$correctAnswers out of $totalQuestions correct',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade600,
                ),
              ),
              SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context); // Close results dialog
                        Navigator.pop(context); // Return to ExamsTab
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green.shade600,
                        padding: EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: Text(
                        'Take Another Exam',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context); // Close results dialog
                        Navigator.pop(context); // Return to ExamsTab
                        Navigator.pop(context); // Back to Home
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.grey.shade600,
                        padding: EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: Text(
                        'Back to Home',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatTime(int seconds) {
    final minutes = seconds ~/ 60;
    final secs = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }

  Color _getTimeColor() {
    if (remainingSeconds <= 300) return Colors.red; // <= 5 min (300 seconds)
    if (remainingSeconds < 600) return Colors.orange; // < 10 min
    return Colors.green;
  }

  void _nextQuestion() {
    if (currentQuestionIndex < (examData?['questions']?.length ?? 0) - 1) {
      setState(() => currentQuestionIndex++);
      _scrollToCurrentQuestion();
    }
  }

  void _previousQuestion() {
    if (currentQuestionIndex > 0) {
      setState(() => currentQuestionIndex--);
      _scrollToCurrentQuestion();
    }
  }

  void _scrollToCurrentQuestion() {
    if (questionScrollController.hasClients && examData != null) {
      final questions = examData?['questions'] as List? ?? [];
      if (questions.isNotEmpty) {
        // Scroll to show current question button
        final offset = (currentQuestionIndex * 48.0) - 50;
        questionScrollController.animateTo(
          offset.clamp(0, questionScrollController.position.maxScrollExtent),
          duration: Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      }
    }
  }

  @override
  void dispose() {
    questionScrollController.dispose();
    // Re-enable system UI
    SystemChrome.setEnabledSystemUIMode(
      SystemUiMode.manual,
      overlays: SystemUiOverlay.values,
    );
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (isLoadingExam || examData == null) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(color: Colors.green.shade600),
              SizedBox(height: 16),
              Text('Preparing your exam...'),
            ],
          ),
        ),
      );
    }

    // Show Submit Confirmation Dialog
    if (showSubmitConfirm) {
      return Scaffold(
        body: Center(
          child: Dialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.warning,
                    size: 48,
                    color: Colors.orange.shade600,
                  ),
                  SizedBox(height: 16),
                  Text(
                    'Submit Exam?',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: Colors.grey.shade900,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Are you sure you want to submit?',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade600,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 8),
                  if ((examData?['questions']?.length ?? 0) - answers.length > 0)
                    Text(
                      'You have ${(examData?['questions']?.length ?? 0) - answers.length} unanswered questions',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.red.shade600,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: isSubmittingExam ? null : () {
                            setState(() {
                              showSubmitConfirm = false;
                            });
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.grey.shade600,
                            disabledBackgroundColor: Colors.grey.shade400,
                            padding: EdgeInsets.symmetric(vertical: 12),
                          ),
                          child: Text('Cancel'),
                        ),
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: isSubmittingExam ? null : () {
                            setState(() {
                              showSubmitConfirm = false;
                            });
                            _submitExam();
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red.shade600,
                            disabledBackgroundColor: Colors.grey.shade400,
                            padding: EdgeInsets.symmetric(vertical: 12),
                          ),
                          child: isSubmittingExam
                              ? SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation(Colors.white),
                                  ),
                                )
                              : Text('Submit Exam'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    final questions = examData?['questions'] as List? ?? [];
    final currentQuestion = questions.isNotEmpty 
        ? questions[currentQuestionIndex] as Map<String, dynamic>
        : null;
    final questionId = currentQuestion?['_id'] ?? 'q$currentQuestionIndex';
    final userAnswer = answers[questionId];

    return WillPopScope(
      onWillPop: () async {
        // Prevent back button during exam
        return false;
      },
      child: Scaffold(
        backgroundColor: Colors.grey.shade50,
        body: SafeArea(
          child: Column(
            children: [
              // Header with Timer and Progress
              Container(
                color: Colors.white,
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Timer and Question Counter
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Question ${currentQuestionIndex + 1}/${questions.length}',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Colors.grey.shade700,
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              '${answers.length} answered',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                        Row(
                          children: [
                            // Timer Display
                            Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: _getTimeColor().withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: _getTimeColor().withOpacity(0.3),
                                ),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.timer,
                                    size: 20,
                                    color: _getTimeColor(),
                                  ),
                                  SizedBox(width: 8),
                                  Text(
                                    _formatTime(remainingSeconds),
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w700,
                                      color: _getTimeColor(),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            SizedBox(width: 8),
                            // Exit/Cancel Button (Icon Only)
                            IconButton(
                              onPressed: isSubmittingExam ? null : () {
                                showDialog(
                                  context: context,
                                  builder: (context) => AlertDialog(
                                    title: Text('Exit Exam?'),
                                    content: Text('Do you want to exit the exam? Your progress will not be saved.'),
                                    actions: [
                                      TextButton(
                                        onPressed: () => Navigator.pop(context),
                                        child: Text('Continue Exam'),
                                      ),
                                      TextButton(
                                        onPressed: () {
                                          Navigator.pop(context);
                                          Navigator.pop(context);
                                        },
                                        child: Text('Exit', style: TextStyle(color: Colors.red)),
                                      ),
                                    ],
                                  ),
                                );
                              },
                              icon: Icon(Icons.exit_to_app, color: Colors.grey.shade600),
                              tooltip: 'Exit Exam',
                            ),
                            SizedBox(width: 4),
                            // Submit Button in Header
                            ElevatedButton.icon(
                              onPressed: isSubmittingExam ? null : () {
                                setState(() {
                                  showSubmitConfirm = true;
                                });
                              },
                              icon: Icon(Icons.check),
                              label: Text('Submit'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.red.shade600,
                                disabledBackgroundColor: Colors.grey.shade400,
                                foregroundColor: Colors.white,
                                padding: EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 8,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    SizedBox(height: 12),
                    
                    // Progress bar
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: LinearProgressIndicator(
                        value: (currentQuestionIndex + 1) / questions.length,
                        minHeight: 6,
                        backgroundColor: Colors.grey.shade200,
                        valueColor: AlwaysStoppedAnimation(Colors.green.shade600),
                      ),
                    ),
                  ],
                ),
              ),

              // Questions Navigation Numbers (with auto-scroll)
              Container(
                color: Colors.white,
                padding: EdgeInsets.all(12),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  controller: questionScrollController,
                  child: Row(
                    children: List.generate(
                      questions.length,
                      (index) {
                        final qId = questions[index]['_id'] ?? 'q$index';
                        final isAnswered = answers.containsKey(qId);
                        final isCurrent = index == currentQuestionIndex;

                        return GestureDetector(
                          onTap: () {
                            setState(() => currentQuestionIndex = index);
                            _scrollToCurrentQuestion();
                          },
                          child: Container(
                            width: 40,
                            height: 40,
                            margin: EdgeInsets.only(right: 8),
                            decoration: BoxDecoration(
                              color: isCurrent
                                  ? Colors.green.shade600
                                  : isAnswered
                                      ? Colors.blue.shade100
                                      : Colors.grey.shade200,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: isCurrent
                                    ? Colors.green.shade700
                                    : Colors.transparent,
                                width: 2,
                              ),
                            ),
                            child: Center(
                              child: Text(
                                '${index + 1}',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: isCurrent || isAnswered
                                      ? Colors.white
                                      : Colors.grey.shade700,
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ),

              // Question Content
              Expanded(
                child: SingleChildScrollView(
                  padding: EdgeInsets.all(16),
                  child: currentQuestion != null
                      ? Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Question text
                            SelectableText(
                              currentQuestion['question'] ?? 'Question not available',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Colors.grey.shade900,
                              ),
                            ),
                            SizedBox(height: 24),

                            // Question image (if available)
                            if (currentQuestion['image'] != null &&
                                (currentQuestion['image'] as String).isNotEmpty)
                              Padding(
                                padding: EdgeInsets.only(bottom: 16),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: Image.network(
                                    currentQuestion['image'],
                                    fit: BoxFit.cover,
                                    height: 200,
                                    errorBuilder: (context, error, stackTrace) {
                                      return Container(
                                        height: 200,
                                        color: Colors.grey.shade200,
                                        child: Center(
                                          child: Icon(Icons.image_not_supported),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              ),

                            // Options
                            ...(currentQuestion['options'] as List?)?.asMap().entries.map(
                              (entry) {
                                final option = entry.value;

                                return Padding(
                                  padding: EdgeInsets.only(bottom: 12),
                                  child: GestureDetector(
                                    onTap: () {
                                      setState(() {
                                        answers[questionId] = option;
                                      });
                                    },
                                    child: Container(
                                      padding: EdgeInsets.all(16),
                                      decoration: BoxDecoration(
                                        color: userAnswer == option
                                            ? Colors.blue.shade50
                                            : Colors.white,
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                          color: userAnswer == option
                                              ? Colors.blue.shade600
                                              : Colors.grey.shade300,
                                          width: userAnswer == option ? 2 : 1,
                                        ),
                                      ),
                                      child: Row(
                                        children: [
                                          Container(
                                            width: 24,
                                            height: 24,
                                            decoration: BoxDecoration(
                                              shape: BoxShape.circle,
                                              border: Border.all(
                                                color: userAnswer == option
                                                    ? Colors.blue.shade600
                                                    : Colors.grey.shade400,
                                                width:
                                                    userAnswer == option ? 8 : 2,
                                              ),
                                            ),
                                          ),
                                          SizedBox(width: 16),
                                          Expanded(
                                            child: Text(
                                              option ?? '',
                                              style: TextStyle(
                                                fontSize: 14,
                                                color: Colors.grey.shade900,
                                                fontWeight: userAnswer == option
                                                    ? FontWeight.w600
                                                    : FontWeight.w400,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ).toList() ??
                                [],
                          ],
                        )
                      : Center(child: Text('No question data')),
                ),
              ),

              // Bottom Navigation
              Container(
                color: Colors.white,
                padding: EdgeInsets.all(16),
                child: Row(
                  children: [
                    // Previous Button
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: currentQuestionIndex > 0 && !isSubmittingExam
                            ? _previousQuestion
                            : null,
                        icon: Icon(Icons.arrow_back),
                        label: Text('Previous'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.grey.shade600,
                          disabledBackgroundColor: Colors.grey.shade300,
                          foregroundColor: Colors.white,
                          padding: EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                    SizedBox(width: 12),

                    // Next or Submit Button
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: isSubmittingExam
                            ? null
                            : currentQuestionIndex < questions.length - 1
                                ? _nextQuestion
                                : _submitExam,
                        icon: isSubmittingExam
                            ? SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor:
                                      AlwaysStoppedAnimation(Colors.white),
                                ),
                              )
                            : Icon(
                                currentQuestionIndex < questions.length - 1
                                    ? Icons.arrow_forward
                                    : Icons.check,
                              ),
                        label: Text(
                          isSubmittingExam
                              ? 'Submitting...'
                              : currentQuestionIndex < questions.length - 1
                                  ? 'Next'
                                  : 'Submit Exam',
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green.shade600,
                          disabledBackgroundColor: Colors.grey.shade300,
                          foregroundColor: Colors.white,
                          padding: EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
