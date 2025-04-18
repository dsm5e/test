import SwiftUI

struct MainTabView: View {
    @State private var selectedTab = 0
    
    var body: some View {
        TabView(selection: $selectedTab) {
            NavigationView {
                EditorView()
            }
            .tabItem {
                Label("Editor", systemImage: "pencil")
            }
            .tag(0)
            
            NavigationView {
                SettingsView()
            }
            .tabItem {
                Label("Settings", systemImage: "gear")
            }
            .tag(1)
        }
        .accentColor(.accentColorToken)
        .onAppear {
            let appearance = UITabBarAppearance()
            appearance.backgroundColor = UIColor(Color.backgroundColorToken)
            UITabBar.appearance().standardAppearance = appearance
            UITabBar.appearance().scrollEdgeAppearance = appearance
        }
    }
} 