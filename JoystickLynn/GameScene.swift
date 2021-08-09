//
//  GameScene.swift
//  JoystickLynn
//
//  Created by Waldi Febrianda on 05/08/21.
//

import SpriteKit
import GameplayKit

class GameScene: SKScene {
    
    // Sknodes
    var player : SKNode?
    var joystick : SKNode?
    var joystickKnob : SKNode?
    var halangan1: SKSpriteNode?
    
    
    // Joystick Boolean
    var joystickAction = false
    
    // Measure
    var knobRadius : CGFloat = 50.0
    
    //Sprite Engine
    var previousTimeInterval : TimeInterval = 0
    var playerFacingRight = true
    let playerSpeed = 4.0
    
    //Player State
    var playerState : GKStateMachine!
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        fatalError("init(coder:) has not been implemented")
        
    }

    
    
    override init(size: CGSize) {
        
       super.init(size: size)
        
        halangan1!.position = CGPoint(x: 500, y: 500)
        halangan1!.anchorPoint = CGPoint(x: 0.5, y: 0.5)
        halangan1!.color = .red
        addChild(halangan1!)
    }
    
 
    
    
    // Didmove
    override func didMove(to view: SKView) {
        
        physicsWorld.contactDelegate = self
        
        player = childNode(withName: "player")
        joystick = childNode(withName: "joystick")
        joystickKnob = joystick?.childNode(withName: "knob")
        
        playerState = GKStateMachine(states: [
            JumpingState(playerNode: player!),
            WalkingState(playerNode: player!),
            IdleState(playerNode: player!),
            LandingState(playerNode: player!),
            StunnedState(playerNode: player!),
        ])
        
        
        
        
        
        
        
    }
}

// Mark: Touche

extension GameScene {
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        for touch in touches {
            if let joystickKnob = joystickKnob {
                let location = touch.location(in: joystick!)
                joystickAction = joystickKnob.frame.contains(location)
            }
            

        }
        
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let joystick = joystick else { return}
        guard let joystickKnob = joystickKnob else { return }
        
        if !joystickAction { return}
        
        for touch in touches {
            let position = touch.location(in: joystick)
            
            let length = sqrt(pow(position.y, 2) + pow(position.x, 2))
            let angle = atan2(position.y, position.x)
            
            if knobRadius > length {
                joystickKnob.position = position
            } else  {
                joystickKnob.position = CGPoint(x: cos(angle) * knobRadius, y: sin(angle) * knobRadius)
            }
        }
    }
    
    // MARK: Handle joystick release touch
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        for touch in touches {
            let xJoystickCoordinate = touch.location(in: joystick!).x
            let xLimit : CGFloat = 400.0
            if xJoystickCoordinate > -xLimit && xJoystickCoordinate < xLimit {
                resetKnobPosition()
            }
        }
    }
    
}
extension GameScene {
    func resetKnobPosition() {
        let initialPoint = CGPoint(x: 0, y: 0)
        let moveBack = SKAction.move(to: initialPoint, duration: 0.1)
        moveBack.timingMode = .linear
        joystickKnob?.run(moveBack)
        joystickAction = false
        
    }
}

extension GameScene {
    override func update(_ currentTime: TimeInterval) {
        
        let deltaTime = currentTime - previousTimeInterval
        previousTimeInterval = currentTime
        
        guard let joystickKnob = joystickKnob else {return}
        
        let xPosition = Double(joystickKnob.position.x)
        let yPosition = Double(joystickKnob.position.y)
        let displacement = CGVector(dx: deltaTime * xPosition * playerSpeed, dy: deltaTime * yPosition * playerSpeed)

        let move = SKAction.move(by: displacement, duration: 0)

        player?.run(move)
    }
}

extension GameScene : SKPhysicsContactDelegate {
    
    struct Collision {
        enum Masks: Int{
            case killing, player, reward
            var bitmask: UInt32 { return 1 << self.rawValue }
        }
        
        let masks: (first: UInt32, second: UInt32)
        
        func matches ( first: Masks, second: Masks) -> Bool{
            return (first.bitmask == masks.first && second.bitmask == masks.second) || (first.bitmask == masks.second && second.bitmask == masks.first)
        }
    }
    
    func didBegin(_ contact: SKPhysicsContact) {
        
        let collision = Collision(masks: (first: contact.bodyA.categoryBitMask, second: contact.bodyB.categoryBitMask))
    
        if collision.matches(first: .player, second: .killing) {
            let die = SKAction.move(to: CGPoint(x: -1078.696, y: 296.704), duration: 0.0)
            player?.run(die)
        }
        
        if collision.matches(first: .player, second: .reward){
            
            if contact.bodyA.node?.name == "toxics" {
                contact.bodyA.node?.physicsBody?.categoryBitMask = 0
                contact.bodyA.node?.removeFromParent()
                
            } else if contact.bodyB.node?.name == "toxics" {
                contact.bodyB.node?.physicsBody?.categoryBitMask = 0
                
            }
            
        }
        
    }
}
