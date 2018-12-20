//
//  CAplayerView.swift
//  CAPlayer
//
//  Created by Cary on 2018/11/29.
//  Copyright © 2018 Cary. All rights reserved.
//

import UIKit
import AVFoundation
import SnapKit

let kScreenWidth = UIScreen.main.bounds.size.width
let kScreenHeight = UIScreen.main.bounds.size.height
let kTransitionTime = 0.2

enum Direction {
    
    case leftOrRight,upOrDown,none
}

class CAplayerView: UIView {

    var direction:Direction!
    var isVolume = false  //是否为改变声音手势
    
    var playerLayer:AVPlayerLayer?
    var playerItem:AVPlayerItem!
    var player:AVPlayer!
    var url:URL?
    
    var timeLabel:UILabel!  //视频时间
    var slider:UISlider!    //视频进度条
    var sliding = false
    var progressView:UIProgressView!  //缓冲条
    var playBtn:UIButton!    //播放暂停按钮
    var playing = true
    var backBtn:UIButton!    //返回按钮
    var fullScreenBtn:UIButton!     //全屏按钮
    var titleLabel:UILabel!   //标题
    
    var oldConstriants:Array<NSLayoutConstraint>!   //旧的布局
    var isFullScreen:Bool!      //是否全屏
    
    var link:CADisplayLink!     //定时器
    
    override func layoutSubviews() {
        
        super.layoutSubviews()
        playerLayer?.frame = self.bounds
        
    }
    
    //MARK:----------便利构造器
    convenience  init(frame: CGRect,theUrl:URL) {
        
        self.init(frame: frame)
        url = theUrl
        setupUI()
        setupTap()
        setupPlayer()
        link = CADisplayLink(target: self, selector: #selector(update))
        link.add(to: RunLoop.main, forMode: .defaultRunLoopMode)
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    //MARK:----------UI界面
    func setupUI () {
        
        timeLabel = UILabel()
        timeLabel.textColor = UIColor.white
        timeLabel.font = UIFont.systemFont(ofSize: 12)
        self.addSubview(timeLabel)
        timeLabel.snp.makeConstraints { (make) in
            
            make.right.equalTo(self).inset(25)
            make.bottom.equalTo(self).inset(5)
            
        }
        
        fullScreenBtn = UIButton()
        self.addSubview(fullScreenBtn)
        fullScreenBtn.snp.makeConstraints { (make) in
            
            make.right.equalTo(self).inset(5)
            make.bottom.equalTo(self).inset(5)
            make.width.height.equalTo(15)
        }
        // 设置按钮图片
        fullScreenBtn.setImage(UIImage(named: "full_screen"), for: .normal)
        // 点击事件
        fullScreenBtn.addTarget(self, action: #selector(tapChangeScreen), for: .touchUpInside)
        
        
        slider = UISlider()
        self.addSubview(slider)
        slider.snp.makeConstraints { (make) in
            make.bottom.equalTo(self).inset(5)
            make.left.equalTo(self).offset(50)
            make.right.equalTo(self).inset(100)
            make.height.equalTo(15)
        }
        slider.minimumValue = 0
        slider.maximumValue = 1
        slider.value = 0
        // 从最大值滑向最小值时杆的颜色
        slider.maximumTrackTintColor = UIColor.clear
        // 从最小值滑向最大值时杆的颜色
        slider.minimumTrackTintColor = UIColor.white
        // 在滑块圆按钮添加图片
        slider.setThumbImage(UIImage(named: "knob"), for: .normal)
        // 按下的时候
        slider.addTarget(self, action: #selector(sliderTouchDown(slider:)), for: .touchDown)
        // 弹起的时候
        slider.addTarget(self, action: #selector(sliderTouchUpOut(slider:)), for: .touchUpOutside)
        slider.addTarget(self, action: #selector(sliderTouchUpOut(slider:)), for: .touchUpInside)
        slider.addTarget(self, action: #selector(sliderTouchUpOut(slider:)), for: .touchCancel)
        
        progressView = UIProgressView()
        progressView.backgroundColor = UIColor.lightGray
        self.insertSubview(progressView, belowSubview: slider)
        progressView.snp.makeConstraints { (make) in
            make.left.right.equalTo(slider)
            make.centerY.equalTo(slider)
            make.height.equalTo(2)
        }
        
        progressView.tintColor = UIColor.red
        progressView.progress = 0
        
        playBtn = UIButton()
        self.addSubview(playBtn)
        playBtn.snp.makeConstraints { (make) in
            make.centerY.equalTo(slider)
            make.left.equalTo(self).offset(10)
            make.width.height.equalTo(30)
        }
        // 设置按钮图片
        playBtn.setImage(UIImage(named: "pause"), for: .normal)
        // 点击事件
        playBtn.addTarget(self, action: #selector(playAndPause(btn:)), for: .touchUpInside)
        
        NotificationCenter.default.addObserver(self, selector: #selector(deviceOrientationDidChange), name:NSNotification.Name.UIDeviceOrientationDidChange, object: nil)
        
        
        backBtn = UIButton()
        self.addSubview(backBtn)
        backBtn.snp.makeConstraints { (make) in
            make.top.equalTo(self).offset(10)
            make.left.equalTo(self).offset(10)
            make.width.height.equalTo(30)
        }
        // 设置按钮图片
        backBtn.setImage(UIImage(named: "Back-white"), for: .normal)
        // 点击事件
        backBtn.addTarget(self, action: #selector(onClickBackBtnAction), for: .touchUpInside)
        backBtn.isHidden = true
        
        titleLabel = UILabel()
        titleLabel.text = "这里显示视频的标题"
        titleLabel.font = UIFont.systemFont(ofSize: 14)
        titleLabel.textColor = UIColor.white
        self.addSubview(titleLabel)
        titleLabel.snp.makeConstraints { (make) in
            
            make.top.equalTo(self).offset(10)
            make.height.equalTo(30)
            make.centerX.equalTo(self)
            
        }

    }
    
    //MARK:----------添加手势
    func setupTap () {
        
        //是否全屏手势（双击手势）
        let fullOrNotFullScreenTap = UITapGestureRecognizer(target: self, action: #selector(tapChangeScreen))
        fullOrNotFullScreenTap.numberOfTapsRequired = 2
        self.addGestureRecognizer(fullOrNotFullScreenTap)
        
        //控件是否隐藏（单击手势）
        let disOrNotdisAppearTap = UITapGestureRecognizer(target: self, action: #selector(disOrNotDisAppear))
        disOrNotdisAppearTap.numberOfTapsRequired  = 1
        self.addGestureRecognizer(disOrNotdisAppearTap)
        
        //这行很关键，意思是只有当没有检测到双击手势 或者 检测双击手势失败，s单击手势才有效
        disOrNotdisAppearTap.require(toFail: fullOrNotFullScreenTap)
        
        //滑动手势
        let pan  = UIPanGestureRecognizer(target: self, action: #selector(changeVoiceOrLightOrProgress(pan:)))
        self.addGestureRecognizer(pan)
        pan.delegate = self as? UIGestureRecognizerDelegate
        
        
    }
    
    @objc func changeVoiceOrLightOrProgress (pan:UIPanGestureRecognizer) {
        
        let offsetPoint = pan.translation(in: self)
        let locationPoint = pan.location(in: self)
        let veloctyPoint = pan.velocity(in: self)
        
        switch pan.state {
        case .began:
            let x = fabs(veloctyPoint.x)
            let y = fabs(veloctyPoint.y)
            if x > y {
                direction = .leftOrRight
            }
            else if x < y {
                
                direction = .upOrDown
                if locationPoint.x <= self.frame.size.width/2 {
                    
                    isVolume = false
                } else {
                    isVolume = true
                }
            }
            break
            
        case .changed:
            
            if direction == .upOrDown {
                
                if isVolume == false && offsetPoint.y > 0 {
                    
                    var newBrightness = UIScreen.main.brightness - 0.01
                    if newBrightness < 0 {
                        newBrightness = 0
                    }
                    UIScreen.main.brightness = newBrightness
                }
              else  if isVolume == false && offsetPoint.y < 0 {
                    
                    var newBrightness = UIScreen.main.brightness + 0.01
                    if newBrightness > 1 {
                        newBrightness = 1
                    }
                    UIScreen.main.brightness = newBrightness
                }
              else  if isVolume == true && offsetPoint.y > 0 {
                    
                    var newVolume = player.volume - 0.01
                    if newVolume < 0 {
                        newVolume = 0
                    }
                    player.volume = Float(newVolume)
                }
                else  if isVolume == true && offsetPoint.y < 0 {
                    
                    var newVolume = player.volume + 0.01
                    if newVolume > 1 {
                        newVolume = 1
                    }
                    player.volume = Float(newVolume)
                }
                
                
            }
            else if direction == .leftOrRight {
        
                //可在这里添加左右滑动改变视频进度的代码
            }
            
            break
            
        case .ended:
            
            if direction == .upOrDown {
                
                isVolume = false
            }
            else if direction == .leftOrRight {
                
            }
            
            break
            
        default:
            break
        }
        
        pan.setTranslation(CGPoint.zero, in: self)
        
    }
    
    @objc func tapChangeScreen () {
        
        if isFullScreen == false {
            
            let rotation : UIInterfaceOrientationMask = [.landscapeLeft, .landscapeRight]
            kAppdelegate?.blockRotation = rotation
        }  else {
            kAppdelegate?.blockRotation = .portrait
        }
        
    }
    
    @objc func disOrNotDisAppear () {
        
        if timeLabel.isHidden == false {
            
            timeLabel.isHidden = true
            slider.isHidden = true
            progressView.isHidden = true
            playBtn.isHidden = true
            backBtn.isHidden = true
            fullScreenBtn.isHidden = true
            titleLabel.isHidden = true
        }

        else if  timeLabel.isHidden == true && isFullScreen == true {
            
            timeLabel.isHidden = false
            slider.isHidden = false
            progressView.isHidden = false
            playBtn.isHidden = false
            backBtn.isHidden = false
            fullScreenBtn.isHidden = true
            titleLabel.isHidden = false
        }
            
        else if  timeLabel.isHidden == true && isFullScreen == false {
            
            timeLabel.isHidden = false
            slider.isHidden = false
            progressView.isHidden = false
            playBtn.isHidden = false
            backBtn.isHidden = true
            fullScreenBtn.isHidden = false
            titleLabel.isHidden = false
        }
        
    }
    
    //MARK:----------添加播放器
    func setupPlayer () {
        
        guard (url != nil) else {
            
            fatalError("连接错误")
        }
        
        playerItem = AVPlayerItem(url: url!)
        //监听缓冲进度改变
        playerItem.addObserver(self, forKeyPath: "loadedTimeRanges", options: .new, context: nil)
        // 监听状态改变
        playerItem.addObserver(self, forKeyPath: "status", options: .new, context: nil)
        player = AVPlayer(playerItem: playerItem)
        player.volume = 0.5
        playerLayer = AVPlayerLayer(player: player)
        playerLayer?.videoGravity = .resizeAspectFill
        playerLayer?.contentsScale = UIScreen.main.scale
        self.layer.insertSublayer(playerLayer!, at: 0)
    }
    
    deinit {
        
        playerItem.removeObserver(self, forKeyPath: "loadedTimeRanges")
        playerItem.removeObserver(self, forKeyPath: "status")
    }
    
    //MARK:----------KVO方法
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        
        if keyPath == "loadedTimeRanges" {
            
            // 通过监听AVPlayerItem的"loadedTimeRanges"，可以实时知道当前视频的进度缓冲
            let loadedTime = avalableDurationWithplayerItem()
            let totalTime = CMTimeGetSeconds(playerItem.duration)
            let percent = loadedTime/totalTime // 计算出比例
            // 改变进度条
            progressView.progress = Float(percent)
            
        }
        else if keyPath == "status" {
            
            if playerItem.status == .readyToPlay {
                player.play()
            } else {
                print("加载异常")
            }
        }
    }
    
    func avalableDurationWithplayerItem()->TimeInterval{
        guard let loadedTimeRanges = player?.currentItem?.loadedTimeRanges,let first = loadedTimeRanges.first else {fatalError()}
        let timeRange = first.timeRangeValue
        let startSeconds = CMTimeGetSeconds(timeRange.start)
        let durationSecound = CMTimeGetSeconds(timeRange.duration)
        let result = startSeconds + durationSecound
        return result
    }
    
   
    
    //MARK:----------通知方法
    @objc func deviceOrientationDidChange() {
        
        let interfaceOrientation = UIApplication.shared.statusBarOrientation
        switch interfaceOrientation {
        case .landscapeLeft,.landscapeRight:
            
            timeLabel.isHidden = true
            slider.isHidden = true
            progressView.isHidden = true
            playBtn.isHidden = true
            backBtn.isHidden = true
            fullScreenBtn.isHidden = true
            titleLabel.isHidden = true
            
            isFullScreen = true
            oldConstriants = getCurrentVC().view.constraints
            self.updateConstraintsIfNeeded()
            //删除UIView animate可以去除横竖屏切换过渡动画
            UIView.animate(withDuration: kTransitionTime, delay: 0, usingSpringWithDamping: 0.5, initialSpringVelocity: 0, options: .transitionCurlUp, animations: {
                
                UIApplication.shared.keyWindow?.addSubview(self)
                self.snp.makeConstraints { (make) in
                    make.edges.equalTo(UIApplication.shared.keyWindow!)
                }
                self.layoutIfNeeded()
                
            }) { (bool) in
                
            }
            break
        case .portrait,.portraitUpsideDown:
            
            timeLabel.isHidden = false
            slider.isHidden = false
            progressView.isHidden = false
            playBtn.isHidden = false
            titleLabel.isHidden = false
            backBtn.isHidden = true
            fullScreenBtn.isHidden = false
            isFullScreen = false
            getCurrentVC().view.addSubview(self)
            UIView.animateKeyframes(withDuration: kTransitionTime, delay: 0, options: .calculationModeLinear, animations: {
                if (self.oldConstriants != nil) {
                    self.getCurrentVC().view.addConstraints(self.oldConstriants)
                }
            }, completion: nil)
            break
        case .unknown:
            print("UIInterfaceOrientationUnknown")
            break
        default:
            break
        }
        
        getCurrentVC().view.layoutIfNeeded()
        
    }
    
    func getCurrentVC()->UIViewController {
        
        var result:UIViewController!
        var window = UIApplication.shared.keyWindow
        if window?.windowLevel != UIWindowLevelNormal {
            let windows:Array = UIApplication.shared.windows
            for tmpWin:UIWindow in windows {
                if tmpWin.windowLevel == UIWindowLevelNormal {
                    window = tmpWin
                    break
                }
            }
        }
        
        let frontView = window?.subviews[0]
        let nextResponder = frontView?.next
        if (nextResponder?.isKind(of: UIViewController.self))! {
            result = nextResponder as? UIViewController
        } else {
            result = window?.rootViewController
        }
        return result
    }
    
    //MARK:----------全屏按钮点击事件
    @objc func onClickBackBtnAction(){
        //设置竖屏
        kAppdelegate?.blockRotation = .portrait
    }
    
    //MARK:----------暂停播放按钮点击方法
    @objc func playAndPause(btn:UIButton){
    let tmp = !playing
    playing = tmp // 改变状态
    
    // 根据状态设定图片
    if playing {
        playBtn.setImage(UIImage(named: "pause"), for: .normal)
        player.play()
    }else{
        playBtn.setImage(UIImage(named: "play"), for: .normal)
        player.pause()
    }
   
    }
    
    //MARK:----------slider滑动方法
    @objc func sliderTouchDown(slider:UISlider){
        
        self.sliding = true
    }
    
    @objc func sliderTouchUpOut(slider:UISlider){
        
        if player.status == .readyToPlay {
            
            let duration = slider.value * Float(CMTimeGetSeconds(player.currentItem!.duration))
            let seekTime = CMTimeMake(Int64(duration), 1)
            
            player.seek(to: seekTime) { (bool) in
                
                self.sliding = false
            }
        }
        
    }

    //MARK:----------定时器方法
   @objc func update () {
    
    if playing == false {
        return
    }
    
    // 当前播放到的时间
    let currentTime = CMTimeGetSeconds(player.currentTime())
    // 总时间
    let totalTime = TimeInterval(playerItem.duration.value)/TimeInterval(playerItem.duration.timescale)
    
    let timeStr = "\(formatPlayTime(seconds: currentTime))/\(formatPlayTime(seconds: totalTime))"
    timeLabel.text = timeStr
    if sliding == false {
        
        slider.value = Float(currentTime/totalTime)
        
    }
    }
    
    func formatPlayTime(seconds:TimeInterval)->String{
        
        if seconds.isNaN{
            return "00:00"
        }
        let Min:Int = Int(seconds / 60)
        let Sec:Int = Int(seconds) % 60
        return String(format: "%02d:%02d", Min, Sec)
    }
    
}
