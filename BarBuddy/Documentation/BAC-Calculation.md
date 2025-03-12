# BAC Calculation in BarBuddy

This document explains how Blood Alcohol Content (BAC) is calculated in BarBuddy.

## The Widmark Formula

BarBuddy uses the Widmark formula, which is one of the most widely accepted methods for estimating BAC:

Where:
- **BAC** is the Blood Alcohol Concentration in percent
- **A** is the mass of alcohol consumed in grams
- **r** is the Widmark factor (body water constant)
- **W** is the body weight in grams

## Gender-Specific Factors

The Widmark factor (r) varies by gender:
- Male: 0.68
- Female: 0.55
- Other: 0.615 (average of male and female)

These values represent the proportion of body weight that is composed of water, where alcohol is distributed.

## Metabolism

The body metabolizes alcohol at a relatively constant rate. BarBuddy uses an average metabolism rate of 0.015% BAC per hour.

## Calculation Steps

1. **Convert drink volume to alcohol mass**:
   - Calculate pure alcohol in ounces: `amount × (alcoholPercentage / 100)`
   - Convert to grams: `alcohol_ounces × 29.57 × 0.79` (where 0.79 is the density of ethanol)

2. **Calculate initial BAC**:
   - Convert weight to grams: `weight_lbs × 453.592`
   - Apply Widmark formula: `(alcohol_grams / (weight_grams × gender_constant)) × 100`

3. **Account for metabolism over time**:
   - For each drink, subtract `0.015 × hours_since_drink` from its contribution
   - Sum the remaining alcohol from all drinks

4. **Calculate time until legal/sober**:
   - Time until legal: `(current_BAC - 0.08) / 0.015` hours (if BAC > 0.08)
   - Time until sober: `current_BAC / 0.015` hours

## Limitations

It's important to note that BAC calculation is an estimation and can be affected by many factors not accounted for in the formula:

- Individual metabolic variations
- Food consumption
- Medications
- Health conditions
- Fatigue
- Actual alcohol content of beverages (which may vary)

BarBuddy emphasizes that these are estimates and should not be used to determine if someone is fit to drive. The only safe amount of alcohol for driving is zero.

## References

1. Widmark, E.M.P. (1932). Die theoretischen Grundlagen und die praktische Verwendbarkeit der gerichtlich-medizinischen Alkoholbestimmung. Urban & Schwarzenberg, Berlin.
2. Jones, A.W. (2010). Evidence-based survey of the elimination rates of ethanol from blood with applications in forensic casework. Forensic Science International, 200(1-3), 1-20.
