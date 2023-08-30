//
//  TuChannelModel.swift
//  TuChannelView
//
//  Created by zhantu wu on 2023/8/30.
//

import Foundation
import HandyJSON

open class TuChannelModel: HandyJSON {
    var id = 0
    var name = ""
    var pid = 0
    var showFilter = 1 // 是否展示右侧过滤按钮 1:展示 0:隐藏
    public var list: [TuChannelModel] = []
    
    required public init(){}
    
    public func mapping(mapper: HelpingMapper) {
        mapper <<< self.showFilter <-- "show_filter"
    }
}
