//
//  GameScene.swift
//  FlappyBird
//
//  Created by 松隈璃奈 on 2017/03/04.
//  Copyright © 2017年 shi0303ma. All rights reserved.
//

import SpriteKit
import AudioToolbox
import AVFoundation

class GameScene: SKScene, SKPhysicsContactDelegate {
    
    var scrollNode:SKNode!
    var wallNode:SKNode!
    var bird:SKSpriteNode!
    var itemNode:SKNode!

    // アイテム用
    var under_wall_y:CGFloat!
    
    // スコア用
    var score = 0
    var itemScore = 0
    var scoreLabelNode:SKLabelNode!
    var bestScoreLabelNode:SKLabelNode!
    var itemScoreLabelNode:SKLabelNode!
    let userDefaults:UserDefaults = UserDefaults.standard
    
    // 衝突判定カテゴリー
    let birdCategory: UInt32 = 1 << 0       // 0...00001
    let groundCategory: UInt32 = 1 << 1     // 0...00010
    let wallCategory: UInt32 = 1 << 2       // 0...00100
    let scoreCategory: UInt32 = 1 << 3      // 0...01000
    let itemScoreCategory: UInt32 = 1 << 4

    // 効果音
    var audioPlayer:AVAudioPlayer!
    
    
    // SKView上にシーンが表示された時に呼ばれるメソッド
    override func didMove(to view: SKView) {
        
        // 重力を設定
        physicsWorld.gravity = CGVector(dx: 0.0, dy: -4.0)
        physicsWorld.contactDelegate = self

        // 背景色を設定
        backgroundColor = UIColor(colorLiteralRed: 0.15, green: 0.75, blue: 0.90, alpha: 1)
        
        // スクロールするスプライトの親ノード
        scrollNode = SKNode()
        addChild(scrollNode)
        
        // 壁用ノード
        wallNode = SKNode()
        scrollNode.addChild(wallNode)
        
        // アイテム用ノード
        itemNode = SKNode()
        scrollNode.addChild(itemNode)
        
        // 各種スプライトを生成する処理をメソッドに分割
        setupGround()
        setupCloud()
        setupWall()
        setupBird()
        setupItem()
        setupScoreLabel()
        
    }
    
    // 画面タップ時
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        if scrollNode.speed > 0 {
            // 鳥の速度をゼロにする
            bird.physicsBody?.velocity = CGVector.zero
            // 鳥に縦方向の力を与える
            bird.physicsBody?.applyImpulse(CGVector(dx: 0, dy: 15))
        } else if bird.speed == 0 {
            restart()
        }
        
    }
    
    
    func setupItem() {
        // アイテム画像読み込み(画質優先)
        let wormTexture = SKTexture(imageNamed: "worm")
        wormTexture.filteringMode = SKTextureFilteringMode.linear
        
        // 移動距離を計算
        let movingDistance = CGFloat(self.frame.size.width + wormTexture.size().width)
        
        // 画面外へ移動->アイテムを削除 のループアニメーション
        let moveWorm = SKAction.moveBy(x: -movingDistance, y: 0, duration:4.0)
        let removeWorm = SKAction.removeFromParent()
        let wormAnimation = SKAction.sequence([moveWorm, removeWorm])
        
        // アイテムを生成
        let createWormAnimation = SKAction.run({
            let groundTexture = SKTexture(imageNamed: "ground")
            let wallTexture = SKTexture(imageNamed: "wall")
            let item = SKNode()
            item.position = CGPoint(x: self.frame.size.width + wormTexture.size().width / 2, y: 0.0)
            item.zPosition = -60.0 // 壁より奥
            
            // アイテムのY軸上限
            let random_y_range = self.frame.size.height - (wallTexture.size().height / 2)
            
            // 1~random_y_rangeまでのランダムな整数を生成
            let random_y = arc4random_uniform( UInt32(random_y_range) )

            // アイテムのY軸下限
            let worm_lowest_y:UInt32!
                worm_lowest_y = UInt32(groundTexture.size().height + (self.under_wall_y / 2))
            
            // Y軸の下限にランダムな値を足して、下の壁のY座標を決定
            let worm_y = CGFloat(worm_lowest_y + random_y)
            
            // アイテムを作成
            let worm = SKSpriteNode(texture: wormTexture)
            worm.position = CGPoint(x: 0.0, y: worm_y)
            worm.physicsBody = SKPhysicsBody(rectangleOf: CGSize(width: worm.size.width, height: worm.size.height))
            worm.physicsBody?.isDynamic = false
            // カテゴリーを設定
            worm.physicsBody?.categoryBitMask = self.itemScoreCategory
            // 衝突判定対象のカテゴリーを設定
            worm.physicsBody?.contactTestBitMask = self.birdCategory
            
            item.addChild(worm)
            item.run(wormAnimation)
            self.itemNode.addChild(item)
        })
        
        // 次のアイテム作成までの待機時間
        let waitAnimation = SKAction.wait(forDuration: TimeInterval(arc4random_uniform(7)))
        // 無限リピート
        let repeatForeverAnimation = SKAction.repeatForever(SKAction.sequence([createWormAnimation, waitAnimation]))
        
        itemNode.run(repeatForeverAnimation)
        
    }
    
    
    func setupScoreLabel() {
        score = 0
        scoreLabelNode = SKLabelNode()
        scoreLabelNode.fontColor = UIColor.black
        scoreLabelNode.position = CGPoint(x: 10, y: self.frame.size.height - 30)
        scoreLabelNode.zPosition = 100      // 一番手前に表示する
        scoreLabelNode.horizontalAlignmentMode = SKLabelHorizontalAlignmentMode.left
        scoreLabelNode.text = "Score:\(score)"
        self.addChild(scoreLabelNode)
        
        bestScoreLabelNode = SKLabelNode()
        bestScoreLabelNode.fontColor = UIColor.black
        bestScoreLabelNode.position = CGPoint(x: 10, y: self.frame.size.height - 60)
        bestScoreLabelNode.zPosition = 100      // 一番手前に表示する
        bestScoreLabelNode.horizontalAlignmentMode = SKLabelHorizontalAlignmentMode.left
        let bestScore = userDefaults.integer(forKey: "BEST")
        bestScoreLabelNode.text = "Best Score:\(bestScore)"
        self.addChild(bestScoreLabelNode)
        
        itemScore = 0
        itemScoreLabelNode = SKLabelNode()
        itemScoreLabelNode.fontColor = UIColor.black
        itemScoreLabelNode.position = CGPoint(x: 10, y: self.frame.size.height - 90)
        itemScoreLabelNode.zPosition = 100      // 一番手前に表示する
        itemScoreLabelNode.horizontalAlignmentMode = SKLabelHorizontalAlignmentMode.left
        itemScoreLabelNode.text = "Item Score:\(itemScore)"
        self.addChild(itemScoreLabelNode)
        
    }

    
    func setupBird() {
        // 鳥の画像を2種類読み込む(画質優先)
        let birdTextureA = SKTexture(imageNamed: "bird_a")
        birdTextureA.filteringMode = SKTextureFilteringMode.linear
        let birdTextureB = SKTexture(imageNamed: "bird_b")
        birdTextureB.filteringMode = SKTextureFilteringMode.linear
        
        // 2種類のテクスチャを交互に変更するアニメーションを作成
        let texturesAnimation = SKAction.animate(with: [birdTextureA, birdTextureB], timePerFrame: 0.2)
        let flap = SKAction.repeatForever(texturesAnimation)
        
        // スプライトを作成
        bird = SKSpriteNode(texture: birdTextureA)
        bird.position = CGPoint(x: self.frame.size.width * 0.2, y: self.frame.size.height * 0.7)
        
        // 物理演算を設定
        bird.physicsBody = SKPhysicsBody(circleOfRadius: bird.size.height / 2.0)
        
        // 衝突した時に回転させない
        bird.physicsBody?.allowsRotation = false
        
        // 衝突のカテゴリー設定
        bird.physicsBody?.categoryBitMask = birdCategory
        bird.physicsBody?.collisionBitMask = groundCategory | wallCategory
        bird.physicsBody?.contactTestBitMask = groundCategory | wallCategory
        
        // アニメーションを設定
        bird.run(flap)
        
        // スプライトを追加
        addChild(bird)
    }

    func setupWall() {
        // 壁の画像を読み込む(画質優先)
        let wallTexture = SKTexture(imageNamed: "wall")
        wallTexture.filteringMode = SKTextureFilteringMode.linear
        
        // 移動距離を計算
        let movingDistance = CGFloat(self.frame.size.width + wallTexture.size().width)
        
        // 画面外へ移動->アイテムを削除 のループアニメーション
        let moveWall = SKAction.moveBy(x: -movingDistance, y: 0, duration:4.0)
        let removeWall = SKAction.removeFromParent()
        let wallAnimation = SKAction.sequence([moveWall, removeWall])
        
        // 壁を生成
        let createWallAnimation = SKAction.run({
            // 壁関連ノード作成
            let wall = SKNode()
            wall.position = CGPoint(x: self.frame.size.width + wallTexture.size().width / 2, y: 0.0)
            wall.zPosition = -50.0 // 雲より手前、地面より奥
            
            // 画面Y軸の中央値
            let center_y = self.frame.size.height / 2
            
            // 壁Y軸上限
            let random_y_range = self.frame.size.height / 4
            
            // 下壁Y軸下限
            let under_wall_lowest_y = UInt32( center_y - wallTexture.size().height / 2 - random_y_range / 2)
            
            // 1~random_y_rangeまでのランダムな整数を生成
            let random_y = arc4random_uniform( UInt32(random_y_range) )
            
            // 下壁Y軸を決定
            self.under_wall_y = CGFloat(under_wall_lowest_y + random_y)
            
            // キャラが通り抜ける隙間の長さ
            let slit_length = self.frame.size.height / 4
            
            // 下壁を作成
            let under = SKSpriteNode(texture: wallTexture)
            under.position = CGPoint(x: 0.0, y: self.under_wall_y)
            wall.addChild(under)
            // スプライトに物理演算を設定
            under.physicsBody = SKPhysicsBody(rectangleOf: wallTexture.size())
            under.physicsBody?.categoryBitMask = self.wallCategory
            // 衝突の時に動かないように設定
            under.physicsBody?.isDynamic = false
            
            // 上壁を作成
            let upper = SKSpriteNode(texture: wallTexture)
            upper.position = CGPoint(x: 0.0, y: self.under_wall_y + wallTexture.size().height + slit_length)
            // スプライトに物理演算を設定
            upper.physicsBody = SKPhysicsBody(rectangleOf: wallTexture.size())
            upper.physicsBody?.categoryBitMask = self.wallCategory
            // 衝突の時に動かないように設定
            upper.physicsBody?.isDynamic = false
            wall.addChild(upper)
            
            // スコアアップ用ノード
            let scoreNode = SKNode()
            scoreNode.position = CGPoint(x: upper.size.width + self.bird.size.width / 2, y: self.frame.height / 2.0)
            scoreNode.physicsBody = SKPhysicsBody(rectangleOf: CGSize(width: upper.size.width, height: self.frame.size.height))
            scoreNode.physicsBody?.isDynamic = false
            scoreNode.physicsBody?.categoryBitMask = self.scoreCategory
            scoreNode.physicsBody?.contactTestBitMask = self.birdCategory
            wall.addChild(scoreNode)
            
            wall.run(wallAnimation)
            self.wallNode.addChild(wall)
        })
        
        // 次の壁作成までの待ち時間のアクションを作成
        let waitAnimation = SKAction.wait(forDuration: 2)
        
        // 壁を作成->待ち時間->壁を作成を無限に繰り替えるアクションを作成
        let repeatForeverAnimation = SKAction.repeatForever(SKAction.sequence([createWallAnimation, waitAnimation]))
        wallNode.run(repeatForeverAnimation)

    }

    
    func setupGround() {
        // 処理速度優先で地面の画像を読み込む
        let groundTexture = SKTexture(imageNamed: "ground")
        groundTexture.filteringMode = SKTextureFilteringMode.nearest
        
        // 必要な枚数を計算
        let needNumber = 2.0 + (frame.size.width / groundTexture.size().width)

        // 左にスクロール->元の位置->左にスクロール の無限ループ
        let moveGround = SKAction.moveBy(x: -groundTexture.size().width, y: 0, duration: 5.0)
        let resetGround = SKAction.moveBy(x: groundTexture.size().width, y: 0, duration: 0.0)
        let repeatScrollGround = SKAction.repeatForever(SKAction.sequence([moveGround, resetGround]))
        
        // スプライトを配置
        stride(from: 0.0, to: needNumber, by: 1.0).forEach { i in
            let sprite = SKSpriteNode(texture: groundTexture)
            // スプライトの表示位置を指定
            sprite.position = CGPoint(x: i * sprite.size.width, y: groundTexture.size().height / 2)
            // スプライトにアクションを設定
            sprite.run(repeatScrollGround)
            // スプライトに物理演算を設定
            sprite.physicsBody = SKPhysicsBody(rectangleOf: groundTexture.size())
            // 衝突のカテゴリー設定
            sprite.physicsBody?.categoryBitMask = groundCategory
            // 衝突の時に動かないように設定
            sprite.physicsBody?.isDynamic = false
            // シーンにスプライトを追加
            scrollNode.addChild(sprite)
        }
        
    }
    
    
    func setupCloud() {
        // 雲画像の読み込み(処理速度優先)
        let cloudTexture = SKTexture(imageNamed: "cloud")
        cloudTexture.filteringMode = SKTextureFilteringMode.nearest
        
        // 必要枚数を計算
        let needCloudNumber = 2.0 + (frame.size.width / cloudTexture.size().width)
        
        // 左にスクロール->元の位置 の無限ループ
        let moveCloud = SKAction.moveBy(x: -cloudTexture.size().width, y: 0, duration: 20.0)
        let resetCloud = SKAction.moveBy(x: cloudTexture.size().width, y: 0, duration: 0.0)
        let repeatScrollCloud = SKAction.repeatForever(SKAction.sequence([moveCloud, resetCloud]))
        
        // スプライトを配置
        stride(from: 0.0, to: needCloudNumber, by: 1.0).forEach { i in
            let sprite = SKSpriteNode(texture: cloudTexture)
            sprite.zPosition = -100 // 一番後ろになるようにする
            // スプライトの表示位置を指定
            sprite.position = CGPoint(x: i * sprite.size.width, y: size.height - cloudTexture.size().height / 2)
            // スプライトにアクションを設定
            sprite.run(repeatScrollCloud)
            // スプライトを追加する
            scrollNode.addChild(sprite)
        }
        
    }
    
    
    // SKPhysicsContactDelegateのメソッド。衝突時に呼ばれる
    func didBegin(_ contact: SKPhysicsContact) {
        // ゲームオーバー時は何もしない
        if scrollNode.speed <= 0 {
            return
        }
        
        if (contact.bodyA.categoryBitMask & scoreCategory) == scoreCategory || (contact.bodyB.categoryBitMask & scoreCategory) == scoreCategory {
            // スコア用物体との衝突時
            print("ScoreUp")
            score += 1
            scoreLabelNode.text = "Score:\(score)"

            // ベストスコア更新か確認する
            var bestScore = userDefaults.integer(forKey: "BEST")
            if score > bestScore {
                bestScore = score
                bestScoreLabelNode.text = "Best Score:\(bestScore)"
                userDefaults.set(bestScore, forKey: "BEST")
                userDefaults.synchronize()
            }
            
        } else if (contact.bodyA.categoryBitMask & itemScoreCategory) == itemScoreCategory || (contact.bodyB.categoryBitMask & itemScoreCategory) == itemScoreCategory  {
            // アイテムスコア用物体との衝突時
            print("ScoreUp")
            itemScore += 1
            itemScoreLabelNode.text = "Item Score:\(itemScore)"
            contact.bodyA.node!.removeFromParent()
            
            // 効果音を流す
            let getSoundPath = Bundle.main.path(forResource: "powerup03", ofType:"mp3")!
            let getSoundUrl = URL(fileURLWithPath: getSoundPath)
            var audioError:NSError?
            do {
                audioPlayer = try AVAudioPlayer(contentsOf: getSoundUrl)
            } catch let error as NSError {
                audioError = error
                audioPlayer = nil
            }
            audioPlayer.play()

            
        } else {
            // 壁・地面との衝突時
            print("GameOver")
            
            // スクロールを停止
            scrollNode.speed = 0
            
            bird.physicsBody?.collisionBitMask = groundCategory
            
            let roll = SKAction.rotate(byAngle: CGFloat(M_PI) * CGFloat(bird.position.y) * 0.01, duration:1)
            bird.run(roll, completion:{
                self.bird.speed = 0
            })
            
            // 効果音を流す
            let gameOverSoundPath = Bundle.main.path(forResource: "damage1", ofType:"mp3")!
            let gameOverSoundUrl = URL(fileURLWithPath: gameOverSoundPath)
            var audioError:NSError?
            do {
                audioPlayer = try AVAudioPlayer(contentsOf: gameOverSoundUrl)
            } catch let error as NSError {
                audioError = error
                audioPlayer = nil
            }
            audioPlayer.play()
        }
        
    }
    
    func restart() {
        score = 0
        itemScore = 0
        scoreLabelNode.text = String("Score:\(score)")
        itemScoreLabelNode.text = "Item Score:\(score)"
        
        bird.position = CGPoint(x: self.frame.size.width * 0.2, y:self.frame.size.height * 0.7)
        bird.physicsBody?.velocity = CGVector.zero
        bird.physicsBody?.collisionBitMask = groundCategory | wallCategory
        bird.zRotation = 0.0
        
        wallNode.removeAllChildren()
        itemNode.removeAllChildren()
        
        bird.speed = 1
        scrollNode.speed = 1
        
    }
    
}
