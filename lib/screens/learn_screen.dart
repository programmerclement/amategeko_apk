import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../widgets/app_snackbar.dart';

class LearnScreen extends StatefulWidget {
  final VoidCallback? onTakeExam;

  const LearnScreen({super.key, this.onTakeExam});

  @override
  State<LearnScreen> createState() => _LearnScreenState();
}

class _LearnScreenState extends State<LearnScreen> {
  // Questions & Session State
  List<Map<String, dynamic>> allQuestions = [];
  List<Map<String, dynamic>> sessionQuestions = [];
  int currentIndex = 0;
  bool sessionStarted = false;
  bool sessionComplete = false;

  // Answer State
  bool showAnswer = false;
  String? selectedAnswer;

  // Filter State
  String category = 'all';
  String difficulty = 'all';
  String hasImage = 'all'; // all, with-image, without-image
  List<String> categories = [];

  // Loading State
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchQuestions();
  }

  Future<void> _fetchQuestions() async {
    try {
      setState(() => isLoading = true);

      print('🎓 [LearnScreen] Fetching questions...');
      final response = await ApiService.fetchExamQuestions();
      print('📥 [LearnScreen] Questions response: $response');

      if (mounted) {
        // Handle different response structures
        List<Map<String, dynamic>> fetchedQuestions = [];

        if (response['questions'] is List) {
          fetchedQuestions = List<Map<String, dynamic>>.from(
            response['questions'],
          );
        } else if (response['data'] is List) {
          fetchedQuestions = List<Map<String, dynamic>>.from(response['data']);
        }

        if (fetchedQuestions.isNotEmpty) {
          // Filter by image if needed
          List<Map<String, dynamic>> filtered = fetchedQuestions;
          if (hasImage == 'with-image') {
            filtered = fetchedQuestions
                .where(
                  (q) =>
                      q['image'] != null &&
                      q['image'].toString().trim().isNotEmpty,
                )
                .toList();
          } else if (hasImage == 'without-image') {
            filtered = fetchedQuestions
                .where(
                  (q) =>
                      q['image'] == null ||
                      q['image'].toString().trim().isEmpty,
                )
                .toList();
          }

          // Shuffle
          filtered.shuffle();

          // Extract unique categories
          final uniqueCats = <String>{};
          for (var q in fetchedQuestions) {
            if (q['category'] != null && q['category'].toString().isNotEmpty) {
              uniqueCats.add(q['category']);
            }
          }

          setState(() {
            allQuestions = filtered;
            categories = uniqueCats.toList();
            isLoading = false;
          });

          print('✅ [LearnScreen] Loaded ${fetchedQuestions.length} questions');
          print('   - Categories: ${uniqueCats.length}');
          print('   - Filtered: ${filtered.length}');
        } else {
          setState(() => isLoading = false);
          AppSnackbar.error(context, 'No questions found');
        }
      }
    } catch (e) {
      print('❌ [LearnScreen] Error fetching questions: $e');
      if (mounted) {
        setState(() => isLoading = false);
        AppSnackbar.error(context, 'Error loading questions: $e');
      }
    }
  }

  void _startSession() {
    if (allQuestions.isEmpty) {
      AppSnackbar.error(context, 'No questions available with current filters');
      return;
    }

    // Take first 5 questions (already shuffled during fetch)
    final first5 = allQuestions.take(5).toList();
    setState(() {
      sessionQuestions = first5;
      sessionStarted = true;
      currentIndex = 0;
      showAnswer = false;
      selectedAnswer = null;
      sessionComplete = false;
    });

    print('🎓 [LearnScreen] Started learning session with 5 questions');
  }

  Future<void> _continueLearning() async {
    // Fetch fresh random questions
    setState(() => isLoading = true);
    await _fetchQuestions();

    if (mounted && allQuestions.isNotEmpty) {
      // Start new session with fresh questions
      final first5 = allQuestions.take(5).toList();
      setState(() {
        sessionQuestions = first5;
        sessionStarted = true;
        sessionComplete = false;
        currentIndex = 0;
        showAnswer = false;
        selectedAnswer = null;
        isLoading = false;
      });

      print(
        '🎓 [LearnScreen] Started new learning session with fresh random questions',
      );
    }
  }

  void _handleNext() {
    if (currentIndex < sessionQuestions.length - 1) {
      setState(() {
        currentIndex++;
        showAnswer = false;
        selectedAnswer = null;
      });
    } else {
      setState(() => sessionComplete = true);
      print('✅ [LearnScreen] Session completed');
    }
  }

  void _handlePrevious() {
    if (currentIndex > 0) {
      setState(() {
        currentIndex--;
        showAnswer = false;
        selectedAnswer = null;
      });
    }
  }

  void _handleAnswerClick(String answer) {
    setState(() {
      selectedAnswer = answer;
      showAnswer = true;
    });
  }

  String _extractAnswerLetter(String? correctAnswer) {
    if (correctAnswer == null) return '';
    final RegExp regex = RegExp(r'^\(?([a-d])\)', caseSensitive: false);
    final match = regex.firstMatch(correctAnswer);
    return match != null ? match.group(1)!.toLowerCase() : '';
  }

  String _getOptionLetter(int index) {
    return String.fromCharCode(97 + index); // a, b, c, d
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return _buildLoadingScreen();
    }

    if (!sessionStarted) {
      return _buildStartScreen();
    }

    if (sessionComplete) {
      return _buildCompletionScreen();
    }

    if (sessionQuestions.isEmpty || currentIndex >= sessionQuestions.length) {
      return SizedBox.expand(
        child: Center(child: Text('No questions available')),
      );
    }

    return _buildQuestionScreen();
  }

  Widget _buildLoadingScreen() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation(Colors.green.shade600),
          ),
          SizedBox(height: 16),
          Text(
            'Loading questions...',
            style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
          ),
        ],
      ),
    );
  }

  Widget _buildStartScreen() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Column(
        children: [
          SizedBox(height: 24),
          // Hero Section
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: Colors.blue.shade100,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Icon(
              Icons.school_outlined,
              size: 40,
              color: Colors.blue.shade600,
            ),
          ),
          SizedBox(height: 24),
          Text(
            'Learn',
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.w700,
              color: Colors.grey.shade900,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Master traffic rules with interactive learning sessions',
            style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 32),
          // Filters Card
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withValues(alpha: 0.08),
                  blurRadius: 12,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Customize Your Learning',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Colors.grey.shade900,
                  ),
                ),
                SizedBox(height: 16),
                // Category Filter
                _buildFilterLabel('Category'),
                SizedBox(height: 8),
                _buildFilterDropdown(
                  value: category,
                  items: ['all', ...categories],
                  onChanged: (value) {
                    setState(() => category = value);
                  },
                  displayName: (item) =>
                      item == 'all' ? 'All Categories' : item,
                ),
                SizedBox(height: 16),
                // Difficulty Filter
                _buildFilterLabel('Difficulty'),
                SizedBox(height: 8),
                _buildFilterDropdown(
                  value: difficulty,
                  items: ['all', 'easy', 'medium', 'hard'],
                  onChanged: (value) {
                    setState(() => difficulty = value);
                  },
                  displayName: (item) {
                    switch (item) {
                      case 'easy':
                        return 'Easy';
                      case 'medium':
                        return 'Medium';
                      case 'hard':
                        return 'Hard';
                      default:
                        return 'All Difficulties';
                    }
                  },
                ),
                SizedBox(height: 16),
                // Image Filter
                _buildFilterLabel('Questions With'),
                SizedBox(height: 8),
                _buildFilterDropdown(
                  value: hasImage,
                  items: ['all', 'with-image', 'without-image'],
                  onChanged: (value) {
                    setState(() => hasImage = value);
                  },
                  displayName: (item) {
                    switch (item) {
                      case 'with-image':
                        return 'With Images';
                      case 'without-image':
                        return 'Without Images';
                      default:
                        return 'All Questions';
                    }
                  },
                ),
                SizedBox(height: 20),
                // Apply Filters Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _fetchQuestions,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey.shade700,
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Text(
                      'Apply Filters',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
                SizedBox(height: 16),
                // Question Count Info
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.blue.shade200),
                  ),
                  child: Text(
                    '📚 ${allQuestions.length} questions available with current filters',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: Colors.blue.shade700,
                    ),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 24),
          // Start Button
          if (allQuestions.isNotEmpty)
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _startSession,
                icon: Icon(Icons.play_arrow),
                label: Text(
                  'Start Learning 5 Questions',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green.shade600,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ),
          SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildQuestionScreen() {
    final question = sessionQuestions[currentIndex];
    final correctLetter = _extractAnswerLetter(question['correctAnswer']);
    final options = question['options'] is List ? question['options'] : [];

    return SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Column(
        children: [
          // Header with progress
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Question ${currentIndex + 1}/5',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: Colors.grey.shade900,
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.blue.shade100,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${((currentIndex + 1) / 5 * 100).toStringAsFixed(0)}%',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.blue.shade700,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 12),
          // Progress Bar
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: (currentIndex + 1) / 5,
              minHeight: 6,
              backgroundColor: Colors.grey.shade300,
              valueColor: AlwaysStoppedAnimation(Colors.blue.shade600),
            ),
          ),
          SizedBox(height: 24),
          // Question Card
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withValues(alpha: 0.08),
                  blurRadius: 12,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Difficulty & Category Badges
                Row(
                  children: [
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: _getDifficultyColor(question['difficulty']),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        (question['difficulty'] ?? 'unknown')
                            .toString()
                            .toUpperCase(),
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    SizedBox(width: 8),
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.indigo.shade100,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        question['category'] ?? 'General',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: Colors.indigo.shade800,
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 16),
                // Question Text
                Text(
                  question['question'] ?? '',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Colors.grey.shade900,
                    height: 1.5,
                  ),
                ),
                SizedBox(height: 16),
                // Question Image
                if (question['image'] != null &&
                    question['image'].toString().isNotEmpty)
                  Padding(
                    padding: EdgeInsets.only(bottom: 16),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.network(
                        question['image'],
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            height: 200,
                            decoration: BoxDecoration(
                              color: Colors.grey.shade200,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Center(
                              child: Icon(
                                Icons.image_not_supported,
                                color: Colors.grey.shade400,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                // Options
                ...List.generate(options.length, (index) {
                  final optionLetter = _getOptionLetter(index);
                  final isSelected = selectedAnswer == optionLetter;
                  final isCorrect = optionLetter == correctLetter;
                  final shouldHighlight = showAnswer && isCorrect;
                  final shouldShowIncorrect =
                      showAnswer && isSelected && !isCorrect;

                  Color? bgColor;
                  Color? borderColor;
                  Color? textColor;

                  if (shouldHighlight) {
                    bgColor = Colors.green.shade50;
                    borderColor = Colors.green.shade500;
                    textColor = Colors.green.shade900;
                  } else if (shouldShowIncorrect) {
                    bgColor = Colors.red.shade50;
                    borderColor = Colors.red.shade500;
                    textColor = Colors.red.shade900;
                  } else if (isSelected) {
                    bgColor = Colors.blue.shade50;
                    borderColor = Colors.blue.shade500;
                    textColor = Colors.blue.shade900;
                  } else {
                    bgColor = Colors.grey.shade50;
                    borderColor = Colors.grey.shade300;
                    textColor = Colors.grey.shade900;
                  }

                  return Padding(
                    padding: EdgeInsets.only(bottom: 12),
                    child: GestureDetector(
                      onTap: showAnswer
                          ? null
                          : () => _handleAnswerClick(optionLetter),
                      child: Container(
                        decoration: BoxDecoration(
                          color: bgColor,
                          border: Border.all(color: borderColor),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        padding: EdgeInsets.all(12),
                        child: Row(
                          children: [
                            Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                color: shouldHighlight
                                    ? Colors.green.shade600
                                    : shouldShowIncorrect
                                    ? Colors.red.shade600
                                    : isSelected
                                    ? Colors.blue.shade600
                                    : Colors.grey.shade300,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Center(
                                child: Text(
                                  optionLetter.toUpperCase(),
                                  style: TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 14,
                                    color:
                                        shouldHighlight ||
                                            shouldShowIncorrect ||
                                            isSelected
                                        ? Colors.white
                                        : Colors.grey.shade600,
                                  ),
                                ),
                              ),
                            ),
                            SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                options[index] ?? '',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: textColor,
                                ),
                              ),
                            ),
                            if (shouldHighlight)
                              Icon(
                                Icons.check_circle,
                                color: Colors.green.shade600,
                                size: 20,
                              )
                            else if (shouldShowIncorrect)
                              Icon(
                                Icons.cancel,
                                color: Colors.red.shade600,
                                size: 20,
                              ),
                          ],
                        ),
                      ),
                    ),
                  );
                }),
                SizedBox(height: 12),
                // Explanation
                if (showAnswer &&
                    question['explanation'] != null &&
                    question['explanation'].toString().isNotEmpty)
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.indigo.shade50,
                      border: Border.all(color: Colors.indigo.shade200),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    padding: EdgeInsets.all(12),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.lightbulb_outline,
                          color: Colors.indigo.shade600,
                          size: 18,
                        ),
                        SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '💡 Explanation',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.indigo.shade700,
                                ),
                              ),
                              SizedBox(height: 6),
                              Text(
                                question['explanation'],
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.indigo.shade700,
                                  height: 1.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                SizedBox(height: 12),
                // Show Answer Button
                if (!showAnswer)
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => setState(() => showAnswer = true),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green.shade600,
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: Text(
                        'Show Correct Answer',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          SizedBox(height: 24),
          // Navigation
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: currentIndex == 0 ? null : _handlePrevious,
                  icon: Icon(Icons.arrow_back),
                  label: Text('Previous'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: currentIndex == 0
                        ? Colors.grey.shade300
                        : Colors.grey.shade600,
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
              SizedBox(width: 12),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${currentIndex + 1} / 5',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _handleNext,
                  icon: Icon(
                    currentIndex == 4
                        ? Icons.check_circle
                        : Icons.arrow_forward,
                  ),
                  label: Text(currentIndex == 4 ? 'Finish' : 'Next'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green.shade600,
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildCompletionScreen() {
    return Center(
      child: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: Colors.green.shade100,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Icon(
                Icons.emoji_events_outlined,
                size: 50,
                color: Colors.green.shade600,
              ),
            ),
            SizedBox(height: 24),
            Text(
              'Great Job!',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w700,
                color: Colors.grey.shade900,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'You completed the learning session!',
              style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
            ),
            SizedBox(height: 32),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: _continueLearning,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey.shade700,
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Text(
                      'Continue Learning',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: widget.onTakeExam,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green.shade600,
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Text(
                      'Take Exam',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterLabel(String text) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: Colors.grey.shade700,
      ),
    );
  }

  Widget _buildFilterDropdown({
    required String value,
    required List<String> items,
    required Function(String) onChanged,
    required String Function(String) displayName,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8),
      ),
      padding: EdgeInsets.symmetric(horizontal: 12),
      child: DropdownButton<String>(
        value: value,
        items: items
            .map(
              (item) =>
                  DropdownMenuItem(value: item, child: Text(displayName(item))),
            )
            .toList(),
        onChanged: (newValue) {
          if (newValue != null) {
            onChanged(newValue);
          }
        },
        underline: SizedBox(),
        isExpanded: true,
        style: TextStyle(
          fontSize: 14,
          color: Colors.grey.shade900,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Color _getDifficultyColor(String? difficulty) {
    switch (difficulty?.toLowerCase()) {
      case 'easy':
        return Colors.green.shade500;
      case 'medium':
        return Colors.amber.shade500;
      case 'hard':
        return Colors.red.shade500;
      default:
        return Colors.grey.shade500;
    }
  }
}
