//
//  GameScene.swift
//  Super Wabbit Jump
//
//  Created by Jérémie ANACHE on 17/09/2017.
//  Copyright © 2017 Jérémie ANACHE. All rights reserved.
//

import SpriteKit
import GameplayKit

enum GameSceneState {
    case active, gameOver
}

class GameScene: SKScene, SKPhysicsContactDelegate {
    
    var entities = [GKEntity]()
    var graphs = [String : GKGraph]()
    var hero: SKSpriteNode!
    var scrollLayer: SKNode!
    var obstacleSource: SKNode!
    var obstacleLayer: SKNode!
    var scoreLabel: SKLabelNode!
    var sinceTouch : CFTimeInterval = 0
    var spawnTimer: CFTimeInterval = 0
    
    let fixedDelta: CFTimeInterval = 1.0 / 60.0 /* 60 FPS */
    let scrollSpeed: CGFloat = 100
    var points = 0
    
    /* Connections IU */
    var buttonRestart: MSButtonNode!
    
    /* Game management */
    var gameState: GameSceneState = .active
    
    private var lastUpdateTime : TimeInterval = 0
    private var label : SKLabelNode?
    private var spinnyNode : SKShapeNode?
    
    override func didMove(to view: SKView) {
        physicsWorld.contactDelegate = self
        /* Recherche recursive de node 'hero' (child of referenced node) */
        hero = self.childNode(withName: "//hero") as! SKSpriteNode
        scrollLayer = self.childNode(withName: "scrollLayer")
        obstacleSource = self.childNode(withName: "obstacle")
        obstacleLayer = self.childNode(withName: "obstacleLayer")
        buttonRestart = self.childNode(withName: "buttonRestart") as! MSButtonNode
        scoreLabel = self.childNode(withName: "scoreLabel") as! SKLabelNode
        
        /* Mise en place du handler de selection du bouton restart*/
        buttonRestart.selectedHandler = {
            
            /* Récupération de la ref a la vue SpriteKit */
            let skView = self.view as SKView!
            
            /* Chargement de la Game scene */
            let scene = GameScene(fileNamed:"GameScene") as GameScene!
            
            /* Étirer pour remplir l'ecran */
            scene?.scaleMode = .aspectFill
            
            /* Relancer la game scene */
            skView?.presentScene(scene)
        }
        /* Cacher le bouton restart*/
        buttonRestart.state = .MSButtonNodeStateHidden
        
        /* Reset Score */
        scoreLabel.text = "\(points)"
    }
    
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        /* Désactivation du touchscreen si gamestate != active */
        if gameState != .active { return }
        
        /* Reset velocité, améliore la réactivité face a la valocité cumulative de chute */
        hero.physicsBody?.velocity = CGVector(dx: 0, dy: 0)
        
        /* Application de pulsation verticale */
        hero.physicsBody?.applyImpulse(CGVector(dx: 0, dy: 300))
        /* Applapplication de pulsation angulaire */
        hero.physicsBody?.applyAngularImpulse(1)
        
        /* Réinitialisation du timer de dernier toucher */
        sinceTouch = 0
    }
    
    
    override func update(_ currentTime: TimeInterval) {
        // Appelé avant chaque rendu visuel
        
        /* ne pas mettre à jour si gamestate != active */
        if gameState != .active { return }
        
        // Initialisation de _lastUpdateTime
        if (self.lastUpdateTime == 0) {
            self.lastUpdateTime = currentTime
        }
        
        // calcul de temps depuis la dernière update
        let dt = currentTime - self.lastUpdateTime
        
        // Update d'entités
        for entity in self.entities {
            entity.update(deltaTime: dt)
        }
        
        self.lastUpdateTime = currentTime
        
        /* Recupérer la velocité actuelle */
        let velocityY = hero.physicsBody?.velocity.dy ?? 0
        /* Verifier et capper la velocité max */
        if velocityY > 400 {
            hero.physicsBody?.velocity.dy = 400
        }
        
        /* Application de la rotation de chute */
        if sinceTouch > 0.2 {
            let impulse = -20000 * fixedDelta
            hero.physicsBody?.applyAngularImpulse(CGFloat(impulse))
        }
        
        /* rotation */
        hero.zRotation.clamp(v1: CGFloat(-35).degreesToRadians(), CGFloat(30).degreesToRadians())
        hero.physicsBody?.angularVelocity.clamp(v1: -2, 3)
        
        /* Update du timer de dernier toucher */
        sinceTouch += fixedDelta
        
        /* Faire scroller le monde */
        scrollWorld()
        updateObstacles()
        spawnTimer+=fixedDelta
    }
    
    func scrollWorld() {
        /* Fonction qui scrolle le monde */
        scrollLayer.position.x -= scrollSpeed * CGFloat(fixedDelta)
        /* boucler sur les nodes du scrolllayer */
        for ground in scrollLayer.children as! [SKSpriteNode] {
            
            /* Get la position du ground node, convertir en espace occupé de scene */
            let groundPosition = scrollLayer.convert(ground.position, to: self)
            
            /* Check si le sprite de sol a quitté l'ecran */
            if groundPosition.x <= -ground.size.width / 2 {
                
                /* Repositionne le sprite a la deuxième position */
                let newPosition = CGPoint(x: (self.size.width / 2) + ground.size.width, y: groundPosition.y)
                
                /* Convertit la position du nouveau node en espace sur le scroll layer  */
                ground.position = self.convert(newPosition, to: scrollLayer)
            }
        }
    }
    
    func updateObstacles() {
        /* Update Obstacles */
        
        obstacleLayer.position.x -= scrollSpeed * CGFloat(fixedDelta)
        
        /* Boucler sur les nodes du obstacleLayer */
        for obstacle in obstacleLayer.children as! [SKReferenceNode] {
            
            /* Recupérer la position du node obstacle et conversit sa nodePosition en scene space */
            let obstaclePosition = obstacleLayer.convert(obstacle.position, to: self)
            
            /* Check si l'obstacle est hors de la scène */
            if obstaclePosition.x <= -26 {
                // 26 = moitié de l'obstacle en largeur
                
                /* Retirer l'obstacle du layer obstacle */
                obstacle.removeFromParent()
            }
            
        }
        /* Moment d'ajouter un obstacle ? */
        if spawnTimer >= 1.5 {
            
            /* Créer un nouvel obstacle en copiant l'obstacle source */
            let newObstacle = obstacleSource.copy() as! SKNode
            obstacleLayer.addChild(newObstacle)
            
            /* Génération de nouvelle position d'obstacle, démarrage hors écran et random position y (pour éviter la répétition) */
            let randomPosition = CGPoint(x: 352, y: CGFloat.random(min: 234, max: 382))
            
            /* Convertit la position du nouveau node en espace layer */
            newObstacle.position = self.convert(randomPosition, to: obstacleLayer)
            
            // Reset du spawn timer
            spawnTimer = 0
        }
    }
    
    func didBegin(_ contact: SKPhysicsContact) {
        
        /* Récup des references aux corps impliqués dans la collision */
        let contactA = contact.bodyA
        let contactB = contact.bodyB
        
        /* Récup des references aux parents des nodes impliqués dans la collision */
        let nodeA = contactA.node!
        let nodeB = contactB.node!
        
        /* Le héros a traversé 'goal'? */
        if nodeA.name == "goal" || nodeB.name == "goal" {
            
            /* Incrementation des points */
            points += 1
            
            /* Mise a jour du label de score */
            scoreLabel.text = String(points)
            
            /* fin */
            return
        }
        
        
        /* Si le héros touche quelque chose d'autre, game over */
        
        /* S'assurer que la fonction est appelée si gamestate = active */
        if gameState != .active { return }
        
        /* Changeer le game state à game over */
        gameState = .gameOver
        
        /* arrêt de toutes les nouvelles vélocités angulaires appliquées */
        hero.physicsBody?.allowsRotation = false
        
        /* reset velocité angulaire */
        hero.physicsBody?.angularVelocity = 0
        
        /* arrêt animation */
        hero.removeAllActions()
        
        /* création de l'action a la mort du heros */
        let heroDeath = SKAction.run({
            
            /* lui faire bouffer le sol tête la première */
            self.hero.zRotation = CGFloat(-90).degreesToRadians()
        })
        
        /* lancer l'action */
        hero.run(heroDeath)
        
        /* Chargement de l'animation de secousse */
        let shakeScene:SKAction = SKAction.init(named: "Shake")!
        
        /* Pour tous les nodes  */
        for node in self.children {
            
            /* Appliquer la secousse */
            node.run(shakeScene)
        }
        
        /* Affiche le bouton restart */
        buttonRestart.state = .MSButtonNodeStateActive
    }
}
