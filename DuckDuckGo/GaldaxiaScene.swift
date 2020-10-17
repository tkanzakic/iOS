//
//  GaldaxiaScene.swift
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

import SpriteKit

struct Galdaxia {

    struct Const {
        static let collisionBulletCategory: UInt32  = 0x1 << 0
        static let collisionEnemyCategory: UInt32 = 0x1 << 1
        static let collisionWallCategory: UInt32 = 0x1 << 2
        static let collisionDaxCategory: UInt32 = 0x1 << 3
        static let collisionBombCategory: UInt32 = 0x1 << 4

        static let enemyName = "enemy"
        static let bombName = "bomb"

        static let daxSize: CGFloat = 50
        static let width: CGFloat = 320
        static let height: CGFloat = 568
        static let downDistance: CGFloat = 25

        static let minMovementSpeed: CGFloat = 25
        static let maxMovementSpeed: CGFloat = 100
    }

    enum MovePhase {

        case right
        case downRight(remaining: CGFloat)
        case left
        case downLeft(remaining: CGFloat)

    }

}

extension Galdaxia {

    class Scene: SKScene {

        let scoreboard = SKLabelNode(text: "")
        let dax = SKSpriteNode(imageNamed: "Logo")
        let touchZone = TappableShapeNode(rect: CGRect(x: 0, y: 0, width: Const.width, height: Const.daxSize + (Const.daxSize / 2)))

        var movePhase: MovePhase = .right
        var lastUpdate: TimeInterval = 0.0

        var level: CGFloat = 1

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

            newGame(delay: 1)
        }

        override func update(_ currentTime: TimeInterval) {
            super.update(currentTime)

            var bomb = shouldDropBomb()

            let diff = CGFloat(currentTime - lastUpdate)
            let speed = min(Const.minMovementSpeed + level, Const.maxMovementSpeed)
            let distance = min(speed * diff, speed)

            switch movePhase {
            case .downLeft(let remaining):
                if remaining > 0 {
                    movePhase = .downLeft(remaining: remaining - distance)
                } else {
                    movePhase = .right
                }

            case .downRight(let remaining):
                if remaining > 0 {
                    movePhase = .downRight(remaining: remaining - distance)
                } else {
                    movePhase = .left
                }

            default: break
            }

            enumerateChildNodes(withName: Const.enemyName) { node, _ in

                if bomb && Int.random(in: 0..<1000) == 0 {
                    bomb = false
                    self.dropBomb(from: node)
                }

                switch self.movePhase {
                case .right:
                    node.position.x += distance

                case .left:
                    node.position.x -= distance

                case .downLeft, .downRight:
                    node.position.y -= distance

                }
            }

            lastUpdate = currentTime
        }

        private func dropBomb(from node: SKNode) {
            guard node.alpha == 1 else { return }
            let bomb = BombNode(startingAt: node.position)
            addChild(bomb)
        }

        private func shouldDropBomb() -> Bool {
            var bombs: CGFloat = 0.0
            enumerateChildNodes(withName: Const.bombName) { _, _ in
                bombs += 1
            }
            return bombs + 1 < min(level, 3)
        }

        private func addBoundary() {
            physicsBody = SKPhysicsBody(edgeLoopFrom: CGRect(x: 0, y: 0, width: Const.width, height: Const.height))
            physicsBody?.applyStandardConfiguration()
            physicsBody?.categoryBitMask = Const.collisionWallCategory
            physicsBody?.contactTestBitMask = Const.collisionEnemyCategory
        }

        private func addEnemy(atPoint point: CGPoint, named name: String) {
            let enemy = EnemyNode(imageNamed: name, atStartingPoint: point)
            addChild(enemy)
        }

        func changeEnemyMovement() {
            print("***", #function)

            switch movePhase {

            case .downLeft:
                movePhase = .right

            case .downRight:
                movePhase = .left

            case .left:
                movePhase = .downLeft(remaining: Const.downDistance)

            case .right:
                movePhase = .downRight(remaining: Const.downDistance)

            }

        }

        func addEnemies() {

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
                "PP Network Icon yandex"
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

        func replenishEnemies() {
            var remaining = 0
            enumerateChildNodes(withName: Const.enemyName) { _, _ in
                remaining += 1
            }

            if remaining == 0 {
                addEnemies()
                level += 1
                showLevel()
            }
        }

        private func showLevel() {

            let label = SKLabelNode(text: "Level \(Int(level))")
            label.fontName = "Proxima Nova Extrabold"
            label.fontSize = 24
            label.fontColor = .cornflowerBlue
            label.verticalAlignmentMode = .center
            label.position = CGPoint(x: frame.midX, y: frame.midY + 30)
            label.alpha = 0.0
            addChild(label)
            label.run(.sequence([
                .fadeIn(withDuration: 1),
                .wait(forDuration: 0.3),
                .fadeOut(withDuration: 1),
                .removeFromParent()
            ]))
        }

        private func addTouchZone() {
            addChild(touchZone)
        }

        func moveDax(to position: CGPoint) {
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
            label.fontName = "Proxima Nova Semibold"
            label.fontSize = 16
            label.fontColor = .white
            label.verticalAlignmentMode = .center

            closeButton.fillColor = .cornflowerBlue
            closeButton.addChild(label)
            label.position.y -= 1
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

        func addDax() {
            dax.size = CGSize(width: Const.daxSize, height: Const.daxSize)
            dax.position = CGPoint(x: frame.midX, y: Const.daxSize)
            dax.zRotation = 0
            dax.physicsBody = SKPhysicsBody(circleOfRadius: Const.daxSize / 2)
            dax.physicsBody?.applyStandardConfiguration()
            dax.physicsBody?.categoryBitMask = Const.collisionDaxCategory
            dax.physicsBody?.contactTestBitMask = Const.collisionEnemyCategory
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
            bullet.physicsBody?.applyStandardConfiguration()
            bullet.physicsBody?.categoryBitMask = Const.collisionBulletCategory
            bullet.physicsBody?.contactTestBitMask = Const.collisionEnemyCategory

        }

    }

}

extension SKPhysicsBody {

    func applyStandardConfiguration() {
        isDynamic = true
        affectedByGravity = false
        collisionBitMask = 0x0
        usesPreciseCollisionDetection = true
    }

}
