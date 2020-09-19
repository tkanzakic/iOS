//
//  GaldaxiaScene.swift
//  DuckDuckGo
//
//  Created by Christopher Brind on 19/09/2020.
//  Copyright © 2020 DuckDuckGo. All rights reserved.
//

import SpriteKit

class GaldaxiaScene: SKScene {

    static func create(onExit: @escaping () -> Void) -> SKScene {
        // Use iPhone SE (1st Gen) resolution
        let scene = GaldaxiaScene(size: CGSize(width: 320, height: 568))
        scene.backgroundColor = UIColor.white
        scene.scaleMode = .aspectFit
        scene.onExit = onExit
        return scene
    }

    let daxSize: CGFloat = 50
    let scoreboard = SKLabelNode(text: "")
    let dax = SKSpriteNode(imageNamed: "Logo")
    let closeButton = TappableShapeNode(rectOf: CGSize(width: 80, height: 32), cornerRadius: 8)

    var score: Int = 0 {
        didSet {
            updateScore()
        }
    }

    var onExit: (() -> Void)?

    override func didMove(to view: SKView) {
        super.didMove(to: view)

        print("***", #function, self.frame, self.frame.midX)

        addScoreboard()
        addCloseButton()
        addDax()
        addTouchZone()

    }

    private func addTouchZone() {
        let touchZone = TappableShapeNode(rect: CGRect(x: 0, y: 0, width: frame.width, height: daxSize + (daxSize / 2)))
        touchZone.tapped = {
            self.moveDax(to: $0.location(in: self))
        }
        addChild(touchZone)
    }

    private func moveDax(to position: CGPoint) {
        print("***", #function, position)

        let x = position.x

        let distance = abs(dax.position.x - x)
        let duration = TimeInterval(distance / frame.width * 0.5)

        print("***", #function, distance, duration)

        dax.removeAllActions()

        dax.run(SKAction.moveTo(x: x, duration: duration)) {
            print("*** move finished")
            self.fire(from: self.dax.position)
        }
    }

    private func addCloseButton() {

        let label = SKLabelNode(text: "[Exit]")
        label.fontName = "Proxima Nova Medium"
        label.fontSize = 18
        label.fontColor = .white
        label.verticalAlignmentMode = .center
        label.position = CGPoint(x: closeButton.frame.midX, y: closeButton.frame.midY - 2)

        closeButton.fillColor = .cornflowerBlue
        closeButton.addChild(label)
        closeButton.position = CGPoint(x: frame.width - 52, y: self.frame.height - 28)
        closeButton.tapped = { _ in self.onExit?() }

        addChild(closeButton)
    }

    private func addScoreboard() {
        scoreboard.position = CGPoint(x: 12, y: frame.height - 18)
        scoreboard.fontName = "Proxima Nova Semibold"
        scoreboard.fontSize = 18
        scoreboard.fontColor = .black
        scoreboard.horizontalAlignmentMode = .left
        scoreboard.verticalAlignmentMode = .top
        addChild(scoreboard)
        updateScore()
    }

    private func addDax() {
        dax.size = CGSize(width: daxSize, height: daxSize)
        dax.position = CGPoint(x: frame.midX, y: daxSize)
        addChild(dax)
    }

    private func updateScore() {
        scoreboard.text = "Score: \(score)"
    }

    private func fire(from position: CGPoint) {

        let bullet = SKLabelNode(text: "🚀")
        bullet.position = position
        bullet.position.x += 8
        bullet.zRotation = CGFloat(GLKMathDegreesToRadians(45))
        bullet.horizontalAlignmentMode = .center
        addChild(bullet)

        bullet.run(.moveTo(y: frame.height + 25, duration: 1.0)) {
            bullet.removeFromParent()
        }

    }

}

class TappableShapeNode: SKShapeNode {

    var tapped: ((UITouch) -> Void)?

    override init() {
        super.init()
        isUserInteractionEnabled = true
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        tapped?(touch)
    }

}
