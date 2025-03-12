import SwiftUI

struct DrinkLogView: View {
    @EnvironmentObject private var userViewModel: UserViewModel
    @EnvironmentObject private var drinkViewModel: DrinkViewModel
    @EnvironmentObject private var bacViewModel: BACViewModel
    
    @State private var showingAddDrinkSheet = false
    @State private var showingQuickAddSheet = false
    @State private var isRefreshing = false
    
    var body: some View {
        ScrollView {
            VStack(spacing: Constants.UI.standardPadding) {
                // BAC Display
                BACDisplayView(bacEstimate: bacViewModel.currentBAC)
                    .padding(.horizontal)
                
                // Quick Add Button
                Button {
                    showingQuickAddSheet = true
                } label: {
                    HStack {
                        Image(systemName: "plus.circle.fill")
                        Text("Quick Add Drink")
                    }
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(Constants.UI.cornerRadius)
                }
                .padding(.horizontal)
                
                // Recent Drinks Section
                VStack(alignment: .leading) {
                    HStack {
                        Text("Recent Drinks")
                            .font(.headline)
                        
                        Spacer()
                        
                        NavigationLink(destination: HistoryView()) {
                            Text("See All")
                                .font(.subheadline)
                                .foregroundColor(.blue)
                        }
                    }
                    .padding(.horizontal)
                    
                    if drinkViewModel.isLoading {
                        ProgressView()
                            .frame(maxWidth: .infinity, alignment: .center)
                            .padding()
                    } else if drinkViewModel.recentDrinks.isEmpty {
                        EmptyDrinkLog {
                            showingAddDrinkSheet = true
                        }
                        .padding()
                    } else {
                        // List recent drinks
                        ForEach(drinkViewModel.recentDrinks.prefix(5)) { drink in
                            NavigationLink(destination: DrinkDetailView(drink: drink)) {
                                DrinkRowView(drink: drink) {
                                    Task {
                                        await drinkViewModel.deleteDrink(id: drink.id)
                                        await bacViewModel.calculateBAC()
                                    }
                                }
                            }
                            .buttonStyle(PlainButtonStyle())
                            .padding(.horizontal)
                            
                            if drink != drinkViewModel.recentDrinks.prefix(5).last {
                                Divider()
                                    .padding(.leading, 60)
                                    .padding(.horizontal)
                            }
                        }
                    }
                }
                .padding(.vertical, 8)
                .background(Color(.secondarySystemBackground))
                .cornerRadius(Constants.UI.cornerRadius)
                .padding(.horizontal)
                
                // Contributing Drinks Summary
                if !bacViewModel.currentBAC.drinkIds.isEmpty && !drinkViewModel.recentDrinks.isEmpty {
                    BACContributingDrinksView(
                        bacEstimate: bacViewModel.currentBAC,
                        drinks: contributingDrinks
                    )
                    .padding(.horizontal)
                }
                
                // "Add Custom Drink" button at the bottom
                Button {
                    showingAddDrinkSheet = true
                } label: {
                    HStack {
                        Image(systemName: "square.and.pencil")
                        Text("Add Custom Drink")
                    }
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color(.tertiarySystemBackground))
                    .foregroundColor(.blue)
                    .cornerRadius(Constants.UI.cornerRadius)
                    .overlay(
                        RoundedRectangle(cornerRadius: Constants.UI.cornerRadius)
                            .stroke(Color.blue, lineWidth: 1)
                    )
                }
                .padding(.horizontal)
                .padding(.top, 8)
            }
            .padding(.vertical)
        }
        .navigationTitle("Drink Log")
        .refreshable {
            await refreshData()
        }
        .sheet(isPresented: $showingAddDrinkSheet) {
            AddDrinkView()
        }
        .sheet(isPresented: $showingQuickAddSheet) {
            QuickAddView()
        }
        .onAppear {
            if drinkViewModel.recentDrinks.isEmpty {
                Task {
                    await refreshData()
                }
            }
        }
    }
    
    private var contributingDrinks: [Drink] {
        return drinkViewModel.recentDrinks.filter { drink in
            bacViewModel.currentBAC.drinkIds.contains(drink.id)
        }
    }
    
    private func refreshData() async {
        isRefreshing = true
        
        await drinkViewModel.loadRecentDrinks(userId: userViewModel.currentUser.id)
        await bacViewModel.calculateBAC()
        
        isRefreshing = false
    }
}

struct BACContributingDrinksView: View {
    let bacEstimate: BACEstimate
    let drinks: [Drink]
    
    private var totalStandardDrinks: Double {
        drinks.reduce(0) { $0 + $1.standardDrinks }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Contributing to Your BAC")
                .font(.headline)
            
            Text("These drinks are currently affecting your BAC:")
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            HStack(spacing: 16) {
                // Count
                VStack {
                    Text("\(drinks.count)")
                        .font(.title)
                        .fontWeight(.bold)
                    
                    Text("Drinks")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Divider()
                
                // Standard drinks
                VStack {
                    Text(String(format: "%.1f", totalStandardDrinks))
                        .font(.title)
                        .fontWeight(.bold)
                    
                    Text("Standard")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Divider()
                
                // Time remaining
                VStack {
                    Text(bacEstimate.timeUntilSoberFormatted)
                        .font(.title)
                        .fontWeight(.bold)
                    
                    Text("Until Sober")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .padding()
            .background(Color(.tertiarySystemBackground))
            .cornerRadius(Constants.UI.cornerRadius)
            
            // Drink types distribution
            if !drinks.isEmpty {
                DrinkTypesDistribution(drinks: drinks)
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(Constants.UI.cornerRadius)
    }
}

struct DrinkTypesDistribution: View {
    let drinks: [Drink]
    
    private var groupedByType: [DrinkType: Int] {
        Dictionary(grouping: drinks, by: { $0.type })
            .mapValues { $0.count }
    }
    
    private var sortedTypes: [DrinkType] {
        groupedByType.keys.sorted { groupedByType[$0, default: 0] > groupedByType[$1, default: 0] }
    }
    
    private func calculatePercentage(_ count: Int) -> CGFloat {
        CGFloat(count) / CGFloat(drinks.count)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Drink Types")
                .font(.subheadline)
                .fontWeight(.semibold)
            
            ForEach(sortedTypes, id: \.self) { type in
                if let count = groupedByType[type] {
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Image(systemName: type.systemIconName)
                                .foregroundColor(.blue)
                            
                            Text(type.defaultName)
                                .font(.caption)
                            
                            Spacer()
                            
                            Text("\(count)")
                                .font(.caption)
                                .fontWeight(.semibold)
                        }
                        
                        // Distribution bar
                        GeometryReader { geometry in
                            Rectangle()
                                .fill(Color.blue)
                                .frame(width: geometry.size.width * calculatePercentage(count))
                                .cornerRadius(2)
                        }
                        .frame(height: 6)
                    }
                }
            }
        }
    }
}

struct EmptyDrinkLog: View {
    let action: () -> Void
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "mug.fill")
                .font(.system(size: 50))
                .foregroundColor(.gray)
            
            Text("No drinks logged yet")
                .font(.headline)
            
            Text("Add your first drink to start tracking your BAC")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            Button(action: action) {
                Text("Add Your First Drink")
                    .font(.headline)
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(Constants.UI.cornerRadius)
            }
        }
        .padding()
    }
}

struct DrinkLogView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            DrinkLogView()
                .environmentObject(UserViewModel())
                .environmentObject(DrinkViewModel())
                .environmentObject(BACViewModel())
        }
    }
}
