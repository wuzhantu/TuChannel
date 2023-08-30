//
//  ViewController.swift
//  TuChannel
//
//  Created by wuzhantu on 08/30/2023.
//  Copyright (c) 2023 wuzhantu. All rights reserved.
//

import UIKit
import HandyJSON
import TuChannel

class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        
        let path = Bundle.main.path(forResource: "channel", ofType: "json")
        guard let path = path else { return }
        do {
            let jsonStr = try String.init(contentsOfFile: path, encoding: .utf8)
            let channelArr = [TuChannelModel].deserialize(from: jsonStr)
            
            let mainScrollView = TuChannelEditView()
            let allChannels = channelArr?.compactMap({ $0 })
            mainScrollView.selectedModel = allChannels?.first?.list[2]
            mainScrollView.allChannels = allChannels
            self.view.addSubview(mainScrollView)
            mainScrollView.snp.makeConstraints { make in
                make.top.equalTo(55)
                make.left.right.bottom.equalToSuperview()
            }
        } catch {
            
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

}

