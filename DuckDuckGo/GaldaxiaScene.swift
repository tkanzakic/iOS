//
//  GaldaxiaScene.swift
//  DuckDuckGo
//
//  Created by Christopher Brind on 19/09/2020.
//  Copyright © 2020 DuckDuckGo. All rights reserved.
//

import SpriteKit

class GaldaxiaScene: SKScene {

    let collisionBulletCategory: UInt32  = 0x1 << 0
    let collisionEnemyCategory: UInt32 = 0x1 << 1

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
        addEnemies()

        physicsWorld.contactDelegate = self

    }

    private func addEnemies() {

        let enemy = SKSpriteNode(imageNamed: "PP Network Icon facebook")
        enemy.position = CGPoint(x: 200, y: 200)
        enemy.run(.fadeIn(withDuration: 0.3))
        addChild(enemy)

        enemy.physicsBody = SKPhysicsBody(circleOfRadius: enemy.size.width / 2)
        enemy.physicsBody?.isDynamic = true
        enemy.physicsBody?.affectedByGravity = false
        enemy.physicsBody?.categoryBitMask = collisionEnemyCategory
        enemy.physicsBody?.contactTestBitMask = collisionBulletCategory
        enemy.physicsBody?.collisionBitMask = 0x0
        enemy.physicsBody?.usesPreciseCollisionDetection = true

    }

    private func addTouchZone() {
        let touchZone = TappableShapeNode(rect: CGRect(x: 0, y: 0, width: frame.width, height: daxSize + (daxSize / 2)))
        touchZone.tapped = {
            self.moveDax(to: $0.location(in: self))
        }
        addChild(touchZone)
    }

    private func moveDax(to position: CGPoint) {
        let x = position.x

        let distance = abs(dax.position.x - x)
        let duration = TimeInterval(distance / frame.width * 0.5)

        dax.removeAllActions()

        dax.run(SKAction.moveTo(x: x, duration: duration)) {
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

        let bullet = SKShapeNode(circleOfRadius: 6)
        bullet.position = position
        bullet.position.y += 5
        bullet.fillColor = .red

        let rocket = SKLabelNode(text: "🚀")
        rocket.zRotation = CGFloat(GLKMathDegreesToRadians(45))
        rocket.position = CGPoint(x: 7, y: -24)
        bullet.addChild(rocket)

        insertChild(bullet, at: 0)

        bullet.run(.moveTo(y: frame.height + 25, duration: 1.0)) {
            bullet.removeFromParent()
        }

        bullet.physicsBody = SKPhysicsBody(circleOfRadius: 6, center: CGPoint(x: 0.5, y: 0.5))
        bullet.physicsBody?.isDynamic = true
        bullet.physicsBody?.affectedByGravity = false
        bullet.physicsBody?.categoryBitMask = collisionBulletCategory
        bullet.physicsBody?.contactTestBitMask = collisionEnemyCategory
        bullet.physicsBody?.collisionBitMask = 0x0;
        bullet.physicsBody?.usesPreciseCollisionDetection = true

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

extension GaldaxiaScene: SKPhysicsContactDelegate {

    func didBegin(_ contact: SKPhysicsContact) {

        let explosionPosition = contact.bodyA.categoryBitMask == collisionEnemyCategory ?
                contact.bodyA.node?.position : contact.bodyB.node?.position

        contact.bodyA.node?.removeFromParent()
        contact.bodyB.node?.removeFromParent()

        score += 1

        if let explosionPosition = explosionPosition,
           let emitter = SKEmitterNode(fileNamed: "GaldaxiaExplosion") {
            emitter.position = explosionPosition
            emitter.run(.sequence([.wait(forDuration: 1.5), .removeFromParent()]))
            addChild(emitter)
        }

    }

}
