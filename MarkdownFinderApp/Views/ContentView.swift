import SwiftUI

public struct ContentView: View {
    @ObservedObject var state = AppState.shared

    public var body: some View {
        NavigationSplitView {
            List(SidebarTab.allCases, selection: $state.selectedTab) { tab in
                NavigationLink(value: tab) {
                    Label(tab.rawValue, systemImage: tab.systemIcon)
                }
            }
            .listStyle(.sidebar)
            .navigationSplitViewColumnWidth(min: 200, ideal: 220, max: 280)
            .navigationTitle("PeekMD")
        } detail: {
            Group {
                switch state.selectedTab {
                case .settings:
                    SettingsView()
                case .locations:
                    LocationsView()
                case .onboarding:
                    OnboardingView()
                case .viewer:
                    DocumentViewerView()
                }
            }
            .navigationTitle(state.selectedTab.rawValue)
        }
        .frame(minWidth: 860, minHeight: 560)
    }
}
