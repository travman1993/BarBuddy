//
//  RideOptionsView.swift
//  BarBuddy
//
//  Created by Travis Rodriguez on 3/12/25.
//

import SwiftUI
import MapKit

struct RideOptionsView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel = RideOptionsViewModel()
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: Constants.UI.standardPadding) {
                    // Location section
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("Your Location")
                                .font(.headline)
                            
                            Spacer()
                            
                            Button {
                                viewModel.refreshLocation()
                            } label: {
                                Image(systemName: "arrow.clockwise")
                                    .foregroundColor(.blue)
                            }
                        }
                        
                        if viewModel.isLoading {
                            HStack {
                                Spacer()
                                ProgressView("Determining location...")
                                Spacer()
                            }
                            .padding()
                            .background(Color(.secondarySystemBackground))
                            .cornerRadius(Constants.UI.cornerRadius)
                        } else if let location = viewModel.currentLocation {
                            // Map view
                            MapView(coordinate: location)
                                .frame(height: 150)
                                .cornerRadius(Constants.UI.cornerRadius)
                                .padding(.bottom, 4)
                            
                            Text(viewModel.currentAddress)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        } else {
                            Text("Unable to determine location")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                .padding()
                                .frame(maxWidth: .infinity, alignment: .center)
                                .background(Color(.secondarySystemBackground))
                                .cornerRadius(Constants.UI.cornerRadius)
                        }
                    }
                    .padding(.horizontal)
                    
                    // Ride services
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Available Ride Services")
                            .font(.headline)
                            .padding(.horizontal)
                        
                        if viewModel.isLoading {
                            ProgressView()
                                .padding()
                                .frame(maxWidth: .infinity)
                                .background(Color(.secondarySystemBackground))
                                .cornerRadius(Constants.UI.cornerRadius)
                                .padding(.horizontal)
                        } else {
                            ForEach(viewModel.rideOptions) { option in
                                RideOptionRow(option: option) {
                                    handleRideSelection(option)
                                }
                            }
                            .padding(.horizontal)
                        }
                    }
                    
                    // Alternative options
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Other Options")
                            .font(.headline)
                            .padding(.horizontal)
                        
                        AlternativeTransportRow(
                            title: "Call a Taxi",
                            description: "Local taxi service",
                            icon: "taxi.fill",
                            action: {
                                viewModel.callTaxi()
                            }
                        )
                        .padding(.horizontal)
                        
                        AlternativeTransportRow(
                            title: "Call a Friend",
                            description: "Ask a friend for a ride",
                            icon: "phone.fill",
                            action: {
                                callFriend()
                            }
                        )
                        .padding(.horizontal)
                        
                        AlternativeTransportRow(
                            title: "Public Transportation",
                            description: "Find bus or train routes",
                            icon: "bus.fill",
                            action: {
                                openMaps()
                            }
                        )
                        .padding(.horizontal)
                    }
                    
                    // Safety reminder
                    Text("Remember: Never drive under the influence of alcohol. Always plan a safe ride home.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding()
                }
                .padding(.vertical)
            }
            .navigationTitle("Get a Ride")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Close") {
                        dismiss()
                    }
                }
            }
            .onAppear {
                viewModel.refreshLocation()
            }
            .alert(item: $viewModel.error) { error in
                Alert(
                    title: Text("Error"),
                    message: Text(error.message),
                    dismissButton: .default(Text("OK"))
                )
            }
        }
    }
    
    private func handleRideSelection(_ option: RideOptionsViewModel.RideOption) {
        if option.isInstalled {
            viewModel.openRideApp(option: option)
        } else if let appStoreURL = option.appStoreURL {
            UIApplication.shared.open(appStoreURL)
        }
    }
    
    private func callFriend() {
        // Open contacts app
        if let url = URL(string: "tel://") {
            UIApplication.shared.open(url)
        }
    }
    
    private func openMaps() {
        // Open Maps app with transit option
        if let location = viewModel.currentLocation {
            let mapItem = MKMapItem(placemark: MKPlacemark(coordinate: location))
            mapItem.name = "Current Location"
            mapItem.openInMaps(launchOptions: [MKLaunchOptionsDirectionsModeKey: MKLaunchOptionsDirectionsModeTransit])
        } else {
            // Just open Maps app
            if let url = URL(string: "maps://") {
                UIApplication.shared.open(url)
            }
        }
    }
}

struct MapView: UIViewRepresentable {
    let coordinate: CLLocationCoordinate2D
    
    func makeUIView(context: Context) -> MKMapView {
        let mapView = MKMapView()
        mapView.showsUserLocation = true
        mapView.delegate = context.coordinator
        return mapView
    }
    
    func updateUIView(_ uiView: MKMapView, context: Context) {
        let region = MKCoordinateRegion(
            center: coordinate,
            span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
        )
        uiView.setRegion(region, animated: true)
        
        // Add annotation
        let annotation = MKPointAnnotation()
        annotation.coordinate = coordinate
        annotation.title = "Your Location"
        
        uiView.removeAnnotations(uiView.annotations)
        uiView.addAnnotation(annotation)
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, MKMapViewDelegate {
        var parent: MapView
        
        init(_ parent: MapView) {
            self.parent = parent
        }
        
        func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
            if annotation is MKUserLocation {
                return nil
            }
            
            let identifier = "Location"
            var annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: identifier)
            
            if annotationView == nil {
                annotationView = MKMarkerAnnotationView(annotation: annotation, reuseIdentifier: identifier)
                annotationView?.canShowCallout = true
            } else {
                annotationView?.annotation = annotation
            }
            
            return annotationView
        }
    }
}

struct RideOptionRow: View {
    let option: RideOptionsViewModel.RideOption
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                // Icon
                Image(option.icon)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 40, height: 40)
                    .background(Color.white)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                
                // Details
                VStack(alignment: .leading, spacing: 2) {
                    Text(option.name)
                        .font(.headline)
                    
                    HStack {
                        if let price = option.estimatedPrice {
                            Text(price)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        
                        if let time = option.estimatedTime {
                            Text("• \(time)")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                
                Spacer()
                
                // Call to action
                VStack(alignment: .trailing) {
                    Text(option.isInstalled ? "Open" : "Get")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(option.isInstalled ? Color.blue : Color.green)
                        .cornerRadius(16)
                }
            }
            .padding()
            .background(Color(.secondarySystemBackground))
            .cornerRadius(Constants.UI.cornerRadius)
            .contentShape(Rectangle())
        }
    }
}

struct AlternativeTransportRow: View {
    let title: String
    let description: String
    let icon: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                // Icon
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(.blue)
                    .frame(width: 40, height: 40)
                    .background(Color.blue.opacity(0.1))
                    .clipShape(Circle())
                
                // Details
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.headline)
                    
                    Text(description)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .foregroundColor(.gray)
            }
            .padding()
            .background(Color(.secondarySystemBackground))
            .cornerRadius(Constants.UI.cornerRadius)
            .contentShape(Rectangle())
        }
    }
}

struct RideOptionsView_Previews: PreviewProvider {
    static var previews: some View {
        RideOptionsView()
    }
}
