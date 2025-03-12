import SwiftUI

struct HomeView: View {
    @EnvironmentObject private var userViewModel: UserViewModel
    @EnvironmentObject private var drinkViewModel: DrinkViewModel
    @EnvironmentObject private var bacViewModel: BACViewModel
    @EnvironmentObject private var settingsViewModel: SettingsViewModel
    
    @State private var showingAddDrinkSheet = false
    @State private var showingEmergencySheet = false
    @State private var showingRideOptionsSheet = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: Constants.UI.standardPadding) {
                    // BAC Display
                    BACDisplayView(bacEstimate: bacViewModel.currentBAC)
                        .padding(.horizontal)
                    
                    // Quick Actions
                    HStack(spacing: Constants.UI.smallPadding) {
                        // Get a Ride Button
                        ActionButton(
                            title: "Get a Ride",
                            systemImage: "car.fill",
                            backgroundColor: Color.blue
                        ) {
                            showingRideOptionsSheet = true
                        }
                        
                        // Check In Button
                        ActionButton(
                            title: "Check In",
                            systemImage: "checkmark.circle.fill",
                            backgroundColor: Color.green
                        ) {
                            // Show check in options
                        }
                    }
                    .padding(.horizontal)
                    
                    // Emergency Button
                    if settingsViewModel.settings.showEmergencyButtonOnHomeScreen {
                        Button {
                            showingEmergencySheet = true
                        } label: {
                            HStack {
                                Image(systemName: "exclamationmark.triangle.fill")
                                Text(Constants.Strings.emergencyButtonText)
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.red)
                            .foregroundColor(.white)
                            .cornerRadius(Constants.UI.cornerRadius)
                        }
                        .padding(.horizontal)
                    }
                    
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
                            EmptyDrinksView {
                                showingAddDrinkSheet = true
                            }
                            .padding()
                        } else {
                            // List recent drinks
                            ForEach(drinkViewModel.recentDrinks.prefix(3)) { drink in
                                DrinkRowView(drink: drink) {
                                    Task {
                                        await drinkViewModel.deleteDrink(id: drink.id)
                                        await bacViewModel.calculateBAC()
                                    }
                                }
                                .padding(.horizontal)
                            }
                        }
                    }
                    
                    Spacer()
                }
                .padding(.vertical)
            }
            .navigationTitle("BarBuddy")
            .refreshable {
                Task {
                    await drinkViewModel.loadRecentDrinks(userId: userViewModel.currentUser.id)
                    await bacViewModel.calculateBAC()
                }
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showingAddDrinkSheet = true
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.title2)
                    }
                }
            }
            .sheet(isPresented: $showingAddDrinkSheet) {
                AddDrinkView()
            }
            .sheet(isPresented: $showingEmergencySheet) {
                EmergencyContactsView()
            }
            .sheet(isPresented: $showingRideOptionsSheet) {
                RideOptionsView()
            }
        }
    }
}

// Supporting Views
struct ActionButton: View {
    let title: String
    let systemImage: String
    let backgroundColor: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack {
                Image(systemName: systemImage)
                    .font(.title2)
                Text(title)
                    .font(.caption)
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(backgroundColor)
            .foregroundColor(.white)
            .cornerRadius(Constants.UI.cornerRadius)
        }
    }
}

struct EmptyDrinksView: View {
    let addDrinkAction: () -> Void
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "wineglass")
                .font(.system(size: 50))
                .foregroundColor(.gray)
            
            Text("No drinks logged yet")
                .font(.headline)
            
            Button("Add Your First Drink", action: addDrinkAction)
                .padding()
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(Constants.UI.cornerRadius)
        }
        .frame(maxWidth: .infinity)
        .padding()
    }
}

struct HomeView_Previews: PreviewProvider {
    static var previews: some View {
        HomeView()
            .environmentObject(UserViewModel())
            .environmentObject(DrinkViewModel())
            .environmentObject(BACViewModel())
            .environmentObject(SettingsViewModel())
    }
}
