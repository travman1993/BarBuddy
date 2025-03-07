import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:barbuddy/widgets/custom_app_bar.dart';
import 'package:barbuddy/widgets/drink_card.dart';
import 'package:barbuddy/models/drink_model.dart';
import 'package:barbuddy/services/drink_logger.dart';
import 'package:barbuddy/state/providers/user_provider.dart';
import 'package:barbuddy/state/providers/drink_provider.dart';
import 'package:barbuddy/utils/constants.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:collection/collection.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({Key? key}) : super(key: key);

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> with SingleTickerProviderStateMixin {
  final DrinkLogger _drinkLogger = DrinkLogger();
  
  late TabController _tabController;
  
  List<Drink> _pastWeekDrinks = [];
  List<Drink> _pastMonthDrinks = [];
  Map<String, dynamic>? _drinkingStats;
  
  bool _isLoading = true;
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadDrinkHistory();
  }
  
  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
  
  Future<void> _loadDrinkHistory() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      final userId = userProvider.currentUser.id;
      
      // Get today's drinks from DrinkProvider (already loaded)
      final drinkProvider = Provider.of<DrinkProvider>(context, listen: false);
      
      // Get past week and month drinks
      final now = DateTime.now();
      final oneWeekAgo = now.subtract(const Duration(days: 7));
      final oneMonthAgo = now.subtract(const Duration(days: 30));
      
      _pastWeekDrinks = await _drinkLogger.getUserDrinksInRange(
        userId,
        oneWeekAgo,
        now,
      );
      
      _pastMonthDrinks = await _drinkLogger.getUserDrinksInRange(
        userId,
        oneMonthAgo,
        now,
      );
      
      // Get drinking stats summary
      _drinkingStats = await _drinkLogger.getUserDrinkingStats(userId);
    } catch (e) {
      debugPrint('Error loading drink history: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(
        title: 'Drink History',
        showBackButton: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Tab Bar
                TabBar(
                  controller: _tabController,
                  labelColor: Theme.of(context).colorScheme.primary,
                  tabs: const [
                    Tab(text: 'SUMMARY'),
                    Tab(text: 'WEEK'),
                    Tab(text: 'MONTH'),
                  ],
                ),
                
                // Tab Bar View
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      // Summary Tab
                      _buildSummaryTab(),
                      
                      // Week Tab
                      _buildHistoryList(_pastWeekDrinks, 'Past 7 Days'),
                      
                      // Month Tab
                      _buildHistoryList(_pastMonthDrinks, 'Past 30 Days'),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
  
  Widget _buildSummaryTab() {
    if (_drinkingStats == null) {
      return const Center(
        child: Text('No drinking data available'),
      );
    }
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Today's summary
          _buildSummaryCard(
            title: 'Today',
            count: _drinkingStats!['today']['count'],
            standardDrinks: _drinkingStats!['today']['standardDrinks'],
          ),
          
          const SizedBox(height: 16),
          
          // Yesterday's summary
          _buildSummaryCard(
            title: 'Yesterday',
            count: _drinkingStats!['yesterday']['count'],
            standardDrinks: _drinkingStats!['yesterday']['standardDrinks'],
          ),
          
          const SizedBox(height: 16),
          
          // Week summary
          _buildSummaryCard(
            title: 'Past 7 Days',
            count: _drinkingStats!['pastWeek']['count'],
            standardDrinks: _drinkingStats!['pastWeek']['standardDrinks'],
            dailyAverage: _drinkingStats!['pastWeek']['dailyAverage'],
          ),
          
          const SizedBox(height: 24),
          
          // Weekly Trends Chart
          Text(
            'Weekly Trends',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 200,
            child: _buildWeeklyChart(),
          ),
          
          const SizedBox(height: 24),
          
          // Monthly summary
          _buildSummaryCard(
            title: 'Past 30 Days',
            count: _drinkingStats!['pastMonth']['count'],
            standardDrinks: _drinkingStats!['pastMonth']['standardDrinks'],
            dailyAverage: _drinkingStats!['pastMonth']['dailyAverage'],
            showMostCommon: true,
            mostCommonType: _drinkingStats!['pastMonth']['mostCommonType'],
          ),
          
          const SizedBox(height: 24),
          
          // Drink types breakdown
          Text(
            'Drink Types',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 200,
            child: _buildDrinkTypesChart(),
          ),
          
          const SizedBox(height: 32),
          
          // Drinking Pattern Card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Drinking Pattern',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 16),
                  _buildPatternInfoRow(
                    icon: Icons.calendar_today,
                    title: 'Drinking Days',
                    value: _calculateDrinkingDays(_pastMonthDrinks).toString(),
                    subtitle: 'out of last 30 days',
                  ),
                  const SizedBox(height: 8),
                  _buildPatternInfoRow(
                    icon: Icons.local_bar,
                    title: 'Avg. Drinks per Session',
                    value: _calculateAvgDrinksPerSession(_pastMonthDrinks).toStringAsFixed(1),
                    subtitle: 'standard drinks',
                  ),
                  const SizedBox(height: 8),
                  _buildPatternInfoRow(
                    icon: Icons.calendar_today,
                    title: 'Most Active Day',
                    value: _getMostActiveDrinkingDay(_pastMonthDrinks),
                    subtitle: 'day of week',
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Disclaimer
          const Card(
            child: Padding(
              padding: EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Disclaimer',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'This information is provided for personal tracking purposes only. '
                    'If you are concerned about your drinking, please consult a healthcare professional.',
                    style: TextStyle(fontSize: 12),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildSummaryCard({
    required String title,
    required int count,
    required double standardDrinks,
    double? dailyAverage,
    bool showMostCommon = false,
    String? mostCommonType,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        count.toString(),
                        style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Drinks',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        standardDrinks.toString(),
                        style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Standard Drinks',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                if (dailyAverage != null)
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          dailyAverage.toString(),
                          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'Daily Average',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
              ],
            ),
            if (showMostCommon && mostCommonType != null && mostCommonType != 'none')
              Padding(
                padding: const EdgeInsets.only(top: 16.0),
                child: Row(
                  children: [
                    Icon(
                      _getDrinkTypeIcon(mostCommonType),
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Most common: ${_formatDrinkType(mostCommonType)}',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
  
  IconData _getDrinkTypeIcon(String type) {
    switch (type) {
      case 'beer':
        return Icons.sports_bar;
      case 'wine':
        return Icons.wine_bar;
      case 'liquor':
        return Icons.local_bar;
      case 'cocktail':
        return Icons.nightlife;
      default:
        return Icons.local_drink;
    }
  }
  
  String _formatDrinkType(String type) {
    switch (type) {
      case 'beer':
        return 'Beer';
      case 'wine':
        return 'Wine';
      case 'liquor':
        return 'Liquor';
      case 'cocktail':
        return 'Cocktail';
      case 'custom':
        return 'Custom';
      default:
        return type.capitalize();
    }
  }
  
  Widget _buildPatternInfoRow({
    required IconData icon,
    required String title,
    required String value,
    required String subtitle,
  }) {
    return Row(
      children: [
        Icon(
          icon,
          size: 20,
          color: Theme.of(context).colorScheme.primary,
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              Text(
                subtitle,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
      ],
    );
  }
  
  Widget _buildHistoryList(List<Drink> drinks, String emptyMessage) {
    if (drinks.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.history,
              size: 64,
              color: Colors.grey[300],
            ),
            const SizedBox(height: 16),
            Text(
              'No Drinks Found',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              emptyMessage,
              style: TextStyle(color: Colors.grey[600]),
            ),
          ],
        ),
      );
    }

    // Group drinks by day
    final drinksByDay = groupBy(drinks, (Drink drink) {
      final date = drink.timestamp;
      return DateTime(date.year, date.month, date.day);
    });

    return ListView.builder(
      itemCount: drinksByDay.length,
      itemBuilder: (context, index) {
        final day = drinksByDay.keys.elementAt(index);
        final dayDrinks = drinksByDay[day]!;
        final dateStr = _formatDate(day);
        
        // Calculate totals for the day
        double totalStandardDrinks = 0;
        for (var drink in dayDrinks) {
          totalStandardDrinks += drink.standardDrinks;
        }
        
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
              child: Row(
                children: [
                  Text(
                    dateStr,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Container(
                      height: 1,
                      color: Colors.grey[300],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${dayDrinks.length} drinks • ${totalStandardDrinks.toStringAsFixed(1)} standard',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            ...dayDrinks.map((drink) => Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: DrinkCard(
                drink: drink,
                onDelete: () async {
                  final drinkProvider = Provider.of<DrinkProvider>(context, listen: false);
                  await drinkProvider.deleteDrink(drink.id);
                  _loadDrinkHistory();
                },
              ),
            )),
          ],
        );
      },
    );
  }
  
  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final yesterday = DateTime(now.year, now.month, now.day - 1);
    final today = DateTime(now.year, now.month, now.day);
    
    if (date == today) {
      return 'Today';
    } else if (date == yesterday) {
      return 'Yesterday';
    }
    
    return DateFormat.MMMEd().format(date);
  }
  
  // Calculate drinking days in the given time period
  int _calculateDrinkingDays(List<Drink> drinks) {
    if (drinks.isEmpty) return 0;
    
    final daysWithDrinks = groupBy(drinks, (Drink drink) {
      final date = drink.timestamp;
      return DateTime(date.year, date.month, date.day);
    });
    
    return daysWithDrinks.length;
  }
  
  // Calculate average drinks per drinking session
  double _calculateAvgDrinksPerSession(List<Drink> drinks) {
    if (drinks.isEmpty) return 0;
    
    // Group by day to identify drinking sessions
    final daysWithDrinks = groupBy(drinks, (Drink drink) {
      final date = drink.timestamp;
      return DateTime(date.year, date.month, date.day);
    });
    
    // Calculate standard drinks per session
    double totalStandardDrinks = 0;
    for (var drink in drinks) {
      totalStandardDrinks += drink.standardDrinks;
    }
    
    return totalStandardDrinks / daysWithDrinks.length;
  }
  
  // Get the most active drinking day of week
  String _getMostActiveDrinkingDay(List<Drink> drinks) {
    if (drinks.isEmpty) return 'N/A';
    
    // Group drinks by day of week
    final drinksByDayOfWeek = groupBy(drinks, (Drink drink) {
      return drink.timestamp.weekday;
    });
    
    // Count total drinks per day of week
    Map<int, int> drinksCountByDay = {};
    for (var entry in drinksByDayOfWeek.entries) {
      drinksCountByDay[entry.key] = entry.value.length;
    }
    
    // Find the day with the most drinks
    int? maxDay;
    int maxCount = 0;
    
    drinksCountByDay.forEach((day, count) {
      if (count > maxCount) {
        maxCount = count;
        maxDay = day;
      }
    });
    
    if (maxDay == null) return 'N/A';
    
    // Convert weekday number to name
    switch (maxDay) {
      case 1: return 'Monday';
      case 2: return 'Tuesday';
      case 3: return 'Wednesday';
      case 4: return 'Thursday';
      case 5: return 'Friday';
      case 6: return 'Saturday';
      case 7: return 'Sunday';
      default: return 'N/A';
    }
  }
  
  // Build weekly drinks chart
  Widget _buildWeeklyChart() {
    // Get last 7 days
    final now = DateTime.now();
    final dates = List.generate(7, (index) {
      return DateTime(now.year, now.month, now.day - index);
    }).reversed.toList();
    
    // Group drinks by day
    final drinksByDay = groupBy(_pastWeekDrinks, (Drink drink) {
      final date = drink.timestamp;
      return DateTime(date.year, date.month, date.day);
    });
    
    // Prepare chart data
    final List<FlSpot> spots = [];
    
    for (int i = 0; i < dates.length; i++) {
      final date = dates[i];
      final dayDrinks = drinksByDay[date] ?? [];
      
      double totalStandardDrinks = 0;
      for (var drink in dayDrinks) {
        totalStandardDrinks += drink.standardDrinks;
      }
      
      spots.add(FlSpot(i.toDouble(), totalStandardDrinks));
    }
    
    return LineChart(
      LineChartData(
        gridData: FlGridData(
          show: true,
          drawVerticalLine: true,
          horizontalInterval: 1,
          verticalInterval: 1,
        ),
        titlesData: FlTitlesData(
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                final int index = value.toInt();
                if (index >= 0 && index < dates.length) {
                  final date = dates[index];
                  return Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Text(
                      DateFormat('E').format(date),
                      style: const TextStyle(fontSize: 10),
                    ),
                  );
                }
                return const Text('');
              },
              reservedSize: 30,
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                return Text(
                  value.toInt().toString(),
                  style: const TextStyle(fontSize: 10),
                );
              },
              reservedSize: 30,
            ),
          ),
        ),
        borderData: FlBorderData(show: true),
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            color: Theme.of(context).colorScheme.primary,
            barWidth: 3,
            isStrokeCapRound: true,
            dotData: const FlDotData(show: true),
            belowBarData: BarAreaData(
              show: true,
              color: Theme.of(context).colorScheme.primary.withOpacity(0.2),
            ),
          ),
        ],
      ),
    );
  }
  
  // Build drink types pie chart
  Widget _buildDrinkTypesChart() {
    // Group by drink type
    final drinksByType = groupBy(_pastMonthDrinks, (Drink drink) {
      return drink.type;
    });
    
    // Calculate standard drinks by type
    Map<DrinkType, double> standardDrinksByType = {};
    
    drinksByType.forEach((type, drinks) {
      double total = 0;
      for (var drink in drinks) {
        total += drink.standardDrinks;
      }
      standardDrinksByType[type] = total;
    });
    
    // Prepare chart data
    final List<PieChartSectionData> sections = [];
    
    standardDrinksByType.forEach((type, value) {
      sections.add(
        PieChartSectionData(
          value: value,
          title: '${value.toStringAsFixed(1)}',
          color: _getDrinkTypeColor(type),
          radius: 80,
          titleStyle: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 12,
          ),
        ),
      );
    });
    
    // Handle empty data
    if (sections.isEmpty) {
      return const Center(
        child: Text('No drink data available'),
      );
    }
    
    return Row(
      children: [
        Expanded(
          child: PieChart(
            PieChartData(
              sections: sections,
              centerSpaceRadius: 0,
              sectionsSpace: 2,
            ),
          ),
        ),
        const SizedBox(width: 16),
        Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: standardDrinksByType.entries.map((entry) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 4.0),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 16,
                    height: 16,
                    decoration: BoxDecoration(
                      color: _getDrinkTypeColor(entry.key),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _getDrinkTypeName(entry.key),
                    style: const TextStyle(fontSize: 12),
                  ),
                ],
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
  
  Color _getDrinkTypeColor(DrinkType type) {
    switch (type) {
      case DrinkType.beer:
        return Colors.amber;
      case DrinkType.wine:
        return Colors.purple;
      case DrinkType.liquor:
        return Colors.blue;
      case DrinkType.cocktail:
        return Colors.green;
      case DrinkType.custom:
        return Colors.orange;
    }
  }
  
  String _getDrinkTypeName(DrinkType type) {
    switch (type) {
      case DrinkType.beer:
        return 'Beer';
      case DrinkType.wine:
        return 'Wine';
      case DrinkType.liquor:
        return 'Liquor';
      case DrinkType.cocktail:
        return 'Cocktail';
      case DrinkType.custom:
        return 'Custom';
    }
  }
}

extension StringExtension on String {
  String capitalize() {
    return "${this[0].toUpperCase()}${substring(1)}";
  }
}