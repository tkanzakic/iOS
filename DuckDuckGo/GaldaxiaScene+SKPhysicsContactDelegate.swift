//
//  GaldaxiaScene+SKPhysicsContactDelegate.swift
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

extension Galdaxia.Scene: SKPhysicsContactDelegate {

    func didBegin(_ contact: SKPhysicsContact) {

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
        return categories.contains(Galdaxia.Const.collisionBulletCategory)
    }

    private func handleDaxCollision(_ contact: SKPhysicsContact) {
        enumerateChildNodes(withName: Galdaxia.Const.enemyName) { node, _ in
            node.removeAllActions()
            node.run(.sequence([.fadeOut(withDuration: 1), .removeFromParent()]))
        }

        let x = CGFloat.random(in: 0 ... Galdaxia.Const.width)
        let y = CGFloat(Galdaxia.Const.height + 100)
        let angle = Double.random(in: -360 ... 360)
        let radians = CGFloat(angle * Double.pi / 180)

        dax.physicsBody?.categoryBitMask = 0x0
        dax.run(.group([
            .repeatForever(.rotate(byAngle: radians, duration: 1)),
            .move(to: CGPoint(x: x, y: y), duration: 2)
        ]))

        addExplosion(at: dax.position)

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

    func newGame(delay: TimeInterval) {
        score = 0
        level = 1

        dax.removeFromParent()
        dax.removeAllActions()

        run(.sequence([
            .wait(forDuration: delay),
            .run {
                self.addDax()
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
        return categories.contains(Galdaxia.Const.collisionDaxCategory)
    }

    private func enemiesAreMovingDown() -> Bool {
        switch movePhase {
        case .downLeft, .downRight: return true
        default: return false
        }
    }

    private func boundaryCollision(_ contact: SKPhysicsContact) -> Bool {
        let categories = [
            contact.bodyA.categoryBitMask,
            contact.bodyB.categoryBitMask
        ]
        return categories.contains(Galdaxia.Const.collisionWallCategory)
    }

    private func handleBoundaryCollision() {
        changeEnemyMovement()
    }

    private func handleEnemyCollision(_ contact: SKPhysicsContact) {
        let explosionPosition = contact.bodyA.categoryBitMask == Galdaxia.Const.collisionEnemyCategory ?
                contact.bodyA.node?.position : contact.bodyB.node?.position

        contact.bodyA.node?.removeFromParent()
        contact.bodyB.node?.removeFromParent()

        if let explosionPosition = explosionPosition {
            addExplosion(at: explosionPosition)
            score += 1
            replenishEnemies()
        }
    }

    private func addExplosion(at position: CGPoint) {
        guard let emitter = SKEmitterNode(fileNamed: "GaldaxiaExplosion") else { return }
        emitter.position = position
        emitter.run(.sequence([.wait(forDuration: 1.5), .removeFromParent()]))
        addChild(emitter)
    }

}
