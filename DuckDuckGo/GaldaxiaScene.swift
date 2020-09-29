//
//  GaldaxiaScene.swift
//  DuckDuckGo
//
//  Created by Christopher Brind on 19/09/2020.
//  Copyright © 2020 DuckDuckGo. All rights reserved.
//

import SpriteKit

class GaldaxiaScene: SKScene {

    enum MovePhase: String {

        case right
        case rightDown
        case left
        case leftDown

    }

    struct C {
        static let collisionBulletCategory: UInt32  = 0x1 << 0
        static let collisionEnemyCategory: UInt32 = 0x1 << 1
        static let collisionWallCategory: UInt32 = 0x1 << 2
        static let daxSize: CGFloat = 50
        static let enemyName = "enemy"
        static let width: CGFloat = 320
        static let height: CGFloat = 568
        static let rightMovement = CGVector(dx: 50, dy: 0)
        static let leftMovement = CGVector(dx: -50, dy: 0)
        static let downMovement = CGVector(dx: 0, dy: -50)
        static let noMovement = CGVector(dx: 0, dy: 0)
    }

    static func create(onExit: @escaping () -> Void) -> SKScene {
        // Use iPhone SE (1st Gen) resolution
        let scene = GaldaxiaScene(size: CGSize(width: C.width, height: C.height))
        scene.backgroundColor = UIColor.white
        scene.scaleMode = .aspectFit
        scene.onExit = onExit
        return scene
    }

    let scoreboard = SKLabelNode(text: "")
    let dax = SKSpriteNode(imageNamed: "Logo")
    let closeButton = TappableShapeNode(rectOf: CGSize(width: 80, height: 32), cornerRadius: 8)

    var movePhase: MovePhase = .leftDown {
        didSet {
            switch movePhase {

            case .left:
                movement = C.leftMovement

            case .leftDown, .rightDown:
                movement = C.noMovement
                moveEnemiesDown()

            case .right:
                movement = C.rightMovement

            }
        }
    }

    var movement = C.noMovement {
        didSet {
            print("***", #function, movement)
            enumerateChildNodes(withName: C.enemyName) { node, stop in
                node.physicsBody?.velocity = self.movement
            }
        }
    }

    var score: Int = 0 {
        didSet {
            updateScore()
        }
    }

    var onExit: (() -> Void)?

    override func didMove(to view: SKView) {
        super.didMove(to: view)

        print("***", #function, self.frame, self.frame.midX)

        view.showsPhysics = true

        addScoreboard()
        addCloseButton()
        addDax()
        addTouchZone()
        addBoundary()

        run(.sequence([
            .wait(forDuration: 3.0),
            .run {
                self.addEnemies()
            }
        ]))

        physicsWorld.contactDelegate = self

    }

    private func addBoundary() {
        physicsBody = SKPhysicsBody(edgeLoopFrom: CGRect(x: 0, y: 0, width: C.width, height: C.height))
        physicsBody?.isDynamic = true
        physicsBody?.affectedByGravity = false
        physicsBody?.categoryBitMask = C.collisionWallCategory
        physicsBody?.contactTestBitMask = C.collisionEnemyCategory
        physicsBody?.collisionBitMask = 0x0
        physicsBody?.usesPreciseCollisionDetection = true
    }

    private func addEnemy(atPoint point: CGPoint, named: String) {

        let enemy = SKSpriteNode(imageNamed: named)
        enemy.position = point
        enemy.run(.fadeIn(withDuration: 0.3))
        enemy.name = C.enemyName
        enemy.physicsBody = SKPhysicsBody(circleOfRadius: enemy.size.width / 2)
        enemy.physicsBody?.isDynamic = true
        enemy.physicsBody?.affectedByGravity = false
        enemy.physicsBody?.categoryBitMask = C.collisionEnemyCategory
        enemy.physicsBody?.contactTestBitMask = C.collisionBulletCategory | C.collisionWallCategory
        enemy.physicsBody?.collisionBitMask = 0x0
        enemy.physicsBody?.usesPreciseCollisionDetection = true

        addChild(enemy)
    }

    private func changeEnemyMovement() {
        print("***", #function)

        switch movePhase {

        case .rightDown:
            movePhase = .left

        case .left:
            movePhase = .leftDown

        case .leftDown:
            movePhase = .right

        case .right:
            movePhase = .rightDown

        }

    }

    private func moveEnemiesDown() {
        enumerateChildNodes(withName: C.enemyName) { node, stop in
            node.run(.moveBy(x: 0, y: -20, duration: 0.3))
        }

        run(.sequence([
            .wait(forDuration: 0.3),
            .run {
                self.changeEnemyMovement()
            }
        ]))
    }

    private func addEnemies() {

        let names = [
            "PP Network Icon facebook",
            "PP Network Icon twitter",
            "PP Network Icon amazon",
            "PP Network Icon outbrain",
            "PP Network Icon adtech",
            "PP Network Icon adobe",
            "PP Network Icon google",
            "PP Network Icon appnexus",
            "PP Network Icon comscore",
            "PP Network Icon aol",
            "PP Network Icon newrelic",
            "PP Network Icon nielsen",
            "PP Network Icon yandex",
        ].shuffled()

        for x in 0 ..< 8 {

            for y in 0 ..< 5 {

                let point = CGPoint(x: (x * 35) + 20, y: (y * 30) + 375)
                let name = names[y]

                print("***", #function, y, name)

                addEnemy(atPoint: point, named: name)

            }
        }

        movePhase = .right

    }

    private func addTouchZone() {
        let rect = CGRect(x: 0, y: 0, width: C.width, height: C.daxSize + (C.daxSize / 2))
        let touchZone = TappableShapeNode(rect: rect)
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
        dax.size = CGSize(width: C.daxSize, height: C.daxSize)
        dax.position = CGPoint(x: frame.midX, y: C.daxSize)
        addChild(dax)
    }

    private func updateScore() {
        scoreboard.text = "Score: \(score)"
    }

    private func fire(from position: CGPoint) {

        let bullet = SKShapeNode(circleOfRadius: 4)
        bullet.position = position
        bullet.position.y += 12
        bullet.fillColor = .red

        let rocket = SKLabelNode(text: "🚀")
        rocket.zRotation = CGFloat(GLKMathDegreesToRadians(45))
        rocket.position = CGPoint(x: 7, y: -24)
        bullet.addChild(rocket)

        insertChild(bullet, at: 0)

        bullet.run(.moveTo(y: frame.height + 25, duration: 1.0)) {
            bullet.removeFromParent()
        }

        bullet.physicsBody = SKPhysicsBody(circleOfRadius: 4, center: CGPoint(x: 0.5, y: 0.5))
        bullet.physicsBody?.isDynamic = true
        bullet.physicsBody?.affectedByGravity = false
        bullet.physicsBody?.categoryBitMask = C.collisionBulletCategory
        bullet.physicsBody?.contactTestBitMask = C.collisionEnemyCategory
        bullet.physicsBody?.collisionBitMask = 0x0;
        bullet.physicsBody?.usesPreciseCollisionDetection = true

    }

}

extension GaldaxiaScene: SKPhysicsContactDelegate {

    func didBegin(_ contact: SKPhysicsContact) {

        print("***", #function)

        if enemyHitsWall(contact) {

            if !enemiesAreMovingDown() {
                handleBoundaryCollision()
            }

        } else {

            handleEnemyCollision(contact)

        }

    }

    private func enemiesAreMovingDown() -> Bool {
        print("***", #function, movePhase)
        return movePhase == .leftDown || movePhase == .rightDown
    }

    private func enemyHitsWall(_ contact: SKPhysicsContact) -> Bool {
        return (contact.bodyA.categoryBitMask == C.collisionWallCategory
                || contact.bodyB.categoryBitMask == C.collisionWallCategory)
            && (contact.bodyA.node?.name == C.enemyName
                || contact.bodyB.node?.name == C.enemyName)
    }

    private func handleBoundaryCollision() {
        print("***", #function)

        changeEnemyMovement()

    }

    private func handleEnemyCollision(_ contact: SKPhysicsContact) {
        print("***", #function)

        let explosionPosition = contact.bodyA.categoryBitMask == C.collisionEnemyCategory ?
                contact.bodyA.node?.position : contact.bodyB.node?.position

        contact.bodyA.node?.removeFromParent()
        contact.bodyB.node?.removeFromParent()

        if let explosionPosition = explosionPosition,
           let emitter = SKEmitterNode(fileNamed: "GaldaxiaExplosion") {
            score += 1

            emitter.position = explosionPosition
            emitter.run(.sequence([.wait(forDuration: 1.5), .removeFromParent()]))
            addChild(emitter)

            var remaining = 0
            enumerateChildNodes(withName: C.enemyName) { node, stop in
                remaining += 1
            }

            if remaining == 0 {
                addEnemies()
            }

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
        print("***", #function)
        guard let touch = touches.first else { return }
        tapped?(touch)
    }

}
