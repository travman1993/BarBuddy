import 'package:flutter/material.dart';
import 'dart:async';
import 'package:barbuddy/models/bac_model.dart';
import 'package:barbuddy/utils/constants.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';
import 'package:barbuddy/services/bac_calculator.dart';

class BACTimerWidget extends StatefulWidget {
  final BACEstimate bacEstimate;
  final Function() onRefresh;
  final bool showDetailedInfo;
  
  const BACTimerWidget({
    Key? key,
    required this.bacEstimate,
    required this.onRefresh,
    this.showDetailedInfo = false,
  }) : super(key: key);

  @override
  State<BACTimerWidget> createState() => _BACTimerWidgetState();
}

class _BACTimerWidgetState extends State<BACTimerWidget> {
  late Timer _timer;
  late BACEstimate _currentEstimate;
  int _remainingMinutes = 0;
  
  @override
  void initState() {
    super.initState();
    _currentEstimate = widget.bacEstimate;
    _calculateRemainingMinutes();
    
    // Set up timer to update every minute
    _timer = Timer.periodic(const Duration(minutes: 1), (_) {
      _calculateRemainingMinutes();
    });
  }
  
  @override
  void didUpdateWidget(BACTimerWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.bacEstimate != widget.bacEstimate) {
      _currentEstimate = widget.bacEstimate;
      _calculateRemainingMinutes();
    }
  }
  
  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }
  
  void _calculateRemainingMinutes() {
    setState(() {
      _remainingMinutes = _currentEstimate.minutesUntilLegal;
    });
  }
  
  Color _getBACColor(BACLevel level) {
    switch (level) {
      case BACLevel.safe:
        return kSafeBAC;
      case BACLevel.caution:
        return kCautionBAC;
      case BACLevel.warning:
      case BACLevel.danger:
        return kDangerBAC;
    }
  }
  
  double _getPercentage() {
    if (_currentEstimate.bac <= 0) return 0.0;
    if (_currentEstimate.bac >= 0.3) return 1.0; // Cap at 0.3 for display purposes
    
    return _currentEstimate.bac / 0.3;
  }
  
  @override
  Widget build(BuildContext context) {
    final Color bacColor = _getBACColor(_currentEstimate.level);
    
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(
              children: [
                Text(
                  'Current BAC',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.refresh),
                  onPressed: widget.onRefresh,
                  tooltip: 'Refresh BAC',
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                CircularPercentIndicator(
                  radius: 60.0,
                  lineWidth: 12.0,
                  percent: _getPercentage(),
                  center: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        _currentEstimate.bac.toStringAsFixed(3),
                        style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          color: bacColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '%',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                  progressColor: bacColor,
                  backgroundColor: bacColor.withOpacity(0.2),
                  animation: true,
                  animationDuration: 500,
                ),
                const SizedBox(width: 24),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _currentEstimate.timeUntilLegalFormatted,
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _currentEstimate.bac < kLegalDrivingLimit
                            ? 'Under legal limit'
                            : 'Until legal to drive',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        _currentEstimate.timeUntilSoberFormatted,
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Until completely sober',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (widget.showDetailedInfo) ...[
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 8),
              Text(
                _currentEstimate.advice,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              if (_currentEstimate.bac >= kLegalDrivingLimit) ...[
                const SizedBox(height: 16),
                Row(
                  children: [
                    const Icon(Icons.warning, color: kWarningColor),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'It is illegal to drive with a BAC at or above ${kLegalDrivingLimit.toStringAsFixed(2)}% in most states.',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: kWarningColor,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }
}