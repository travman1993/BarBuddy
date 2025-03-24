#if os(watchOS)
import SwiftUI

struct DashboardView: View {
    @EnvironmentObject var drinkTracker: DrinkTracker
    
    var body: some View {
        VStack(spacing: 8) {
            Text("BAC")
                .font(.caption2)
                .foregroundColor(.gray)
            
            Text(String(format: "%.3f", drinkTracker.currentBAC))
                .font(.system(size: 34, weight: .bold))
                .foregroundColor(bacColor)
            
            Text(safetyStatus)
                .font(.caption)
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background(bacColor.opacity(0.3))
                .cornerRadius(4)
        }
        .padding()
    }
    
    var bacColor: Color {
        if drinkTracker.currentBAC < 0.04 {
            return .green
        } else if drinkTracker.currentBAC < 0.08 {
            return .yellow
        } else {
            return .red
        }
    }
    
    var safetyStatus: String {
        if drinkTracker.currentBAC < 0.04 {
            return "Safe to Drive"
        } else if drinkTracker.currentBAC < 0.08 {
            return "Borderline"
        } else {
            return "DO NOT DRIVE"
        }
    }
}
#endif
