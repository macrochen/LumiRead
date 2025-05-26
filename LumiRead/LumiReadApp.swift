//
//  LumiReadApp.swift
//  LumiRead
//
//  Created by jolin on 2025/5/26.
//

import SwiftUI

@main
struct LumiReadApp: App {
    let persistenceController = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}
