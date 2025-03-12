import SwiftUI

struct BACInfoView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Constants.UI.standardPadding) {
                // Header
                Text("Understanding Blood Alcohol Content (BAC)")
                    .font(.title)
                    .fontWeight(.bold)
                    .padding(.bottom, 8)
                
                // What is BAC section
                VStack(alignment: .leading, spacing: 8) {
                    Text("What is BAC?")
                        .font(.headline)
                    
                    Text("Blood Alcohol Content (BAC) is the percentage of alcohol in your bloodstream. For example, a BAC of 0.08% means that 0.08% of your bloodstream is alcohol.")
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding()
                .background(Color(.secondarySystemBackground))
                .cornerRadius(Constants.UI.cornerRadius)
                
                // BAC Levels section
                VStack(alignment: .leading, spacing: 8) {
                    Text("BAC Levels & Effects")
                        .font(.headline)
                    
                    BACLevelRow(
                        level: "0.020-0.039%",
                        effects: "Mild euphoria, relaxation, slight impairment in reasoning and memory",
                        color: .safeBAC
                    )
                    
                    BACLevelRow(
                        level: "0.040-0.059%",
                        effects: "Feeling of wellbeing, lower inhibitions, slight impairment of judgment",
                        color: .safeBAC
                    )
                    
                    BACLevelRow(
                        level: "0.060-0.079%",
                        effects: "Slight impairment of balance, speech, vision, and control",
                        color: .cautionBAC
                    )
                    
                    BACLevelRow(
                        level: "0.080-0.099%",
                        effects: "Legal intoxication in most states. Significant impairment of motor coordination and judgment",
                        color: .dangerBAC
                    )
                    
                    BACLevelRow(
                        level: "0.100-0.129%",
                        effects: "Clear deterioration of reaction time and control, slurred speech, poor coordination",
                        color: .dangerBAC
                    )
                    
                    BACLevelRow(
                        level: "0.130-0.159%",
                        effects: "Major impairment of physical and mental control, blurred vision, lack of balance",
                        color: .dangerBAC
                    )
                    
                    BACLevelRow(
                        level: "0.160-0.199%",
                        effects: "Dysphoria, nausea, disorientation, feeling confused or dazed",
                        color: .dangerBAC
                    )
                    
                    BACLevelRow(
                        level: "0.200-0.299%",
                        effects: "Needs assistance to walk, total mental confusion, blackout",
                        color: .dangerBAC
                    )
                    
                    BACLevelRow(
                        level: "0.300-0.399%",
                        effects: "Loss of consciousness, risk of alcohol poisoning and death",
                        color: .dangerBAC
                    )
                    
                    BACLevelRow(
                        level: "0.400%+",
                        effects: "Onset of coma, possible respiratory arrest and death",
                        color: .dangerBAC
                    )
                }
                .padding()
                .background(Color(.secondarySystemBackground))
                .cornerRadius(Constants.UI.cornerRadius)
                
                // How BAC is calculated
                VStack(alignment: .leading, spacing: 8) {
                    Text("How BAC is Calculated")
                        .font(.headline)
                    
                    Text("BarBuddy calculates BAC using the Widmark formula, which considers:")
                        .fixedSize(horizontal: false, vertical: true)
                    
                    BulletPointText(text: "Weight")
                    BulletPointText(text: "Gender")
                    BulletPointText(text: "Amount of alcohol consumed")
                    BulletPointText(text: "Time elapsed since consumption")
                    
                    Text("For more details on how BAC is calculated, check our documentation.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding()
                .background(Color(.secondarySystemBackground))
                .cornerRadius(Constants.UI.cornerRadius)
                
                // Disclaimer
                VStack(alignment: .leading, spacing: 8) {
                    Text("Disclaimer")
                        .font(.headline)
                    
                    Text(Constants.Strings.disclaimerText)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding()
                .background(Color(.secondarySystemBackground))
                .cornerRadius(Constants.UI.cornerRadius)
            }
            .padding()
        }
        .navigationTitle("BAC Information")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct BACLevelRow: View {
    let level: String
    let effects: String
    let color: Color
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Rectangle()
                .frame(width: 4, height: nil)
                .foregroundColor(color)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(level)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                
                Text(effects)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(.vertical, 4)
    }
}

struct BulletPointText: View {
    let text: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            Text("•")
                .font(.body)
            
            Text(text)
                .font(.body)
        }
    }
}

struct BACInfoView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            BACInfoView()
        }
    }
}
