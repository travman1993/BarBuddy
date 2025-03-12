//
//  BACView.swift
//  BarBuddy
//
//  Created by Travis Rodriguez on 3/11/25.
//

import SwiftUI

struct WatchBACView: View {
    @EnvironmentObject private var bacViewModel: WatchBACViewModel
    @EnvironmentObject private var userViewModel: WatchUserViewModel
    
    @State private var isRefreshing = false
    
    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                // BAC Circle
                ZStack {
                    WatchBACCircleView(bac: bacViewModel.currentBAC.bac)
                    
                    if isRefreshing {
                        ProgressView()
                            .scaleEffect(0.8)
                    }
                }
                .padding(.vertical, 8)
                
                // Safety message
                if bacViewModel.currentBAC.bac > 0 {
                    Text(bacViewModel.currentBAC.advice)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .lineLimit(3)
                }
                
                // Time until legal / sober
                VStack(spacing: 12) {
                    // Time until legal
                    VStack(spacing: 4) {
                        Text(bacViewModel.currentBAC.timeUntilLegalFormatted)
                            .font(.body)
                            .fontWeight(.semibold)
                        
                        Text(bacViewModel.currentBAC.bac < Constants.BAC.legalLimit ? "Under legal limit" : "Until legal to drive")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                    
                    Divider()
                    
                    // Time until sober
                    VStack(spacing: 4) {
                        Text(bacViewModel.currentBAC.timeUntilSoberFormatted)
                            .font(.caption)
                            .fontWeight(.medium)
                        
                        Text("Until completely sober")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
                .padding(8)
                .background(Color(.secondarySystemBackground))
                .cornerRadius(8)
            }
            .padding()
        }
        .navigationTitle("BAC")
        .onAppear {
            refresh()
        }
        .onDisappear {
            isRefreshing = false
        }
        .refreshable {
            await refresh()
        }
    }
    
    private func refresh() {
        isRefreshing = true
        
        Task {
            await bacViewModel.refreshBAC()
            isRefreshing = false
        }
    }
}

struct WatchBACCircleView: View {
    let bac: Double
    
    var body: some View {
        ZStack {
            Circle()
                .stroke(
                    Color.forBACLevel(bac >= Constants.BAC.highThreshold ? .danger :
                                     bac >= Constants.BAC.legalLimit ? .warning :
                                     bac >= Constants.BAC.cautionThreshold ? .caution : .safe)
                        .opacity(0.3),
                    lineWidth: 8
                )
            
            Circle()
                .trim(from: 0, to: min(CGFloat(bac / 0.25), 1.0))
                .stroke(
                    Color.forBACLevel(bac >= Constants.BAC.highThreshold ? .danger :
                                     bac >= Constants.BAC.legalLimit ? .warning :
                                     bac >= Constants.BAC.cautionThreshold ? .caution : .safe),
                    style: StrokeStyle(lineWidth: 8, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
                .animation(.linear, value: bac)
            
            VStack(spacing: 0) {
                Text(bac.bacString)
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundColor(Color.forBACLevel(bac >= Constants.BAC.highThreshold ? .danger :
                                                      bac >= Constants.BAC.legalLimit ? .warning :
                                                      bac >= Constants.BAC.cautionThreshold ? .caution : .safe))
                
                Text("%")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
        .frame(width: 80, height: 80)
    }
}
struct WatchBACView_Previews: PreviewProvider {
    static var previews: some View {
        WatchBACView()
            .environmentObject(WatchBACViewModel.preview)
            .environmentObject(WatchUserViewModel.preview)
    }
}

struct WatchQuickAddView_Previews: PreviewProvider {
    static var previews: some View {
        WatchQuickAddView()
            .environmentObject(WatchDrinkViewModel.preview)
            .environmentObject(WatchUserViewModel.preview)
            .environmentObject(WatchBACViewModel.preview)
    }
}

struct WatchMainView_Previews: PreviewProvider {
    static var previews: some View {
        WatchMainView()
            .environmentObject(WatchBACViewModel.preview)
            .environmentObject(WatchDrinkViewModel.preview)
            .environmentObject(WatchUserViewModel.preview)
    }
}
