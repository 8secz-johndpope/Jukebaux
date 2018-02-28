//
//  AMGifPicker.swift
//  AMGifPicker
//
//  Created by Alexander Momotiuk on 09.01.18.
//  Copyright © 2018 Alexander Momotiuk. All rights reserved.
//

import UIKit
import GiphyCoreSDK

public protocol AMGifPickerDelegate: class {
    
    func gifPicker(_ picker: AMGifPicker, didSelected gif: AMGif)
}

public class AMGifPicker: UIView {
    
    public weak var delegate: AMGifPickerDelegate?
    
    public private(set) var configuration: AMGifPickerConfiguration!
    private var collectionView: UICollectionView!
    private var model: AMGifPickerModel!
    private var isLoading = false
    
    private override init(frame: CGRect) {
        super.init(frame: frame)
    }
    
    public required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        assertionFailure("User init with configuration")
    }
    
    public convenience init(configuration: AMGifPickerConfiguration) {
        self.init(frame: .zero)
        self.configuration = configuration
        initialize()
    }
    
    private func initialize() {
        model = AMGifPickerModel(config: self.configuration)
        model.delegate = self
        print("initialize here")
        setupCollectionView()
    }
    
    //MARK: - Layout
    private func setupCollectionView() {
        let layout = configuration.scrollDirection == .horizontal ? AMGifHorizontalLayout() : AMGifVerticalLayout()
        collectionView = UICollectionView(frame: CGRect.zero, collectionViewLayout: layout)
        (collectionView.collectionViewLayout as? AMGifBaseLayout)?.delegate = self
        addSubview(collectionView)
        collectionView.backgroundColor = .white
        collectionView.delegate = self
        collectionView.dataSource = self
        
        if #available(iOS 10.0, *) {
            collectionView.prefetchDataSource = self
        }
        
        collectionView.register(AMGifCell.self, forCellWithReuseIdentifier: String(describing: AMGifCell.self))
        collectionView.reloadData()
    }
    
    public override func layoutSubviews() {
        super.layoutSubviews()
        collectionView.frame = bounds
    }
    
    //MARK: - Public Methods
    public func search(_ text: String?) {
        model.search(text)
    }
}

extension AMGifPicker: AMGifPickerModelDelegate {
    
    func model(_ model: AMGifPickerModel, didInsert indexPath: [IndexPath]) {
        DispatchQueue.main.async {
            self.collectionView.performBatchUpdates({
                self.collectionView.insertItems(at: indexPath)
            }, completion: nil)
        }
    }
    
    func modelDidUpdatedData(_ model: AMGifPickerModel) {
        DispatchQueue.main.async {
            self.collectionView.scrollRectToVisible(CGRect.init(x: 0, y: 0, width: 1, height: 1), animated: true)
            self.collectionView.collectionViewLayout.invalidateLayout()
            self.collectionView.reloadData()
        }
    }
}

extension AMGifPicker: UICollectionViewDataSource {
    
    public func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    
    public func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return model.numberOfItems()
    }
    
    public func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: String(describing: AMGifCell.self), for: indexPath) as! AMGifCell
        if let item = model.item(at: indexPath.row) {
            cell.setupWith(item)
        }
        return cell
    }
    
    public func collectionView(_ collectionView: UICollectionView, didEndDisplaying cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        model.item(at: indexPath.row)?.stopFetching()
    }
    
    public func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        if model.numberOfItems() - indexPath.item < 10 {
            model.loadNext()
        }
    }
}

extension AMGifPicker: UICollectionViewDataSourcePrefetching {
    
    public func collectionView(_ collectionView: UICollectionView, prefetchItemsAt indexPaths: [IndexPath]) {
        for indexPath in indexPaths {
            model.item(at: indexPath.row)?.prefetchData()
        }
    }
    
    public func collectionView(_ collectionView: UICollectionView, cancelPrefetchingForItemsAt indexPaths: [IndexPath]) {
        for indexPath in indexPaths {
            model.item(at: indexPath.row)?.cancelPrefecth()
        }
    }
}

extension AMGifPicker: UICollectionViewDelegate {
    
    public func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard let item = model.item(at: indexPath.row) else {
            return
        }
        delegate?.gifPicker(self, didSelected: item.gifItem)
    }
}

extension AMGifPicker: AMGifHorizontalLayoutDelegate {
    
    func numberOfRows(_ collectionView: UICollectionView) -> Int {
        return configuration.numberRows
    }
    
    func collectionView(_ collectionView: UICollectionView, widthForItemAt indexPath: IndexPath, withHeight height: CGFloat) -> CGFloat {
        guard let itemSize = model.item(at: indexPath.row)?.gifItem.size else {
            return 0
        }
        let ratio = height/itemSize.height
        return itemSize.width*ratio
    }
}

extension AMGifPicker: AMGifVerticalLayoutDelegate {
    
    func numberOfColumns(_ collectionView: UICollectionView) -> Int {
        return configuration.numberRows
    }
    
    func collectionView(_ collectionView: UICollectionView, heightForItemAt indexPath: IndexPath, withWidth width: CGFloat) -> CGFloat {
        guard let itemSize = model.item(at: indexPath.row)?.gifItem.size else {
            return 0
        }
        let ratio = width/itemSize.width
        return itemSize.height*ratio
    }
}

