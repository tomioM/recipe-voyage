import SwiftUI
import MapKit

// MARK: - Recipe Map View
// Custom minimal map with maximum styling control

struct RecipeMapView: View {
    let latitude: Double?
    let longitude: Double?
    let locationName: String?
    
    @State private var region: MKCoordinateRegion
    
    init(latitude: Double?, longitude: Double?, locationName: String?) {
        self.latitude = latitude
        self.longitude = longitude
        self.locationName = locationName
        
        // Initialize region based on provided coordinates or default to Canada
        if let lat = latitude, let lon = longitude {
            _region = State(initialValue: MKCoordinateRegion(
                center: CLLocationCoordinate2D(latitude: lat, longitude: lon),
                span: MKCoordinateSpan(latitudeDelta: 10, longitudeDelta: 10)
            ))
        } else {
            // Default to showing Canada
            _region = State(initialValue: MKCoordinateRegion(
                center: CLLocationCoordinate2D(latitude: 56.1304, longitude: -106.3468),
                span: MKCoordinateSpan(latitudeDelta: 40, longitudeDelta: 60)
            ))
        }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Minimal styled map
            CustomMinimalMap(
                region: $region,
                latitude: latitude,
                longitude: longitude,
                locationName: locationName
            )
            .frame(height: 200)
            .cornerRadius(8)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color.gray.opacity(0.3), lineWidth: 1)
            )
            
            // Zoom controls
            HStack(spacing: 16) {
                Button(action: zoomIn) {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 24))
                        .foregroundColor(.brown)
                }
                
                Button(action: zoomOut) {
                    Image(systemName: "minus.circle.fill")
                        .font(.system(size: 24))
                        .foregroundColor(.brown)
                }
                
                Spacer()
                
                if let name = locationName {
                    Text(name)
                        .font(.custom("Georgia", size: 14))
                        .foregroundColor(.brown.opacity(0.8))
                }
            }
            .padding(.top, 8)
        }
    }
    
    private func zoomIn() {
        withAnimation {
            region.span.latitudeDelta *= 0.5
            region.span.longitudeDelta *= 0.5
        }
    }
    
    private func zoomOut() {
        withAnimation {
            region.span.latitudeDelta *= 2.0
            region.span.longitudeDelta *= 2.0
        }
    }
}

// MARK: - Custom Minimal Map
// Uses UIKit MKMapView with all available minimal styling

struct CustomMinimalMap: UIViewRepresentable {
    @Binding var region: MKCoordinateRegion
    let latitude: Double?
    let longitude: Double?
    let locationName: String?
    
    func makeUIView(context: Context) -> MKMapView {
        let mapView = MKMapView()
        mapView.delegate = context.coordinator
        
        // MAXIMUM MINIMAL STYLING
        // Unfortunately Apple limits how much we can customize
        
        // Use standard map (most minimal option available)
        mapView.mapType = .standard
        
        // Disable all extra features
        mapView.showsBuildings = false
        mapView.showsTraffic = false
        mapView.showsCompass = false
        mapView.showsScale = false
        mapView.showsUserLocation = false
        
        // Disable manual interaction (only zoom buttons work)
        mapView.isZoomEnabled = false
        mapView.isScrollEnabled = false
        mapView.isRotateEnabled = false
        mapView.isPitchEnabled = false
        
        // Apply the most minimal configuration available in iOS 16+
        if #available(iOS 16.0, *) {
            let config = MKStandardMapConfiguration(emphasisStyle: .muted)
            config.elevationStyle = .flat
            config.showsTraffic = false
            mapView.preferredConfiguration = config
        }
        
        // Alternative: Use mutedStandard for even more minimal appearance (iOS 17+)
        if #available(iOS 17.0, *) {
            // This is the most minimal style Apple provides
            mapView.preferredConfiguration = MKStandardMapConfiguration(emphasisStyle: .muted)
        }
        
        // Add pin if location exists
        if let lat = latitude, let lon = longitude {
            let annotation = MKPointAnnotation()
            annotation.coordinate = CLLocationCoordinate2D(latitude: lat, longitude: lon)
            annotation.title = locationName
            mapView.addAnnotation(annotation)
        }
        
        return mapView
    }
    
    func updateUIView(_ mapView: MKMapView, context: Context) {
        mapView.setRegion(region, animated: true)
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, MKMapViewDelegate {
        var parent: CustomMinimalMap
        
        init(_ parent: CustomMinimalMap) {
            self.parent = parent
        }
        
        func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
            let identifier = "MinimalPin"
            
            var annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: identifier)
            
            if annotationView == nil {
                annotationView = MKMarkerAnnotationView(annotation: annotation, reuseIdentifier: identifier)
                annotationView?.canShowCallout = true
            } else {
                annotationView?.annotation = annotation
            }
            
            // Minimal brown pin
            if let markerView = annotationView as? MKMarkerAnnotationView {
                markerView.markerTintColor = UIColor(red: 0.545, green: 0.271, blue: 0.075, alpha: 1.0)
                markerView.glyphImage = nil
                markerView.displayPriority = .required
            }
            
            return annotationView
        }
        
        func mapView(_ mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
            DispatchQueue.main.async {
                self.parent.region = mapView.region
            }
        }
    }
}

// MARK: - Preview

struct RecipeMapView_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 20) {
            Text("Apple MapKit has limited styling options.")
                .font(.caption)
                .foregroundColor(.gray)
            
            RecipeMapView(
                latitude: 45.4215,
                longitude: -75.6972,
                locationName: "Ottawa, ON"
            )
            .padding()
            
            RecipeMapView(
                latitude: nil,
                longitude: nil,
                locationName: nil
            )
            .padding()
            
            Text("For completely custom maps, you'd need to use external tile services or SVG.")
                .font(.caption)
                .foregroundColor(.gray)
                .padding()
        }
    }
}
