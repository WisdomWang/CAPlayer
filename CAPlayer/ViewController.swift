//
//  ViewController.swift
//  CAPlayer
//
//  Created by Cary on 2018/9/13.
//  Copyright © 2018年 Cary. All rights reserved.
//

import UIKit


class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        self.view.backgroundColor = UIColor.gray
        let playerView = CAplayerView(frame: CGRect(x: 0, y: 0, width: kScreenWidth, height: 250), theUrl: URL(string: "https://www.apple.com/105/media/us/iphone-x/2017/01df5b43-28e4-4848-bf20-490c34a926a7/films/feature/iphone-x-feature-tpl-cc-us-20170912_1280x720h.mp4")!)
        playerView.backgroundColor = UIColor.black
        self.view.addSubview(playerView)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }


}

