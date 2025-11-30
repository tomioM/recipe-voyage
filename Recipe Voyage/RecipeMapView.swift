import SwiftUI
import MapKit

// MARK: - Recipe Map View
// Customized map showing recipe origin with progressive detail levels
// - World view: Shows only country borders and labels
// - Canada zoom: Shows provinces, territories, and cities

struct RecipeMapView: View {
    let latitude: Double?
    let longitude: Double?
    let locationName: String?
    
    @StateObject private var viewModel: MapViewModel
    
    init(latitude: Double?, longitude: Double?, locationName: String?) {
        self.latitude = latitude
        self.longitude = longitude
        self.locationName = locationName
        
        _viewModel = StateObject(wrappedValue: MapViewModel(
            latitude: latitude,
            longitude: longitude
        ))
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Map
            CustomMapView(viewModel: viewModel)
                .frame(height: 200)
                .cornerRadius(8)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                )
            
            // Zoom controls
            HStack(spacing: 16) {
                Button(action: { viewModel.zoomIn() }) {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 24))
                        .foregroundColor(.brown)
                }
                
                Button(action: { viewModel.zoomOut() }) {
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
}

// MARK: - Map View Model
// Manages map state and detail levels

class MapViewModel: NSObject, ObservableObject {
    @Published var region: MKCoordinateRegion
    @Published var showProvinceDetail = false
    
    let latitude: Double?
    let longitude: Double?
    let hasLocation: Bool
    
    init(latitude: Double?, longitude: Double?) {
        self.latitude = latitude
        self.longitude = longitude
        self.hasLocation = latitude != nil && longitude != nil
        
        // Initialize region
        if let lat = latitude, let lon = longitude {
            self.region = MKCoordinateRegion(
                center: CLLocationCoordinate2D(latitude: lat, longitude: lon),
                span: MKCoordinateSpan(latitudeDelta: 10, longitudeDelta: 10)
            )
        } else {
            // Default to Canada overview
            self.region = MKCoordinateRegion(
                center: CLLocationCoordinate2D(latitude: 56.1304, longitude: -106.3468),
                span: MKCoordinateSpan(latitudeDelta: 40, longitudeDelta: 60)
            )
        }
        
        super.init()
    }
    
    func updateDetailLevel() {
        let span = region.span.latitudeDelta
        
        // Show province detail when zoomed in (span < 20 degrees)
        // and focused on Canada region
        let isInCanada = isRegionInCanada()
        showProvinceDetail = span < 20 && isInCanada
    }
    
    private func isRegionInCanada() -> Bool {
        let lat = region.center.latitude
        let lon = region.center.longitude
        
        // Rough bounds for Canada
        return lat > 40 && lat < 85 && lon > -141 && lon < -52
    }
    
    func zoomIn() {
        withAnimation {
            region.span.latitudeDelta *= 0.5
            region.span.longitudeDelta *= 0.5
            updateDetailLevel()
        }
    }
    
    func zoomOut() {
        withAnimation {
            region.span.latitudeDelta = min(region.span.latitudeDelta * 2.0, 180)
            region.span.longitudeDelta = min(region.span.longitudeDelta * 2.0, 180)
            updateDetailLevel()
        }
    }
}

// MARK: - Custom Map View
// UIKit MapView wrapper with custom styling

struct CustomMapView: UIViewRepresentable {
    @ObservedObject var viewModel: MapViewModel
    
    func makeUIView(context: Context) -> MKMapView {
        let mapView = MKMapView()
        mapView.delegate = context.coordinator
        mapView.mapType = .standard
        mapView.showsCompass = false
        mapView.showsScale = true
        
        // Customize appearance for cleaner look
        mapView.pointOfInterestFilter = .excludingAll
        
        return mapView
    }
    
    func updateUIView(_ mapView: MKMapView, context: Context) {
        // Update region
        mapView.setRegion(viewModel.region, animated: true)
        
        // Clear existing overlays
        mapView.removeOverlays(mapView.overlays)
        
        // Add location pin if available
        mapView.removeAnnotations(mapView.annotations)
        if let lat = viewModel.latitude, let lon = viewModel.longitude {
            let annotation = MKPointAnnotation()
            annotation.coordinate = CLLocationCoordinate2D(latitude: lat, longitude: lon)
            mapView.addAnnotation(annotation)
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, MKMapViewDelegate {
        var parent: CustomMapView
        
        init(_ parent: CustomMapView) {
            self.parent = parent
        }
        
        // Handle region changes
        func mapView(_ mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
            DispatchQueue.main.async {
                self.parent.viewModel.region = mapView.region
                self.parent.viewModel.updateDetailLevel()
            }
        }
        
        // Customize annotation view (red pin)
        func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
            let identifier = "LocationPin"
            
            var annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: identifier)
            
            if annotationView == nil {
                annotationView = MKMarkerAnnotationView(annotation: annotation, reuseIdentifier: identifier)
                annotationView?.canShowCallout = false
            } else {
                annotationView?.annotation = annotation
            }
            
            if let markerView = annotationView as? MKMarkerAnnotationView {
                markerView.markerTintColor = .red
                markerView.glyphImage = nil
            }
            
            return annotationView
        }
    }
}

// MARK: - Preview

struct RecipeMapView_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 20) {
            // With location
            RecipeMapView(
                latitude: 45.4215, 
                longitude: -75.6972,
                locationName: "Ottawa, ON"
            )
            .padding()
            
            // Without location (default Canada view)
            RecipeMapView(
                latitude: nil,
                longitude: nil,
                locationName: nil
            )
            .padding()
        }
    }
}
