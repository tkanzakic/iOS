//
//  GameViewController.swift
//  DuckDuckGo
//
//  Created by Christopher Brind on 19/09/2020.
//  Copyright © 2020 DuckDuckGo. All rights reserved.
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
        gameView.backgroundColor = .clear
        gameView.autoresizingMask = [ .flexibleWidth, .flexibleHeight ]
        gameView.presentScene(GaldaxiaScene.create(onExit: {
            controller.dismiss(animated: true)
        }))

        controller.view.addSubview(gameView)

        presentingViewController.present(controller, animated: true)
    }

}
