import SpriteKit

protocol GameSceneDelegate: AnyObject {
    func gameDidEnd(score: Int)
    func gameDidPause()
}

class GameScene: SKScene, SKPhysicsContactDelegate {

    weak var gameDelegate: GameSceneDelegate?

    // Nodes
    private var player: SKShapeNode!
    private var ground: SKSpriteNode!
    private var ceiling: SKSpriteNode!
    private var scoreLabel: SKLabelNode!
    private var livesLabel: SKLabelNode!

    // State
    private(set) var score = 0
    private var isJumping = false
    private var gameStarted = false
    private var isDead = false
    private var livesCount = 5

    // Physics
    private let playerCategory:   UInt32 = 0x1 << 0
    private let obstacleCategory: UInt32 = 0x1 << 1
    private let groundCategory:   UInt32 = 0x1 << 2
    private let coinCategory:     UInt32 = 0x1 << 3

    // Timing
    private var obstacleSpawnInterval: TimeInterval = 2.2
    private var gameSpeed: CGFloat = 280
    private var lastSpeedUp: TimeInterval = 0
    private var elapsedTime: TimeInterval = 0

    // MARK: - Setup

    override func didMove(to view: SKView) {
        backgroundColor = SKColor(red: 0.06, green: 0.06, blue: 0.12, alpha: 1)
        physicsWorld.gravity = CGVector(dx: 0, dy: -18)
        physicsWorld.contactDelegate = self

        setupGround()
        setupCeiling()
        setupPlayer()
        setupHUD()
        startObstacleSpawning()
        startCoinSpawning()
        startBackgroundParticles()
        startCountdown()
    }

    func configure(lives: Int) {
        livesCount = lives
    }

    // MARK: - Node Creation

    private func setupGround() {
        let h: CGFloat = 30
        ground = SKSpriteNode(color: SKColor(red: 0.2, green: 0.8, blue: 0.6, alpha: 1), size: CGSize(width: size.width * 3, height: h))
        ground.position = CGPoint(x: size.width / 2, y: h / 2)
        ground.physicsBody = SKPhysicsBody(rectangleOf: ground.size)
        ground.physicsBody?.isDynamic = false
        ground.physicsBody?.categoryBitMask = groundCategory
        ground.physicsBody?.contactTestBitMask = playerCategory
        addChild(ground)

        ceiling = SKSpriteNode(color: .clear, size: CGSize(width: size.width * 3, height: 5))
        ceiling.position = CGPoint(x: size.width / 2, y: size.height)
        ceiling.physicsBody = SKPhysicsBody(rectangleOf: ceiling.size)
        ceiling.physicsBody?.isDynamic = false
        ceiling.physicsBody?.categoryBitMask = groundCategory
        ceiling.physicsBody?.contactTestBitMask = playerCategory
        addChild(ceiling)
    }

    private func setupPlayer() {
        let r: CGFloat = 22
        player = SKShapeNode(circleOfRadius: r)
        player.fillColor = SKColor(red: 1, green: 0.3, blue: 0.5, alpha: 1)
        player.strokeColor = .white
        player.lineWidth = 2
        player.position = CGPoint(x: 100, y: 60)
        player.zPosition = 10

        let body = SKPhysicsBody(circleOfRadius: r - 2)
        body.allowsRotation = false
        body.categoryBitMask = playerCategory
        body.contactTestBitMask = obstacleCategory | groundCategory | coinCategory
        body.collisionBitMask = groundCategory
        body.restitution = 0
        player.physicsBody = body
        addChild(player)

        // Glow effect
        let glow = SKShapeNode(circleOfRadius: r + 6)
        glow.fillColor = .clear
        glow.strokeColor = SKColor(red: 1, green: 0.3, blue: 0.5, alpha: 0.3)
        glow.lineWidth = 4
        player.addChild(glow)
    }

    private func setupHUD() {
        scoreLabel = SKLabelNode(fontNamed: "AvenirNext-Bold")
        scoreLabel.fontSize = 36
        scoreLabel.fontColor = .white
        scoreLabel.position = CGPoint(x: size.width / 2, y: size.height - 60)
        scoreLabel.zPosition = 20
        scoreLabel.text = "0"
        addChild(scoreLabel)

        livesLabel = SKLabelNode(fontNamed: "AvenirNext-Bold")
        livesLabel.fontSize = 22
        livesLabel.fontColor = SKColor(red: 1, green: 0.3, blue: 0.5, alpha: 1)
        livesLabel.position = CGPoint(x: size.width - 20, y: size.height - 55)
        livesLabel.horizontalAlignmentMode = .right
        livesLabel.zPosition = 20
        updateLivesLabel()
        addChild(livesLabel)
    }

    private func updateLivesLabel() {
        let hearts = String(repeating: "♥ ", count: livesCount)
        livesLabel.text = hearts.trimmingCharacters(in: .whitespaces)
    }

    // MARK: - Countdown

    private func startCountdown() {
        let labels = ["3", "2", "1", "GO!"]
        for (i, text) in labels.enumerated() {
            let label = SKLabelNode(fontNamed: "AvenirNext-Heavy")
            label.fontSize = 72
            label.fontColor = .white
            label.position = CGPoint(x: size.width / 2, y: size.height / 2)
            label.alpha = 0
            label.zPosition = 30
            label.text = text
            addChild(label)

            let delay = SKAction.wait(forDuration: TimeInterval(i))
            let fadeIn = SKAction.fadeIn(withDuration: 0.2)
            let wait = SKAction.wait(forDuration: 0.6)
            let fadeOut = SKAction.fadeOut(withDuration: 0.2)
            let remove = SKAction.removeFromParent()
            let start: SKAction = (i == labels.count - 1) ? SKAction.run { [weak self] in self?.gameStarted = true } : .wait(forDuration: 0)
            label.run(.sequence([delay, fadeIn, wait, fadeOut, start, remove]))
        }
    }

    // MARK: - Obstacles

    private func startObstacleSpawning() {
        let spawn = SKAction.run { [weak self] in self?.spawnObstacle() }
        let wait = SKAction.wait(forDuration: 2.5)
        run(.sequence([.wait(forDuration: 4), .repeatForever(.sequence([spawn, wait]))]), withKey: "spawn")
    }

    private func spawnObstacle() {
        guard gameStarted, !isDead else { return }

        let styles: [() -> SKNode] = [
            { self.makeColumnObstacle() },
            { self.makeFloatingObstacle() },
            { self.makeDoubleObstacle() }
        ]
        let obstacle = styles.randomElement()!()
        addChild(obstacle)
        let move = SKAction.moveBy(x: -(size.width + 200), y: 0, duration: TimeInterval((size.width + 200) / gameSpeed))
        obstacle.run(.sequence([move, .removeFromParent()]))
    }

    private func makeColumnObstacle() -> SKNode {
        let heights: [CGFloat] = [60, 80, 100, 120]
        let h = heights.randomElement()!
        let w: CGFloat = 26
        let node = SKSpriteNode(color: SKColor(red: 0.2, green: 0.7, blue: 1, alpha: 1), size: CGSize(width: w, height: h))
        node.position = CGPoint(x: size.width + 60, y: 30 + h / 2)
        node.physicsBody = SKPhysicsBody(rectangleOf: node.size)
        node.physicsBody?.isDynamic = false
        node.physicsBody?.categoryBitMask = obstacleCategory
        node.physicsBody?.contactTestBitMask = playerCategory
        return node
    }

    private func makeFloatingObstacle() -> SKNode {
        let w: CGFloat = 70
        let h: CGFloat = 20
        let y = CGFloat.random(in: 90...180)
        let node = SKSpriteNode(color: SKColor(red: 0.8, green: 0.3, blue: 1, alpha: 1), size: CGSize(width: w, height: h))
        node.position = CGPoint(x: size.width + 80, y: y)
        node.physicsBody = SKPhysicsBody(rectangleOf: node.size)
        node.physicsBody?.isDynamic = false
        node.physicsBody?.categoryBitMask = obstacleCategory
        node.physicsBody?.contactTestBitMask = playerCategory
        return node
    }

    private func makeDoubleObstacle() -> SKNode {
        let container = SKNode()
        container.position = CGPoint(x: size.width + 60, y: 0)

        let low = makeColumnObstacle()
        low.position = CGPoint(x: 0, y: low.position.y)

        let high = makeFloatingObstacle()
        high.position = CGPoint(x: 40, y: high.position.y)

        container.addChild(low)
        container.addChild(high)
        return container
    }

    // MARK: - Coins

    private func startCoinSpawning() {
        let spawn = SKAction.run { [weak self] in self?.spawnCoin() }
        run(.sequence([.wait(forDuration: 3), .repeatForever(.sequence([spawn, .wait(forDuration: 3.5)]))]))
    }

    private func spawnCoin() {
        guard gameStarted, !isDead else { return }
        let coin = SKShapeNode(circleOfRadius: 12)
        coin.fillColor = SKColor(red: 1, green: 0.85, blue: 0, alpha: 1)
        coin.strokeColor = SKColor(red: 1, green: 0.7, blue: 0, alpha: 1)
        coin.lineWidth = 2
        coin.position = CGPoint(x: size.width + 40, y: CGFloat.random(in: 70...200))
        coin.physicsBody = SKPhysicsBody(circleOfRadius: 12)
        coin.physicsBody?.isDynamic = false
        coin.physicsBody?.categoryBitMask = coinCategory
        coin.physicsBody?.contactTestBitMask = playerCategory

        let label = SKLabelNode(text: "$")
        label.fontSize = 14
        label.fontName = "AvenirNext-Bold"
        label.fontColor = .white
        label.verticalAlignmentMode = .center
        coin.addChild(label)

        addChild(coin)
        coin.run(.sequence([.moveBy(x: -(size.width + 100), y: 0, duration: TimeInterval((size.width + 100) / gameSpeed)), .removeFromParent()]))
    }

    // MARK: - Background

    private func startBackgroundParticles() {
        for _ in 0..<15 {
            let star = SKShapeNode(circleOfRadius: CGFloat.random(in: 1...3))
            star.fillColor = .white
            star.alpha = CGFloat.random(in: 0.2...0.6)
            star.position = CGPoint(x: CGFloat.random(in: 0...size.width), y: CGFloat.random(in: 50...size.height))
            addChild(star)
            let pulse = SKAction.sequence([
                .fadeAlpha(to: 0.1, duration: CGFloat.random(in: 0.5...2)),
                .fadeAlpha(to: CGFloat.random(in: 0.3...0.7), duration: CGFloat.random(in: 0.5...2))
            ])
            star.run(.repeatForever(pulse))
        }
    }

    // MARK: - Input

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard gameStarted, !isDead else { return }
        jump()
    }

    private func jump() {
        guard let body = player.physicsBody else { return }
        body.velocity = CGVector(dx: 0, dy: 0)
        body.applyImpulse(CGVector(dx: 0, dy: 95))

        let squash = SKAction.scaleX(to: 0.8, y: 1.2, duration: 0.05)
        let restore = SKAction.scale(to: 1, duration: 0.1)
        player.run(.sequence([squash, restore]))
    }

    // MARK: - Physics

    func didBegin(_ contact: SKPhysicsContact) {
        let masks = contact.bodyA.categoryBitMask | contact.bodyB.categoryBitMask

        if masks == (playerCategory | coinCategory) {
            let coin = contact.bodyA.node?.physicsBody?.categoryBitMask == coinCategory ? contact.bodyA.node : contact.bodyB.node
            collectCoin(coin)
        } else if masks == (playerCategory | obstacleCategory) {
            hitObstacle()
        }
    }

    private func collectCoin(_ node: SKNode?) {
        node?.removeFromParent()
        score += 5
        updateScore()

        let pop = SKLabelNode(text: "+5")
        pop.fontName = "AvenirNext-Bold"
        pop.fontSize = 22
        pop.fontColor = SKColor(red: 1, green: 0.85, blue: 0, alpha: 1)
        pop.position = player.position
        pop.zPosition = 25
        addChild(pop)
        pop.run(.sequence([.group([.moveBy(x: 0, y: 40, duration: 0.6), .fadeOut(withDuration: 0.6)]), .removeFromParent()]))
    }

    private func hitObstacle() {
        guard !isDead else { return }
        isDead = true
        isPaused = false

        let flash = SKAction.sequence([
            .colorize(with: .white, colorBlendFactor: 1, duration: 0.05),
            .colorize(withColorBlendFactor: 0, duration: 0.1)
        ])
        player.run(.repeat(flash, count: 3))

        run(.wait(forDuration: 0.5)) { [weak self] in
            guard let self else { return }
            self.gameDelegate?.gameDidEnd(score: self.score)
        }
    }

    // MARK: - Score / Speed

    private func updateScore() {
        scoreLabel.text = "\(score)"
        let scale = SKAction.sequence([.scale(to: 1.3, duration: 0.05), .scale(to: 1, duration: 0.1)])
        scoreLabel.run(scale)
    }

    override func update(_ currentTime: TimeInterval) {
        guard gameStarted, !isDead else { return }

        elapsedTime += 1.0 / 60.0
        score = max(score, Int(elapsedTime * 2))
        updateScore()

        if elapsedTime - lastSpeedUp > 10 {
            gameSpeed = min(gameSpeed + 20, 520)
            lastSpeedUp = elapsedTime
        }

        // Scrolling ground stripe effect
        let stripeSpeed = gameSpeed / 60
        ground.position.x -= stripeSpeed
        if ground.position.x < -size.width / 2 {
            ground.position.x = size.width / 2
        }
    }
}
