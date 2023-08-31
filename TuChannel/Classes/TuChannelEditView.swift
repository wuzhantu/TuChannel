//
//  TuChannelEditView.swift
//  TuChannelView
//
//  Created by zhantu wu on 2023/8/30.
//

import UIKit

/// 是否是iPhoneX系列(刘海屏)
var isiPhoneXMore: Bool {
    if #available(iOS 11.0, *) {
        return UIApplication.shared.delegate?.window??.safeAreaInsets.top ?? 0 > 20
    }
    return false
}

public let kSafeBottomHeight: CGFloat = isiPhoneXMore ? 34 : 0

enum TuChannelClickType {
    case myChannel(index: Int)
    case recommend(model: TuChannelModel)
}

let recommendTitleTopMargin: CGFloat = 16
let recommendTitleHeight: CGFloat = 20
let leftMargin: CGFloat = 16
let topMargin: CGFloat = 12
let num = 3
let space: CGFloat = 8
let itemHeight: CGFloat = 38
let itemWidth: CGFloat = (UIScreen.main.bounds.width - 2 * leftMargin - CGFloat(num - 1) * space) / CGFloat(num)

open class TuChannelEditView: UIScrollView {

    var editFinishBlock: (([TuChannelModel]) -> Void)?
    var clickBlock: ((TuChannelClickType) -> Void)?
    
    public var allChannels: [TuChannelModel]? {
        didSet {
            guard let allChannels = allChannels else { return }
            refreshView(allChannels: allChannels)
        }
    }
    
    var isDragAnimationFinish = true
    var lastPoint: CGPoint = .zero
    var beginIndex: Int = -1
    var endIndex: Int = -1
    
    var recommendTitleLabs: [UILabel] = []
    var myChannelCellArray: [TuChannelCell] = []
    var recommendCell2DArray: [[TuChannelCell]] = []
    
    private(set) var isEdit = false
    
    public var selectedModel: TuChannelModel?
    
    lazy var myChannelTitleLab: UILabel = {
        let lab = UILabel()
        lab.text = "我的频道"
        lab.textColor = UIColor(red: 51.0/255.0, green: 51.0/255.0, blue: 51.0/255.0, alpha: 1)
        lab.font = UIFont.boldSystemFont(ofSize: 15)
        return lab
    }()
    
    lazy var myChannelTipsLab: UILabel = {
        let lab = UILabel()
        lab.text = "点击进入频道"
        lab.textColor = UIColor(red: 153.0/255.0, green: 153.0/255.0, blue: 153.0/255.0, alpha: 1)
        lab.font = UIFont.systemFont(ofSize: 11)
        return lab
    }()
    
    lazy var editBtn: UIButton = {
        var btn = UIButton()
        btn.setTitle("编辑", for: .normal)
        btn.setTitle("完成", for: .selected)
        btn.setTitleColor(UIColor(red: 41.0/255.0, green: 161.0/255.0, blue: 247.0/255.0, alpha: 1), for: .normal)
        btn.titleLabel?.font = UIFont.systemFont(ofSize: 13)
//        btn.hr.touchAreaInsets = UIEdgeInsets(top: 15, left: 10, bottom: 15, right: 10)
        btn.addTarget(self, action: #selector(editBtnAction), for: .touchUpInside)
        return btn
    }()
    
    lazy var recommendChannelTitleLab: UILabel = {
        let lab = UILabel()
        lab.text = "为您推荐"
        lab.textColor =  UIColor(red: 51.0/255.0, green: 51.0/255.0, blue: 51.0/255.0, alpha: 1)
        lab.font = UIFont.boldSystemFont(ofSize: 15)
        return lab
    }()
    
    lazy var mainScrollView: UIScrollView = {
        let view = UIScrollView()
        return view
    }()
    
    lazy var containerView: UIView = {
        let view = UIView()
        return view
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }
    
    required public init?(coder: NSCoder) {
        super.init(coder: coder)
        setupUI()
    }
    
    func setupUI() {
        addSubview(containerView)
        containerView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
            make.width.equalToSuperview()
        }
    }
    
    func refreshView(allChannels: [TuChannelModel]) {
        guard allChannels.count > 0 else { return }
        
        containerView.addSubview(myChannelTitleLab)
        myChannelTitleLab.snp.makeConstraints { make in
            make.top.equalTo(10)
            make.left.equalTo(16)
        }
        
        containerView.addSubview(myChannelTipsLab)
        myChannelTipsLab.snp.makeConstraints { make in
            make.left.equalTo(myChannelTitleLab.snp.right).offset(8)
            make.centerY.equalTo(myChannelTitleLab)
        }
        
        containerView.addSubview(editBtn)
        editBtn.snp.makeConstraints { make in
            make.right.equalTo(-16)
            make.centerY.equalTo(myChannelTitleLab)
        }
        
        let myChannelBottomOffset = setupMyChannelUI(myChannelModels: allChannels[0].list)

        containerView.addSubview(recommendChannelTitleLab)
        recommendChannelTitleLab.snp.makeConstraints { make in
            make.top.equalTo(myChannelTitleLab.snp.bottom).offset(myChannelBottomOffset)
            make.left.equalTo(16)
        }
        
        var lastTopOffset: CGFloat = 0
        for i in 1..<allChannels.count {
            lastTopOffset = setupRecommendUI(title: allChannels[i].name, recommendModels: allChannels[i].list, lastTopOffset: lastTopOffset)
        }
        
        if recommendTitleLabs.count > 0 && recommendCell2DArray.count > 0 {
            let count = recommendCell2DArray[recommendCell2DArray.count-1].count
            let totalRow = (count % num == 0) ? count / num : (count / num + 1)
            let titleLab = recommendTitleLabs[recommendTitleLabs.count-1]
            let bottom = topMargin + (itemHeight + space) * CGFloat(totalRow)
            containerView.snp.makeConstraints { make in
                make.bottom.equalTo(titleLab.snp.bottom).offset(bottom+kSafeBottomHeight)
            }
        } else {
            containerView.snp.makeConstraints { make in
                make.bottom.equalTo(recommendChannelTitleLab.snp.bottom).offset(space+kSafeBottomHeight)
            }
        }
    }
    
    func setupMyChannelUI(myChannelModels: [TuChannelModel]) -> CGFloat {
        var nextSort: DisplaySort = .left
        for i in 0..<myChannelModels.count {
            let model = myChannelModels[i]
            let title = model.name
            let nextColumn = i % num
            let nextRow = i / num
            let leftOffset = leftMargin + (itemWidth + space) * CGFloat(nextColumn)
            let topOffset = topMargin + (itemHeight + space) * CGFloat(nextRow)
            let view = TuChannelCell(sort: nextSort, title: title, index: i, loc: .myChannel, model: model)
            self.containerView.addSubview(view)
            view.snp.makeConstraints { make in
                make.left.equalTo(leftOffset)
                make.top.equalTo(myChannelTitleLab.snp.bottom).offset(topOffset)
                make.width.equalTo(itemWidth)
                make.height.equalTo(itemHeight)
            }
            view.leftOffset = leftOffset
            view.topOffset = topOffset
            
            if let _ = selectedModel, model.id == selectedModel!.id {
                view.isSelected = true
            }
            
            let tap = UITapGestureRecognizer(target: self, action: #selector(tapAction(_:)))
            view.addGestureRecognizer(tap)
            
            let longPress = UILongPressGestureRecognizer(target: self, action: #selector(longPressAction(_:)))
            view.addGestureRecognizer(longPress)
            
            let pan = UIPanGestureRecognizer(target: self, action: #selector(panAction(_:)))
            pan.delegate = self
            view.addGestureRecognizer(pan)
            
            myChannelCellArray.append(view)
            nextSort = nextSort.addNext()
        }
        
        let count = myChannelCellArray.count
        let totalRow = (count % num == 0) ? count / num : (count / num + 1)
        let reduce = totalRow == 0 ? 0 : space
        return topMargin + (itemHeight + space) * CGFloat(totalRow) - reduce + 27
    }
    
    func setupRecommendUI(title: String, recommendModels: [TuChannelModel], lastTopOffset: CGFloat = 0) -> CGFloat {
        let titleLab = UILabel()
        titleLab.text = title
        titleLab.textColor = UIColor(red: 102.0/255.0, green: 102.0/255.0, blue: 102.0/255.0, alpha: 1)
        titleLab.font = UIFont.systemFont(ofSize: 13)
        containerView.addSubview(titleLab)
        titleLab.snp.makeConstraints { make in
            make.top.equalTo(recommendChannelTitleLab.snp.bottom).offset(lastTopOffset+recommendTitleTopMargin)
            make.left.equalTo(16)
            make.height.equalTo(recommendTitleHeight)
        }
        recommendTitleLabs.append(titleLab)
        
        var items: [TuChannelCell] = []
        var nextSort: DisplaySort = .left
        for i in 0..<recommendModels.count {
            let model = recommendModels[i]
            let title = model.name
            let nextColumn = i % num
            let nextRow = i / num
            let leftOffset = leftMargin + (itemWidth + space) * CGFloat(nextColumn)
            let topOffset = topMargin + (itemHeight + space) * CGFloat(nextRow)
            let view = TuChannelCell(sort: nextSort, title: title, index: i, loc: .recommend, model: model)
            self.containerView.addSubview(view)
            view.snp.makeConstraints { make in
                make.left.equalTo(leftOffset)
                make.top.equalTo(titleLab.snp.bottom).offset(topOffset)
                make.width.equalTo(itemWidth)
                make.height.equalTo(itemHeight)
            }
            view.leftOffset = leftOffset
            view.topOffset = topOffset
            let tap = UITapGestureRecognizer(target: self, action: #selector(tapAction(_:)))
            view.addGestureRecognizer(tap)
            
            let longPress = UILongPressGestureRecognizer(target: self, action: #selector(longPressAction(_:)))
            view.addGestureRecognizer(longPress)
            
            let pan = UIPanGestureRecognizer(target: self, action: #selector(panAction(_:)))
            pan.delegate = self
            view.addGestureRecognizer(pan)
            
            items.append(view)
            nextSort = nextSort.addNext()
        }
        recommendCell2DArray.append(items)
        
        let count = items.count
        let totalRow = (count % num == 0) ? count / num : (count / num + 1)
        let reduce = totalRow == 0 ? 0 : space
        return lastTopOffset + recommendTitleTopMargin + recommendTitleHeight + topMargin + (itemHeight + space) * CGFloat(totalRow) - reduce
    }
    
    @objc func tapAction(_ gesture: UITapGestureRecognizer) {
        guard let view = gesture.view, let cell = view as? TuChannelCell else { return }
        if isEdit {
            if cell.loc == .myChannel {
                deleteMyChannel(with: cell)
            } else {
                deleteRecommend(with: cell)
            }
        } else {
            switch cell.loc {
            case .myChannel:
                let type = TuChannelClickType.myChannel(index: cell.index)
                clickBlock?(type)
            case .recommend:
                let type = TuChannelClickType.recommend(model: cell.model)
                clickBlock?(type)
            }
        }
    }
}

// MARK: - 删除添加处理
extension TuChannelEditView {
    func deleteMyChannel(with cell: TuChannelCell) {
        guard self.myChannelCellArray.count > 1 else { return }
        let delIndex = cell.index
        self.deleteMyChannelToRecommend(with: cell)
        
        UIView.animate(withDuration: 0.3, delay: 0, options: .curveEaseInOut) {
            let section = self.getModelSection(with: cell)
            let titleLab = self.recommendTitleLabs[section]
            cell.snp.remakeConstraints { make in
                make.left.equalTo(leftMargin)
                make.top.equalTo(titleLab.snp.bottom).offset(topMargin)
                make.width.equalTo(itemWidth)
                make.height.equalTo(itemHeight)
            }
            cell.leftOffset = leftMargin
            cell.topOffset = topMargin
            
            for i in (delIndex+1)..<self.myChannelCellArray.count {
                let view = self.myChannelCellArray[i]
                view.deleteResetLayout(self.myChannelTitleLab)
                view.sort = view.sort.deleteNext()
                view.index -= 1
            }
            
            self.myChannelCellArray.remove(at: delIndex)
            if let _ = self.selectedModel, cell.model.id == self.selectedModel!.id {
                cell.isSelected = false
                self.selectedModel = nil
            }
            
            if self.myChannelCellArray.count == 1 {
                self.myChannelCellArray[0].rightIconImgView.isHidden = true
            }
            
            self.resetLayout(with: section)
            
            self.layoutIfNeeded()
        }
    }
    
    func deleteMyChannelToRecommend(with cell: TuChannelCell) {
        let section = self.getModelSection(with: cell)
        
        UIView.animate(withDuration: 0.3, delay: 0, options: .curveEaseInOut) {
            self.recommendCell2DArray[section].forEach { [weak self] view in
                guard let self = self else { return }
                view.addResetLayout(self.recommendTitleLabs[section])
                view.sort = view.sort.addNext()
                view.index += 1
            }
            
            cell.sort = .left
            cell.index = 0
            cell.loc = .recommend
            self.recommendCell2DArray[section].insert(cell, at: 0)
            
            self.layoutIfNeeded()
        }
    }
    
    func deleteMyChannelLast(with cell: TuChannelCell) {
        guard self.myChannelCellArray.count > 1 else { return }
        let delIndex = cell.index
        
        UIView.animate(withDuration: 0.3, delay: 0, options: .curveEaseInOut) {
            let section = self.getModelSection(with: cell)
            let titleLab = self.recommendTitleLabs[section]
            let nextColumn = self.recommendCell2DArray[section].count % num
            let nextRow = self.recommendCell2DArray[section].count / num
            let leftOffset = leftMargin + (itemWidth + space) * CGFloat(nextColumn)
            let topOffset = topMargin + (itemHeight + space) * CGFloat(nextRow)
            cell.snp.remakeConstraints { make in
                make.left.equalTo(leftOffset)
                make.top.equalTo(titleLab.snp.bottom).offset(topOffset)
                make.width.equalTo(itemWidth)
                make.height.equalTo(itemHeight)
            }
            cell.leftOffset = leftOffset
            cell.topOffset = topOffset
            
            self.deleteMyChannelToRecommendLast(with: cell)
            
            for i in (delIndex+1)..<self.myChannelCellArray.count {
                let view = self.myChannelCellArray[i]
                view.deleteResetLayout(self.myChannelTitleLab)
                view.sort = view.sort.deleteNext()
                view.index -= 1
            }
            
            self.myChannelCellArray.remove(at: delIndex)
            
            if self.myChannelCellArray.count == 1 {
                self.myChannelCellArray[0].rightIconImgView.isHidden = true
            }
            
            self.resetLayout(with: section)
            
            self.layoutIfNeeded()
        }
    }
    
    func deleteMyChannelToRecommendLast(with cell: TuChannelCell) {
        let section = self.getModelSection(with: cell)
        
        if let lastCell = recommendCell2DArray[section].last {
            cell.sort = lastCell.sort.addNext()
            cell.index = recommendCell2DArray[section].count
        } else {
            cell.sort = .left
            cell.index = 0
        }
        cell.loc = .recommend
        recommendCell2DArray[section].append(cell)
    }
    
    func deleteRecommend(with cell: TuChannelCell) {
        let delIndex = cell.index
        let section = self.getModelSection(with: cell)
        
        UIView.animate(withDuration: 0.3, delay: 0, options: .curveEaseInOut) {
            let nextColumn = self.myChannelCellArray.count % num
            let nextRow = self.myChannelCellArray.count / num
            let leftOffset = leftMargin + (itemWidth + space) * CGFloat(nextColumn)
            let topOffset = topMargin + (itemHeight + space) * CGFloat(nextRow)
            cell.snp.remakeConstraints { make in
                make.left.equalTo(leftOffset)
                make.top.equalTo(self.myChannelTitleLab.snp.bottom).offset(topOffset)
                make.width.equalTo(itemWidth)
                make.height.equalTo(itemHeight)
            }
            cell.leftOffset = leftOffset
            cell.topOffset = topOffset
            
            self.deleteRecommendToMyChannel(with: cell)
            
            for i in (delIndex+1)..<self.recommendCell2DArray[section].count {
                let view = self.recommendCell2DArray[section][i]
                view.deleteResetLayout(self.recommendTitleLabs[section])
                view.sort = view.sort.deleteNext()
                view.index -= 1
            }
            
            self.recommendCell2DArray[section].remove(at: delIndex)
            
            self.resetLayout(with: section)
    
            self.layoutIfNeeded()
        }
    }
    
    func deleteRecommendToMyChannel(with cell: TuChannelCell) {
        if self.myChannelCellArray.count == 1 {
            self.myChannelCellArray[0].rightIconImgView.isHidden = false
        }
        
        if let lastCell = myChannelCellArray.last {
            cell.sort = lastCell.sort.addNext()
            cell.index = myChannelCellArray.count
        } else {
            cell.sort = .left
            cell.index = 0
        }
        cell.loc = .myChannel
        self.myChannelCellArray.append(cell)
    }
    
    func getModelSection(with cell: TuChannelCell) -> Int {
        guard let allChannels = allChannels else { return 0 }
        var index = 0
        for model in allChannels {
            if cell.model.pid == model.id {
                break
            }
            index += 1
        }
        return index-1
    }
    
    func resetLayout(with section: Int) {
        let count = self.myChannelCellArray.count
        let totalRow = (count % num == 0) ? count / num : (count / num + 1)
        let reduce = totalRow == 0 ? 0 : space
        let top = topMargin + (itemHeight + space) * CGFloat(totalRow) - reduce + 27
        
        self.recommendChannelTitleLab.snp.updateConstraints { make in
            make.top.equalTo(self.myChannelTitleLab.snp.bottom).offset(top)
        }
        
        if self.recommendTitleLabs.count > section+1 {
            var top: CGFloat = 0
            for i in 0..<(section+1) {
                let arr = self.recommendCell2DArray[i]
                let count = arr.count
                let totalRow = (count % num == 0) ? count / num : (count / num + 1)
                let reduce = totalRow == 0 ? 0 : space
                top = top + recommendTitleTopMargin + recommendTitleHeight + topMargin + (itemHeight + space) * CGFloat(totalRow) - reduce
            }

            self.recommendTitleLabs[section+1].snp.updateConstraints { make in
                make.top.equalTo(self.recommendChannelTitleLab.snp.bottom).offset(top+recommendTitleTopMargin)
            }
        }
        
        if recommendTitleLabs.count > 0 && recommendCell2DArray.count > 0 {
            let count = recommendCell2DArray[recommendCell2DArray.count-1].count
            let totalRow = (count % num == 0) ? count / num : (count / num + 1)
            let titleLab = recommendTitleLabs[recommendTitleLabs.count-1]
            let bottom = topMargin + (itemHeight + space) * CGFloat(totalRow)
            containerView.snp.updateConstraints { make in
                make.bottom.equalTo(titleLab.snp.bottom).offset(bottom+kSafeBottomHeight)
            }
        } else {
            containerView.snp.updateConstraints { make in
                make.bottom.equalTo(recommendChannelTitleLab.snp.bottom).offset(space+kSafeBottomHeight)
            }
        }
    }
}

// MARK: - 拖拽处理
extension TuChannelEditView {
    @objc func longPressAction(_ gesture: UILongPressGestureRecognizer) {
        myChannelSort(gesture)
    }
    
    @objc func panAction(_ gesture: UIPanGestureRecognizer) {
        guard isEdit else { return }
        myChannelSort(gesture)
    }
    
    func myChannelSort(_ gesture: UIGestureRecognizer) {
        guard let view = gesture.view, let cell = view as? TuChannelCell else { return }
        guard cell.loc == .myChannel else { return }
        
        if gesture.state == .began {
            beginIndex = cell.index
            lastPoint = gesture.location(in: self)
            
            editBtn.isSelected = true
            isEdit = true
            myChannelTipsLab.text = "拖拽可以排序"
            myChannelCellArray.forEach { [weak self] cell in
                guard let self = self else { return }
                cell.isEdit = self.isEdit
            }
            
            if myChannelCellArray.count == 1 {
                myChannelCellArray[0].rightIconImgView.isHidden = true
            }
            
            recommendCell2DArray.flatMap { $0 }.forEach { [weak self] cell in
                guard let self = self else { return }
                cell.isEdit = self.isEdit
            }
            
            self.containerView.bringSubview(toFront: cell)
            
            UIView.animate(withDuration: 0.07, delay: 0, options: .curveEaseIn) {
                let left = cell.leftOffset - 2
                let top = cell.topOffset - 2
                cell.snp.updateConstraints { make in
                    make.left.equalTo(left)
                    make.top.equalTo(self.myChannelTitleLab.snp.bottom).offset(top)
                    make.width.equalTo(itemWidth+4)
                    make.height.equalTo(itemHeight+4)
                }
                cell.titleLab.textColor = UIColor(red: 102.0/255.0, green: 102.0/255.0, blue: 102.0/255.0, alpha: 1)
                self.layoutIfNeeded()
            }
        } else if gesture.state == .changed {
            let currentPoint = gesture.location(in: self)
            
            let left = cell.leftOffset + currentPoint.x - lastPoint.x
            let top = cell.topOffset + currentPoint.y - lastPoint.y
            cell.snp.updateConstraints { make in
                make.left.equalTo(left)
                make.top.equalTo(myChannelTitleLab.snp.bottom).offset(top)
            }
            cell.leftOffset = left
            cell.topOffset = top
            
            self.layoutIfNeeded()
            
            if isDragAnimationFinish {
                endIndex = findEndIndex(with: cell)
            }
            
            if beginIndex != -1 && endIndex != -1 && beginIndex != endIndex && isDragAnimationFinish {
                if beginIndex < endIndex {
                    dragLeftAnimation(cell: cell, endIndex: endIndex)
                } else {
                    dragRightAnimation(cell: cell, endIndex: endIndex)
                }
            }
            lastPoint = currentPoint
        } else if gesture.state == .cancelled || gesture.state == .ended {
            UIView.animate(withDuration: 0.2, delay: 0, options: .curveEaseInOut) {
                let nextColumn = self.beginIndex % num
                let nextRow = self.beginIndex / num
                let left = leftMargin + (itemWidth + space) * CGFloat(nextColumn)
                let top = topMargin + (itemHeight + space) * CGFloat(nextRow)
                cell.snp.updateConstraints { make in
                    make.left.equalTo(left)
                    make.top.equalTo(self.myChannelTitleLab.snp.bottom).offset(top)
                    make.width.equalTo(itemWidth)
                    make.height.equalTo(itemHeight)
                }
                cell.leftOffset = left
                cell.topOffset = top
                cell.sort = DisplaySort.getSort(by: self.beginIndex)
                cell.index = self.beginIndex
                cell.titleLab.textColor = UIColor(red: 45.0/255.0, green: 45.0/255.0, blue: 45.0/255.0, alpha: 1)
                self.layoutIfNeeded()
            }
        }
    }
    
    func dragLeftAnimation(cell: TuChannelCell, endIndex: Int) {
        isDragAnimationFinish = false
        UIView.animate(withDuration: 0.3, delay: 0, options: .curveEaseInOut) {
            for i in (self.beginIndex+1)...endIndex {
                let view = self.myChannelCellArray[i]
                view.deleteResetLayout(self.myChannelTitleLab)
                view.sort = view.sort.deleteNext()
                view.index -= 1
            }
            self.myChannelCellArray.remove(at: self.beginIndex)
            self.myChannelCellArray.insert(cell, at: endIndex)
            cell.sort = .center
            cell.index = endIndex
            self.beginIndex = endIndex
            self.layoutIfNeeded()
        } completion: { _ in
            self.isDragAnimationFinish = true
        }
    }
    
    func dragRightAnimation(cell: TuChannelCell, endIndex: Int) {
        isDragAnimationFinish = false
        UIView.animate(withDuration: 0.3, delay: 0, options: .curveEaseInOut) {
            for i in endIndex...(self.beginIndex-1) {
                let view = self.myChannelCellArray[i]
                view.addResetLayout(self.myChannelTitleLab)
                view.sort = view.sort.addNext()
                view.index += 1
            }
            self.myChannelCellArray.remove(at: self.beginIndex)
            self.myChannelCellArray.insert(cell, at: endIndex)
            cell.sort = .center
            cell.index = endIndex
            self.beginIndex = endIndex
            
            self.layoutIfNeeded()
        } completion: { _ in
            self.isDragAnimationFinish = true
        }
    }
    
    func findEndIndex(with cell: TuChannelCell) -> Int {
        let nextColumn = beginIndex % num
        let nextRow = beginIndex / num
        let startPointX = leftMargin + (itemWidth + space) * CGFloat(nextColumn)
        let startPointY = myChannelTitleLab.frame.origin.y + myChannelTitleLab.frame.size.height + topMargin + (itemHeight + space) * CGFloat(nextRow)
        let startCenterPoint = CGPoint(x: startPointX + itemWidth * 0.5, y: startPointY + itemHeight * 0.5)
        let distanceX = cell.center.x - startCenterPoint.x
        let distanceY = cell.center.y - startCenterPoint.y
        
        let needMoveX = itemWidth * 0.5 + space
        let needMoveY = itemHeight * 0.5 + space
        
        var retIndex = -1
        // 四个对角线方向
        if abs(distanceX) > needMoveX && abs(distanceY) > needMoveY {
            // 左上
            if distanceX < 0 && distanceY < 0 {
                retIndex = beginIndex - (num + 1)
            }
            // 左下
            if distanceX < 0 && distanceY > 0 {
                retIndex = beginIndex + (num - 1)
            }
            // 右上
            if distanceX > 0 && distanceY < 0 {
                retIndex = beginIndex - (num - 1)
            }
            // 右下
            if distanceX > 0 && distanceY > 0 {
                retIndex = beginIndex + (num + 1)
            }
        } else if abs(distanceX) > needMoveX && abs(distanceY) < itemHeight * 0.3 {
            // 左右方向
            if distanceX < 0 {
                // 左
                retIndex = beginIndex - 1
            } else if distanceX > 0 {
                // 右
                retIndex = beginIndex + 1
            }
        } else if abs(distanceY) > needMoveY && abs(distanceX) < itemWidth * 0.3 {
            // 上下方向
            if distanceY < 0 {
                // 上
                retIndex = beginIndex - num
            } else if distanceY > 0 {
                // 下
                retIndex = beginIndex + num
            }
        }
        
        // 防止越界
        if retIndex < 0 || retIndex >= myChannelCellArray.count {
            retIndex = -1
        }
        return retIndex
    }
}

extension TuChannelEditView: UIGestureRecognizerDelegate {
    open override func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        
        if let view = gestureRecognizer.view, view == self {
            return super.gestureRecognizerShouldBegin(gestureRecognizer)
        }
        
        if let view = gestureRecognizer.view, let cell = view as? TuChannelCell {
            return isEdit && cell.loc == .myChannel
        }
        
        return true
    }
}

extension TuChannelEditView {
    @objc func editBtnAction() {
        editBtn.isSelected = !editBtn.isSelected
        isEdit = !isEdit
        
        myChannelTipsLab.text = isEdit ? "拖拽可以排序" : "点击进入频道"
        
        var myChannelModels: [TuChannelModel] = []
        myChannelCellArray.forEach { [weak self] cell in
            guard let self = self else { return }
            myChannelModels.append(cell.model)
            cell.isEdit = self.isEdit
        }
        
        if myChannelCellArray.count == 1 {
            myChannelCellArray[0].rightIconImgView.isHidden = true
        }
        
        recommendCell2DArray.flatMap { $0 }.forEach { [weak self] cell in
            guard let self = self else { return }
            cell.isEdit = self.isEdit
        }
        
        if !isEdit {
            editFinishBlock?(myChannelModels)
            if selectedModel == nil {
                myChannelCellArray.first?.isSelected = true
                selectedModel = myChannelModels.first
            }
        }
    }
}

