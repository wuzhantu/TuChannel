//
//  TuChannelCell.swift
//  TuChannelView
//
//  Created by zhantu wu on 2023/8/30.
//

import UIKit
import SnapKit

enum TuChannelLocation {
    case myChannel
    case recommend
}

enum DisplaySort {
    case left
    case center
    case right
    
    func deleteNext() -> Self {
        if self == .left {
            return .right
        } else if self == .center {
            return .left
        } else {
            return .center
        }
    }
    
    func addNext() -> Self {
        if self == .left {
            return .center
        } else if self == .center {
            return .right
        } else {
            return .left
        }
    }
    
    static func getSort(by index: Int) -> Self {
        let num = index % 3
        if num == 0 {
            return .left
        } else if num == 1 {
            return .center
        } else {
            return .right
        }
    }
}

open class TuChannelCell: UIView {
    
    let titleLab = UILabel()
    
    var sort: DisplaySort
    var title: String
    var index: Int
    var loc: TuChannelLocation {
        didSet {
            var imageName = loc == .myChannel ? "home_channel_delete" : "home_channel_add"
            imageName += (UIScreen.main.scale == 2) ? "@2x" : "@3x"
            if let bundlePath = Bundle.main.path(forResource: "TuChannel", ofType: "bundle"), let bundle = Bundle.init(path: bundlePath), let path = bundle.path(forResource: imageName, ofType: "png") {
                rightIconImgView.image = UIImage(contentsOfFile: path)
            }
        }
    }
    var model: TuChannelModel
    var leftOffset: CGFloat = 0
    var topOffset: CGFloat = 0
    
    var isEdit = false {
        didSet {
            rightIconImgView.isHidden = !isEdit
            titleLab.textColor = (isSelected && !isEdit) ? UIColor(red: 41.0/255.0, green: 161.0/255.0, blue: 247.0/255.0, alpha: 1) : UIColor(red: 45.0/255.0, green: 45.0/255.0, blue: 45.0/255.0, alpha: 1)
            titleLab.font = (isSelected && !isEdit) ? UIFont.boldSystemFont(ofSize: 13) : UIFont.systemFont(ofSize: 13)
        }
    }
    
    var isSelected: Bool = false {
        didSet {
            titleLab.textColor = (isSelected && !isEdit) ? UIColor(red: 41.0/255.0, green: 161.0/255.0, blue: 247.0/255.0, alpha: 1) : UIColor(red: 45.0/255.0, green: 45.0/255.0, blue: 45.0/255.0, alpha: 1)
            titleLab.font = (isSelected && !isEdit) ? UIFont.boldSystemFont(ofSize: 13) : UIFont.systemFont(ofSize: 13)
        }
    }
    
    lazy var rightIconImgView: UIImageView = {
        let imgView = UIImageView()
        return imgView
    }()
    
    init(sort: DisplaySort, title: String, index: Int, loc: TuChannelLocation, model: TuChannelModel) {
        self.sort = sort
        self.title = title
        self.index = index
        self.loc = loc
        self.model = model
        super.init(frame: .zero)
        setupUI()
    }
    
    func setupUI() {
        backgroundColor = UIColor(red: 246.0/255.0, green: 246.0/255.0, blue: 246.0/255.0, alpha: 1)
        layer.cornerRadius = 5
        clipsToBounds = true
        
        titleLab.adjustsFontSizeToFitWidth = true
        titleLab.textColor = UIColor(red: 45.0/255.0, green: 45.0/255.0, blue: 45.0/255.0, alpha: 1)
        titleLab.font = UIFont.systemFont(ofSize: 13)
        titleLab.text = title
        addSubview(titleLab)
        titleLab.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.left.top.greaterThanOrEqualTo(4)
            make.right.bottom.lessThanOrEqualTo(-4)
        }
        
        var imageName = loc == .myChannel ? "home_channel_delete" : "home_channel_add"
        imageName += (UIScreen.main.scale == 2) ? "@2x" : "@3x"
        if let bundlePath = Bundle.main.path(forResource: "TuChannel", ofType: "bundle"), let bundle = Bundle.init(path: bundlePath), let path = bundle.path(forResource: imageName, ofType: "png") {
            rightIconImgView.image = UIImage(contentsOfFile: path)
        }
        addSubview(rightIconImgView)
        rightIconImgView.snp.makeConstraints { make in
            make.top.equalTo(4)
            make.right.equalTo(-4)
            make.size.equalTo(10)
        }
        rightIconImgView.isHidden = true
    }
    
    required public init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

extension TuChannelCell {
    func deleteResetLayout(_ topView: UIView) {
        if sort == .left {
            let left = leftOffset + (CGFloat(num - 1) * (itemWidth + space))
            let top = topOffset - (itemHeight + space)
            self.snp.updateConstraints { make in
                make.left.equalTo(left)
                make.top.equalTo(topView.snp.bottom).offset(top)
            }
            leftOffset = left
            topOffset = top
        } else if sort == .center {
            let left = leftOffset - (itemWidth + space)
            self.snp.updateConstraints { make in
                make.left.equalTo(left)
            }
            leftOffset = left
        } else {
            let left = leftOffset - (itemWidth + space)
            self.snp.updateConstraints { make in
                make.left.equalTo(left)
            }
            leftOffset = left
        }
    }

    func addResetLayout(_ topView: UIView) {
        if sort == .left {
            let left = leftOffset + (itemWidth + space)
            self.snp.updateConstraints { make in
                make.left.equalTo(left)
            }
            leftOffset = left
        } else if sort == .center {
            let left = leftOffset + (itemWidth + space)
            self.snp.updateConstraints { make in
                make.left.equalTo(left)
            }
            leftOffset = left
        } else {
            let left = leftOffset - (CGFloat(num - 1) * (itemWidth + space))
            let top = topOffset + (itemHeight + space)
            self.snp.updateConstraints { make in
                make.left.equalTo(left)
                make.top.equalTo(topView.snp.bottom).offset(top)
            }
            leftOffset = left
            topOffset = top
        }
    }
}
