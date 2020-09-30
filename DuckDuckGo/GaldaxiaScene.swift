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
        static let collisionDaxCategory: UInt32 = 0x1 << 3

        static let daxSize: CGFloat = 50
        static let enemyName = "enemy"
        static let width: CGFloat = 320
        static let height: CGFloat = 568
        static let rightMovement = CGVector(dx: 50, dy: 0)
        static let leftMovement = CGVector(dx: -50, dy: 0)
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
    let touchZone = TappableShapeNode(rect: CGRect(x: 0, y: 0, width: C.width, height: C.daxSize + (C.daxSize / 2)))

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
        addTouchZone()
        addBoundary()

        physicsWorld.contactDelegate = self

        newGame(delay: 3)
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
        enemy.physicsBody?.contactTestBitMask =
            C.collisionBulletCategory | C.collisionWallCategory | C.collisionDaxCategory
        enemy.physicsBody?.collisionBitMask = 0x0
        enemy.physicsBody?.usesPreciseCollisionDetection = true

        addChild(enemy)

        enemy.alpha = 0.0
        enemy.run(.fadeIn(withDuration: 0.3))
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
            node.run(.sequence([
                .moveBy(x: 0, y: -24, duration: 0.3),
                .run {
                    if node.position.y < 0 {
                        node.removeFromParent()
                        self.replenishEnemies()
                    }
                }
            ]))
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

    private func replenishEnemies() {
        var remaining = 0
        enumerateChildNodes(withName: C.enemyName) { node, stop in
            remaining += 1
        }

        if remaining == 0 {
            addEnemies()
        }
    }

    private func addTouchZone() {
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
        let closeButton = TappableShapeNode(rectOf: CGSize(width: 80, height: 32), cornerRadius: 8)

        let label = SKLabelNode(text: "Close")
        label.fontName = "Proxima Nova Medium"
        label.fontSize = 16
        label.fontColor = .white
        label.verticalAlignmentMode = .center

        closeButton.fillColor = .cornflowerBlue
        closeButton.addChild(label)
        label.position.y -= 2
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
        dax.zRotation = 0
        dax.physicsBody = SKPhysicsBody(circleOfRadius: C.daxSize / 2)
        dax.physicsBody?.isDynamic = true
        dax.physicsBody?.affectedByGravity = false
        dax.physicsBody?.categoryBitMask = C.collisionDaxCategory
        dax.physicsBody?.contactTestBitMask = C.collisionEnemyCategory
        dax.physicsBody?.collisionBitMask = 0x0
        dax.physicsBody?.usesPreciseCollisionDetection = true
        dax.alpha = 0.0

        insertChild(dax, at: 0)

        dax.run(.sequence([ .fadeIn(withDuration: 0.3),
                            .rotate(toAngle: CGFloat(GLKMathDegreesToRadians(90)), duration: 0.3) ]))
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

        if daxCollision(contact) {

            handleDaxCollision(contact)

        } else if boundaryCollision(contact) {

            if !enemiesAreMovingDown() {
                handleBoundaryCollision()
            }

        } else if bulletCollision(contact) {

            handleEnemyCollision(contact)

        }

    }

    private func bulletCollision(_ contact: SKPhysicsContact) -> Bool {
        let categories = [
            contact.bodyA.categoryBitMask,
            contact.bodyB.categoryBitMask
        ]
        return categories.contains(C.collisionBulletCategory)
    }

    private func handleDaxCollision(_ contact: SKPhysicsContact) {
        print("***", #function)

        touchZone.tapped = nil

        enumerateChildNodes(withName: C.enemyName) { node, stop in
            node.removeAllActions()
            node.run(.sequence([.fadeOut(withDuration: 1), .removeFromParent()]))
        }

        let x = CGFloat.random(in: 0 ... C.width)
        let y = CGFloat(C.height + 100)
        let angle = Double.random(in: -360 ... 360)
        let radians = CGFloat(angle * Double.pi / 180)
        print("***", #function, x, y, angle, radians)

        dax.physicsBody?.categoryBitMask = 0x0
        dax.run(.group([
            .repeatForever(.rotate(byAngle: radians, duration: 1)),
            .move(to: CGPoint(x: x, y: y), duration: 2)
        ]))

        showGameOver()
    }

    private func showGameOver() {

        let label = SKLabelNode(text: "Game Over!")
        label.fontName = "Proxima Nova Extrabold"
        label.fontSize = 24
        label.fontColor = .cornflowerBlue
        label.verticalAlignmentMode = .center
        label.position = CGPoint(x: frame.midX, y: frame.midY + 30)
        label.alpha = 0.0
        addChild(label)
        label.run(.fadeIn(withDuration: 1))

        let playAgain = SKLabelNode(text: "Play Again")
        playAgain.fontName = "Proxima Nova Semibold"
        playAgain.fontSize = 16
        playAgain.fontColor = .white
        playAgain.verticalAlignmentMode = .center

        let button = TappableShapeNode(rectOf: CGSize(width: 100, height: 40), cornerRadius: 8)
        button.fillColor = .cornflowerBlue
        button.addChild(playAgain)
        playAgain.position.y -= 2
        button.position = CGPoint(x: frame.midX, y: frame.midY - 30)
        button.tapped = { _ in
            label.removeFromParent()
            button.removeFromParent()
            self.newGame(delay: 1)
        }

        addChild(button)

    }

    private func newGame(delay: TimeInterval) {
        score = 0

        dax.removeFromParent()
        dax.removeAllActions()

        run(.sequence([
            .wait(forDuration: delay),
            .run {
                self.addDax()
                self.touchZone.tapped = {
                    self.moveDax(to: $0.location(in: self))
                }
            },
            .wait(forDuration: 0.4),
            .run {
                self.addEnemies()
            }
        ]))

    }

    private func daxCollision(_ contact: SKPhysicsContact) -> Bool {
        let categories = [
            contact.bodyA.categoryBitMask,
            contact.bodyB.categoryBitMask
        ]
        return categories.contains(C.collisionDaxCategory)
    }

    private func enemiesAreMovingDown() -> Bool {
        print("***", #function, movePhase)
        return movePhase == .leftDown || movePhase == .rightDown
    }

    private func boundaryCollision(_ contact: SKPhysicsContact) -> Bool {
        let categories = [
            contact.bodyA.categoryBitMask,
            contact.bodyB.categoryBitMask
        ]
        return categories.contains(C.collisionWallCategory)
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

            replenishEnemies()
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
