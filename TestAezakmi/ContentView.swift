//
//  ContentView.swift
//  TestAezakmi
//
//  Created by dsm 5e on 18.04.2025.
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        MainTabView()
    }
}

#Preview {
    ContentView()
        .environmentObject(AppStateManager())
}
