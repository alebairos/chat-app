import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/journal_entry_model.dart';
import '../services/journal_generation_service.dart';
import '../services/journal_storage_service.dart';
import '../widgets/journal_entry_card.dart';
import '../widgets/journal_language_toggle.dart';
import '../widgets/detailed_summary_widget.dart';
import '../widgets/journal_loading_skeleton.dart';
import '../../../utils/logger.dart';

/// Main journal screen with date navigation and language toggle
class JournalScreen extends StatefulWidget {
  const JournalScreen({super.key});

  @override
  State<JournalScreen> createState() => _JournalScreenState();
}

class _JournalScreenState extends State<JournalScreen>
    with SingleTickerProviderStateMixin {
  static final Logger _logger = Logger();

  late TabController _tabController;
  String _selectedLanguage = 'pt_BR';
  DateTime _selectedDate = DateTime.now();

  JournalEntryModel? _currentJournalEntry;
  Map<String, dynamic>? _currentDailySummary;
  bool _isLoading = false;
  bool _isGenerating = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadUserLanguagePreference();
    _loadJournalForDate();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  /// Load user's language preference from SharedPreferences
  Future<void> _loadUserLanguagePreference() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedLanguage = prefs.getString('journal_language') ?? 'pt_BR';

      if (mounted) {
        setState(() {
          _selectedLanguage = savedLanguage;
        });
      }
    } catch (e) {
      _logger.warning('JournalScreen: Failed to load language preference: $e');
    }
  }

  /// Save user's language preference
  Future<void> _saveUserLanguagePreference(String language) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('journal_language', language);
    } catch (e) {
      _logger.warning('JournalScreen: Failed to save language preference: $e');
    }
  }

  /// Load journal entry for the selected date
  Future<void> _loadJournalForDate() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Load existing journal entry
      final existingEntry = await JournalStorageService.getJournalForDate(
          _selectedDate, _selectedLanguage);

      // Load daily summary data from service layer
      final dayData =
          await JournalGenerationService.getDayDataForSummary(_selectedDate);
      final dailySummary = JournalGenerationService.generateDailySummary(
          _selectedDate, dayData.messages, dayData.activities);

      if (mounted) {
        setState(() {
          _currentJournalEntry = existingEntry;
          _currentDailySummary = dailySummary;
          _isLoading = false;
        });
      }
    } catch (e) {
      _logger.error('JournalScreen: Failed to load journal for date: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Failed to load journal entry';
        });
      }
    }
  }

  /// Generate a new journal entry for the selected date in both languages
  Future<void> _generateJournalEntry() async {
    if (!mounted || _isGenerating) return;

    setState(() {
      _isGenerating = true;
      _errorMessage = null;
    });

    try {
      // Generate journal entries for both languages in single API call
      await JournalGenerationService.generateDailyJournalBothLanguages(
          _selectedDate);

      if (mounted) {
        setState(() {
          _currentJournalEntry = null; // Clear cache to force fresh reload
          _isGenerating = false;
        });

        // Trigger fresh reload from database for current language
        _loadJournalForDate();

        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_selectedLanguage == 'pt_BR'
                ? 'Diários gerados com sucesso em ambos os idiomas!'
                : 'Journals generated successfully in both languages!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      _logger.error('JournalScreen: Failed to generate journal: $e');
      if (mounted) {
        setState(() {
          _isGenerating = false;
          _errorMessage = _selectedLanguage == 'pt_BR'
              ? 'Erro ao gerar diário. Tente novamente.'
              : 'Failed to generate journal. Please try again.';
        });
      }
    }
  }

  /// Handle language change
  void _onLanguageChanged(String newLanguage) {
    if (newLanguage != _selectedLanguage) {
      setState(() {
        _selectedLanguage = newLanguage;
        _currentJournalEntry = null; // Clear cached entry to force reload
      });

      _saveUserLanguagePreference(newLanguage);
      _loadJournalForDate(); // Reload for new language
    }
  }

  /// Build the centralized generation action bar
  Widget _buildGenerationActionBar() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        border: Border(
          bottom: BorderSide(color: Colors.grey.shade200, width: 0.5),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          ElevatedButton(
            onPressed: _isGenerating ? null : _generateJournalEntry,
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              backgroundColor: Theme.of(context).primaryColor,
              foregroundColor: Colors.white,
              alignment: Alignment.center,
            ),
            child: _isGenerating
                ? Row(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _selectedLanguage == 'pt_BR'
                            ? 'Gerando ambos idiomas...'
                            : 'Generating both languages...',
                        style: const TextStyle(fontSize: 14),
                      ),
                    ],
                  )
                : Text(
                    _currentJournalEntry == null
                        ? (_selectedLanguage == 'pt_BR'
                            ? 'Gerar Diário'
                            : 'Generate Journal')
                        : (_selectedLanguage == 'pt_BR'
                            ? 'Gerar Novamente'
                            : 'Regenerate'),
                    style: const TextStyle(fontSize: 14),
                  ),
          ),
        ],
      ),
    );
  }

  /// Handle date change
  void _onDateChanged(DateTime newDate) {
    if (newDate != _selectedDate) {
      setState(() {
        _selectedDate = newDate;
      });

      _loadJournalForDate();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Expanded(
              child: Text(
                _selectedLanguage == 'pt_BR' ? 'Meu diário' : 'Daily journal',
                textAlign: TextAlign.left,
              ),
            ),
            const SizedBox(width: 16), // Add spacing between title and toggle
            JournalLanguageToggle(
              selectedLanguage: _selectedLanguage,
              onLanguageChanged: _onLanguageChanged,
            ),
          ],
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: Colors.black,
        automaticallyImplyLeading:
            false, // Remove back button to give more space
      ),
      body: Column(
        children: [
          // Date Header - Prominent like Daymi
          _buildDateHeader(),

          // Internal Tab Bar - Journal vs Detailed Summary
          _buildInternalTabBar(),

          // Centralized Generation Action Bar
          _buildGenerationActionBar(),

          // Tab Content Body
          Expanded(
            child: _isLoading
                ? const JournalLoadingSkeleton()
                : TabBarView(
                    controller: _tabController,
                    children: [
                      _buildJournalTab(), // I-There journal narrative
                      _buildDetailedSummaryTab(), // Structured data summary
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  /// Build the prominent date header
  Widget _buildDateHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        border: Border(
          bottom: BorderSide(color: Colors.grey[200]!),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            onPressed: () =>
                _onDateChanged(_selectedDate.subtract(const Duration(days: 1))),
            icon: const Icon(Icons.chevron_left),
          ),
          GestureDetector(
            onTap: () async {
              final pickedDate = await showDatePicker(
                context: context,
                initialDate: _selectedDate,
                firstDate: DateTime.now().subtract(const Duration(days: 365)),
                lastDate: DateTime.now(),
              );

              if (pickedDate != null) {
                _onDateChanged(pickedDate);
              }
            },
            child: Column(
              children: [
                Text(
                  _selectedLanguage == 'pt_BR'
                      ? '${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}'
                      : '${_selectedDate.month}/${_selectedDate.day}/${_selectedDate.year}',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  _getWeekdayName(_selectedDate),
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: _selectedDate
                    .isBefore(DateTime.now().subtract(const Duration(days: 1)))
                ? () =>
                    _onDateChanged(_selectedDate.add(const Duration(days: 1)))
                : null,
            icon: const Icon(Icons.chevron_right),
          ),
        ],
      ),
    );
  }

  /// Build the internal tab bar
  Widget _buildInternalTabBar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(color: Colors.grey[200]!),
        ),
      ),
      child: TabBar(
        controller: _tabController,
        labelColor: Colors.blue[700],
        unselectedLabelColor: Colors.grey[600],
        indicatorColor: Colors.blue[700],
        tabs: [
          Tab(text: _selectedLanguage == 'pt_BR' ? 'Diário' : 'Journal'),
          Tab(
              text: _selectedLanguage == 'pt_BR'
                  ? 'Resumo Detalhado'
                  : 'Detailed Summary'),
        ],
      ),
    );
  }

  /// Build the journal tab content
  Widget _buildJournalTab() {
    if (_errorMessage != null) {
      return _buildErrorState();
    }

    if (_currentJournalEntry == null) {
      return _buildEmptyJournalState();
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: JournalEntryCard(
        entry: _currentJournalEntry!,
        language: _selectedLanguage,
      ),
    );
  }

  /// Build the detailed summary tab content
  Widget _buildDetailedSummaryTab() {
    if (_errorMessage != null) {
      return _buildErrorState();
    }

    if (_currentDailySummary == null) {
      return Center(
        child: Text(
          _selectedLanguage == 'pt_BR'
              ? 'Nenhum resumo disponível'
              : 'No summary available',
          style: TextStyle(color: Colors.grey[600]),
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: DetailedSummaryWidget(
        summary: _currentDailySummary!,
        language: _selectedLanguage,
      ),
    );
  }

  /// Build empty journal state with generate button
  Widget _buildEmptyJournalState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.book_outlined,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              _selectedLanguage == 'pt_BR'
                  ? 'Nenhum diário para esta data'
                  : 'No journal for this date',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              _selectedLanguage == 'pt_BR'
                  ? 'Gere um diário baseado nas suas atividades e conversas do dia'
                  : 'Generate a journal based on your activities and conversations for the day',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[500],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Text(
              _selectedLanguage == 'pt_BR'
                  ? 'Use o botão acima para gerar'
                  : 'Use the button above to generate',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[400],
                fontStyle: FontStyle.italic,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  /// Build error state
  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.red[400],
            ),
            const SizedBox(height: 16),
            Text(
              _errorMessage!,
              style: TextStyle(
                fontSize: 16,
                color: Colors.red[600],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadJournalForDate,
              child: Text(_selectedLanguage == 'pt_BR'
                  ? 'Tentar Novamente'
                  : 'Try Again'),
            ),
          ],
        ),
      ),
    );
  }

  /// Get weekday name in the selected language
  String _getWeekdayName(DateTime date) {
    final weekdays = _selectedLanguage == 'pt_BR'
        ? ['segunda', 'terça', 'quarta', 'quinta', 'sexta', 'sábado', 'domingo']
        : [
            'Monday',
            'Tuesday',
            'Wednesday',
            'Thursday',
            'Friday',
            'Saturday',
            'Sunday'
          ];

    return weekdays[date.weekday - 1];
  }
}
