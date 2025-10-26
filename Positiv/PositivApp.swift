//
//  PositivApp.swift
//  Positiv
//
//  Created by DnD-Luk on 23/10/2025.
//

import SwiftUI
import BackgroundTasks

@main
struct PositivApp: App {
    init() {
        BGTaskScheduler.shared.register(forTaskWithIdentifier: AppConfig.comBgArt, using: nil) { task in
            handleArtRefresh(task: task as! BGAppRefreshTask)
        }
    }

    var body: some Scene {
        WindowGroup {
            MainTabs()
                .task {
                    if ArtCache.load() == nil {
                        await ArtFetcher.fetchAndCache()
                    }
                    scheduleNextArtRefresh() // planifie le prochain run
                }
        }
    }
}

func handleArtRefresh(task: BGAppRefreshTask) {
    scheduleNextArtRefresh() // replanifier tout de suite pour la prochaine fois

    let op = Task {
        await ArtFetcher.fetchAndCache()
    }

    task.expirationHandler = {
        op.cancel()
    }

    Task {
        _ = await op.result
        task.setTaskCompleted(success: true)
    }
}

func scheduleNextArtRefresh() {
    let req = BGAppRefreshTaskRequest(identifier: AppConfig.comBgArt)
    req.earliestBeginDate = Date(timeIntervalSinceNow: 6*60*60) // ~6h
    do { try BGTaskScheduler.shared.submit(req) }
    catch { print("BG submit error:", error.localizedDescription) }
}
