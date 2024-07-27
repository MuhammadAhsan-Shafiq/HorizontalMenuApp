import SwiftUI

// Custom shape for rounded corners on the left side
struct RoundedLeftShape: Shape {
    var radius: CGFloat

    func path(in rect: CGRect) -> Path {
        var path = Path()
        let cornerRadius = radius

        // Top-left corner
        path.addArc(center: CGPoint(x: cornerRadius, y: cornerRadius),
                    radius: cornerRadius,
                    startAngle: .degrees(180),
                    endAngle: .degrees(270),
                    clockwise: false)

        // Top-right corner
        path.addLine(to: CGPoint(x: rect.width, y: 0))

        // Bottom-right corner
        path.addLine(to: CGPoint(x: rect.width, y: rect.height))

        // Bottom-left corner
        path.addArc(center: CGPoint(x: cornerRadius, y: rect.height - cornerRadius),
                    radius: cornerRadius,
                    startAngle: .degrees(90),
                    endAngle: .degrees(180),
                    clockwise: false)

        path.addLine(to: CGPoint(x: 0, y: cornerRadius))

        return path
    }
}

// Custom shape for rounded corners on the right side
struct RoundedRightShape: Shape {
    var radius: CGFloat

    func path(in rect: CGRect) -> Path {
        var path = Path()
        let cornerRadius = radius

        // Top-left corner
        path.move(to: CGPoint(x: 0, y: 0))
        path.addLine(to: CGPoint(x: rect.width - cornerRadius, y: 0))
        path.addArc(center: CGPoint(x: rect.width - cornerRadius, y: cornerRadius),
                    radius: cornerRadius,
                    startAngle: .degrees(270),
                    endAngle: .degrees(0),
                    clockwise: false)

        // Bottom-right corner
        path.addLine(to: CGPoint(x: rect.width, y: rect.height - cornerRadius))
        path.addArc(center: CGPoint(x: rect.width - cornerRadius, y: rect.height - cornerRadius),
                    radius: cornerRadius,
                    startAngle: .degrees(0),
                    endAngle: .degrees(90),
                    clockwise: false)

        path.addLine(to: CGPoint(x: 0, y: rect.height))
        path.addLine(to: CGPoint(x: 0, y: 0))

        return path
    }
}

// Observable object for managing menu items, selected item, and products
class MenuViewModel: ObservableObject {
    @Published var menuItems: [MenuItem] = []
    @Published var selectedItem: UUID? = nil
    @Published var selectedSubMenus: Set<String> = [] // Changed to Set for multiple selections

    // Sample products data
    @Published var products: [Product] = [
        Product(name: "Product 1", category: "Category 1", subCategory: "SubCategory 1-1"),
        Product(name: "Product 2", category: "Category 2", subCategory: "SubCategory 2-2"),
        Product(name: "Product 3", category: "Category 3", subCategory: "SubCategory 3-3"),
        Product(name: "Product 4", category: "Category 1", subCategory: "SubCategory 1-2"),
        Product(name: "Product 5", category: "Category 2", subCategory: "SubCategory 2-3")
    ]

    // Filtered products based on selected sub-menus
    var filteredProducts: [Product] {
        if !selectedSubMenus.isEmpty {
            return products.filter { selectedSubMenus.contains($0.subCategory) }
        } else {
            return []
        }
    }

    // Load menu data from JSON file
    func loadMenuData() {
        if let url = Bundle.main.url(forResource: "menuData", withExtension: "json"),
           let data = try? Data(contentsOf: url),
           let decodedData = try? JSONDecoder().decode([MenuItem].self, from: data) {
            self.menuItems = decodedData
        } else {
            print("Failed to load or decode JSON data.")
        }
    }
}

struct MenuItem: Identifiable, Codable, Equatable {
    let id = UUID()
    let title: String
    var subMenus: [String]

    static func == (lhs: MenuItem, rhs: MenuItem) -> Bool {
        return lhs.id == rhs.id
    }
}

struct Product: Identifiable {
    let id = UUID()
    let name: String
    let category: String
    let subCategory: String
}

import SwiftUI

struct ContentView: View {
    @StateObject private var viewModel = MenuViewModel()
    @State private var showFilteredProducts: Bool = false
    @State private var filteredMenuItem: UUID? = nil

    var body: some View {
        VStack(spacing: 0) {
            // Reset Button
            HStack {
                Spacer() // Push the button to the right
                Button(action: {
                    withAnimation {
                        viewModel.selectedSubMenus.removeAll() // Clear all sub-menu selections
                        showFilteredProducts = false // Hide filtered products
                        filteredMenuItem = nil // Remove the highlight from the main menu
                        viewModel.selectedItem = nil // Hide sub-menu
                    }
                    print("Filters reset")
                }) {
                    Text("Reset")
                        .font(.headline)
                        .foregroundColor(viewModel.selectedSubMenus.isEmpty ? .gray : .orange)
                }
                .disabled(viewModel.selectedSubMenus.isEmpty) // Disable button if no filters are applied
            }
            .padding()

            // Main Menu
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 16) {
                    ForEach(viewModel.menuItems.indices, id: \.self) { index in
                        let isSelected = viewModel.selectedItem == viewModel.menuItems[index].id || filteredMenuItem == viewModel.menuItems[index].id
                        Button(action: {
                            withAnimation(.spring()) {
                                if isSelected {
                                    viewModel.selectedItem = nil // Deselect if clicked again
                                    viewModel.selectedSubMenus.removeAll() // Clear all sub-menu selections
                                } else {
                                    viewModel.selectedItem = viewModel.menuItems[index].id // Select new item
                                    viewModel.selectedSubMenus.removeAll() // Clear previous sub-menu selections
                                    showFilteredProducts = false // Hide filtered products
                                }
                            }
                            print("\(viewModel.menuItems[index].title) clicked")
                        }) {
                            HStack(spacing: 4) { // Reduced spacing between text and arrow
                                Text(viewModel.menuItems[index].title)
                                    .font(.headline)
                                    .foregroundColor(isSelected ? .pink : .primary) // Use blue for selected, primary color otherwise
                                    .padding(.vertical, 12)
                                    .padding(.leading, 16) // Adjusted padding to ensure text and arrow fit well

                                Image(systemName: "arrowtriangle.down.fill")
                                    .rotationEffect(.degrees(isSelected ? 180 : 0))
                                    .foregroundColor(isSelected ? .pink : .primary) // Color the arrow to match the text
                                    .padding(.trailing, 8) // Added padding to the right of the arrowhead
                            }
                            .background(isSelected ? Color.pink.opacity(0.1) : Color.clear) // Light blue background for selected item
                            .overlay(
                                RoundedRectangle(cornerRadius: 30)
                                    .stroke(isSelected ? Color.pink : Color.clear, lineWidth: 2) // Blue border for selected item
                            )
                            .shadow(color: isSelected ? Color.blue.opacity(0.2) : Color.clear, radius: 5) // Shadow for selected item
                            .clipShape(RoundedRectangle(cornerRadius: 30))
                        }
                    }
                }
                .padding(.horizontal)
            }

            // Sub Menu and Filtered Products
            if let selectedItem = viewModel.selectedItem,
               let selectedItemIndex = viewModel.menuItems.firstIndex(where: { $0.id == selectedItem }) {
                VStack(spacing: 8) {
                    // Sub Menu
                    let columns = [GridItem(.flexible()), GridItem(.flexible())]
                    LazyVGrid(columns: columns, spacing: 16) {
                        ForEach(viewModel.menuItems[selectedItemIndex].subMenus, id: \.self) { subMenu in
                            let isSubMenuSelected = viewModel.selectedSubMenus.contains(subMenu)
                            Button(action: {
                                withAnimation {
                                    if isSubMenuSelected {
                                        viewModel.selectedSubMenus.remove(subMenu) // Deselect sub-menu
                                    } else {
                                        viewModel.selectedSubMenus.insert(subMenu) // Select sub-menu
                                    }
                                }
                                print("\(subMenu) clicked")
                            }) {
                                HStack(spacing: 4) { // Ensure no space between text and checkmark
                                    Text(subMenu)
                                        .font(.subheadline)
                                        .foregroundColor(isSubMenuSelected ? .orange : .primary)
                                    
                                    if isSubMenuSelected {
                                        Image(systemName: "checkmark")
                                            .foregroundColor(.orange)
                                    }
                                }
                                .padding()
                                .cornerRadius(8)
                            }
                            
                        }
                    }
                    .padding()
                    
                    // Continue and Cancel Buttons
                    if !viewModel.selectedSubMenus.isEmpty {
                        
                        // Continue and Cancel Buttons with Gradient Background
                        HStack(spacing: 0) { // Remove space between buttons
                            Button(action: {
                                withAnimation {
                                    showFilteredProducts = true // Show filtered products when continue is clicked
                                    filteredMenuItem = viewModel.selectedItem // Highlight the main menu that caused filtration
                                    viewModel.selectedItem = nil // Hide sub-menu
                                }
                                print("Continue with selected sub-menus")
                            }) {
                                Text("Continue")
                                    .font(.headline)
                                    .padding(.horizontal, 50)
                                    .foregroundColor(.white)
                                    .frame(height: 40)
                            }
                            
                            Button(action: {
                                withAnimation {
                                    viewModel.selectedSubMenus.removeAll() // Clear all sub-menu selections
                                    showFilteredProducts = false // Hide filtered products
                                    filteredMenuItem = nil // Remove the highlight from the main menu
                                    viewModel.selectedItem = nil // Hide sub-menu
                                }
                                print("Filters cancelled")
                            }) {
                                Text("Cancel")
                                    .font(.headline)
                                    .padding(.horizontal, 50)
                                    .foregroundColor(.white)
                                    .frame(height: 40)
                            }
                        }
                        .background(
                            LinearGradient(gradient: Gradient(colors: [Color.yellow, Color.orange.opacity(1.5)]), startPoint: .leading, endPoint: .trailing)
                                .clipShape(RoundedCornerShape(corners: [.topLeft, .bottomLeft, .topRight, .bottomRight], cornerRadius: 12))
                        )
                    }}}
            // Filtered Products
            if showFilteredProducts {
                VStack {
                    Text("Filtered Products")
                        .font(.title2)
                        .padding(.top, 16)

                    List(viewModel.filteredProducts) { product in
                        Text(product.name)
                    }
                }
                .padding(.horizontal)
            }

            Spacer()
        }
        .onAppear {
            viewModel.loadMenuData() // Load menu data on appear
        }
    }
}

// Custom Corner Radius Shape
struct RoundedCornerShape: Shape {
    var corners: UIRectCorner
    var cornerRadius: CGFloat

    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(roundedRect: rect, byRoundingCorners: corners, cornerRadii: CGSize(width: cornerRadius, height: cornerRadius))
        return Path(path.cgPath)
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
