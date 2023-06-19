//
//  SceneDelegate.swift
//  BackgroundNotification
//
//  Created by 渡邉昇 on 2023/06/18.
//

import UIKit
import BackgroundTasks

// サンプル用のOperation
class PrintOperation: Operation {
    let id: Int

    init(id: Int) {
        self.id = id
    }

    override func main() {
        print("this operation id is \(self.id)")
    }
}

class SceneDelegate: UIResponder, UIWindowSceneDelegate {

    var window: UIWindow?


    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        // Use this method to optionally configure and attach the UIWindow `window` to the provided UIWindowScene `scene`.
        // If using a storyboard, the `window` property will automatically be initialized and attached to the scene.
        // This delegate does not imply the connecting scene or session are new (see `application:configurationForConnectingSceneSession` instead).
        
        // 第一引数: Info.plistで定義したIdentifierを指定
        // 第二引数: タスクを実行するキューを指定。nilの場合は、デフォルトのバックグラウンドキューが利用されます。
        // 第三引数: 実行する処理
        BGTaskScheduler.shared.register(forTaskWithIdentifier: "com.test.test.refresh", using: nil) { task in
            // バックグラウンド処理したい内容 ※後述します
            self.handleAppProcessing(task: task as! BGProcessingTask)
        }
        
        guard let _ = (scene as? UIWindowScene) else { return }
    }
    
    private func scheduleAppProcessing() {
        // Info.plistで定義したIdentifierを指定
        let request = BGProcessingTaskRequest(identifier: "com.test.test.refresh")
        // 通信が発生するか否かを指定
        request.requiresNetworkConnectivity = false
        // CPU監視の必要可否を設定
        request.requiresExternalPower = true

        do {
            // スケジューラーに実行リクエストを登録
            try BGTaskScheduler.shared.submit(request)
        } catch {
            print("Could not schedule app processing: \(error)")
        }
    }
    
    private func handleAppProcessing(task: BGProcessingTask) {
        // 1日の間、何度も実行したい場合は、1回実行するごとに新たにスケジューリングに登録します
        // scheduleAppRefresh()

        let queue = OperationQueue()
        queue.maxConcurrentOperationCount = 1

        // 時間内に実行完了しなかった場合は、処理を解放します
        // バックグラウンドで実行する処理は、次回に回しても問題ない処理のはずなので、これでOK
        task.expirationHandler = {
            queue.cancelAllOperations()
        }

        // サンプルの処理をキューに詰めます
        let array = [1, 2, 3, 4, 5]
        array.enumerated().forEach { arg in
            let (offset, value) = arg
            let operation = PrintOperation(id: value)
            if offset == array.count - 1 {
                operation.completionBlock = {
                    // 最後の処理が完了したら、必ず完了したことを伝える必要があります
                    task.setTaskCompleted(success: operation.isFinished)
                }
            }
            queue.addOperation(operation)
        }
    }

    func sceneDidDisconnect(_ scene: UIScene) {
        // Called as the scene is being released by the system.
        // This occurs shortly after the scene enters the background, or when its session is discarded.
        // Release any resources associated with this scene that can be re-created the next time the scene connects.
        // The scene may re-connect later, as its session was not necessarily discarded (see `application:didDiscardSceneSessions` instead).
        print("Detected: sceneDidDisconnect")
        scheduleAppProcessing()
    }

    func sceneDidBecomeActive(_ scene: UIScene) {
        // Called when the scene has moved from an inactive state to an active state.
        // Use this method to restart any tasks that were paused (or not yet started) when the scene was inactive.
        print("Detected: sceneDidBecomeActive")
    }

    func sceneWillResignActive(_ scene: UIScene) {
        // Called when the scene will move from an active state to an inactive state.
        // This may occur due to temporary interruptions (ex. an incoming phone call).
        print("Detected: sceneWillResignActive")
    }

    func sceneWillEnterForeground(_ scene: UIScene) {
        // Called as the scene transitions from the background to the foreground.
        // Use this method to undo the changes made on entering the background.
        print("Detected: sceneWillEnterForeground")
    }

    func sceneDidEnterBackground(_ scene: UIScene) {
        // Called as the scene transitions from the foreground to the background.
        // Use this method to save data, release shared resources, and store enough scene-specific state information
        // to restore the scene back to its current state.
        print("Detected: sceneDidEnterBackground")
    }


}

