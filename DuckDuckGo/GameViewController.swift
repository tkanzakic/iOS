//
//  GameViewController.swift
//  DuckDuckGo
//
//  Copyright © 2020 DuckDuckGo. All rights reserved.
//
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//  http://www.apache.org/licenses/LICENSE-2.0
//
//  Unless required by applicable law or agreed to in writing, software
//  distributed under the License is distributed on an "AS IS" BASIS,
//  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//  See the License for the specific language governing permissions and
//  limitations under the License.
//

import UIKit
import SpriteKit

class GameViewController: UIViewController {

    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return UIDevice.current.userInterfaceIdiom == .pad ? .all : [ .portrait, .portraitUpsideDown]
    }

    static func launch(over presentingViewController: UIViewController) {
        let controller = GameViewController()
        controller.modalPresentationStyle = .fullScreen

        let gameView = SKView(frame: controller.view.frame)
        gameView.autoresizingMask = [ .flexibleWidth, .flexibleHeight ]
        gameView.presentScene(Galdaxia.Scene.create(onExit: {
            gameView.scene?.isPaused = true
            gameView.scene?.physicsWorld.contactDelegate = nil
            gameView.scene?.removeFromParent()
            controller.dismiss(animated: true)
        }))

        controller.view.addSubview(gameView)

        presentingViewController.present(controller, animated: true)
    }

}

extension Galdaxia.Scene {

    static func create(onExit: @escaping () -> Void) -> SKScene {
        // Use iPhone SE (1st Gen) resolution
        let scene = Galdaxia.Scene(size: CGSize(width: Galdaxia.Const.width, height: Galdaxia.Const.height))
        scene.backgroundColor = UIColor.white
        scene.scaleMode = .aspectFit
        scene.onExit = {
            onExit()
            scene.onExit = nil
        }
        return scene
    }

}
