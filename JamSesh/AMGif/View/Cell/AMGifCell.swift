//
//  AMGifCell.swift
//  AMGifPicker
//
//  Created by Alexander Momotiuk on 09.01.18.
//  Copyright © 2018 Alexander Momotiuk. All rights reserved.
//

import UIKit
import GiphyCoreSDK
import FLAnimatedImage

class AMGifCell: UICollectionViewCell {
    
    private var model: AMGifViewModel!
    let imageView = FLAnimatedImageView()
    let indicator = UIActivityIndicatorView(activityIndicatorStyle: .gray)
    var gifIndicator: AMGifProgress?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        initialize()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        initialize()
    }
    
    private func initialize() {
        setupLayout()
    }
    
    private func setupLayout() {
        contentView.addSubview(imageView)
        imageView.translatesAutoresizingMaskIntoConstraints = false
        
        imageView.topAnchor.constraint(equalTo: self.topAnchor).isActive = true
        imageView.leftAnchor.constraint(equalTo: self.leftAnchor).isActive = true
        imageView.bottomAnchor.constraint(equalTo: self.bottomAnchor).isActive = true
        imageView.rightAnchor.constraint(equalTo: self.rightAnchor).isActive = true
        
        contentView.addSubview(indicator)
        indicator.isHidden = true
        indicator.translatesAutoresizingMaskIntoConstraints = false
        indicator.heightAnchor.constraint(equalToConstant: 40.0).isActive = true
        indicator.widthAnchor.constraint(equalToConstant: 40.0).isActive = true
        indicator.centerXAnchor.constraint(equalTo: centerXAnchor).isActive = true
        indicator.centerYAnchor.constraint(equalTo: centerYAnchor).isActive = true
    }
    
    func setupWith(_ media: AMGifViewModel) {
        model = media
        model.delegate = self
        model.fetchData()
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        gifIndicator?.center = CGPoint(x: contentView.frame.width/2, y: contentView.frame.height/2)
    }
    
    //MARK: - Loading Indicator
    private func startIndicator() {
        if !self.indicator.isAnimating {
            DispatchQueue.main.async {
                self.indicator.startAnimating()
                self.indicator.isHidden = false
            }
        }
    }
    
    private func stopIndicator() {
        if self.indicator.isAnimating {
            DispatchQueue.main.async {
                self.indicator.isHidden = true
                self.indicator.stopAnimating()
            }
        }
    }
    
    private func showGifIndicator() {
        if gifIndicator == nil {
            gifIndicator = AMGifProgress(frame: CGRect(x: 0, y: 0, width: 30, height: 30))
            gifIndicator?.center = CGPoint(x: contentView.frame.width/2, y: contentView.frame.height/2)
            UIView.transition(with: self.gifIndicator!,
                              duration: 0.3,
                              options: .transitionCrossDissolve,
                              animations: {
                                self.contentView.addSubview(self.gifIndicator!)
            }, completion: nil)
        } else {
            
        }
    }
    
    private func hideGifIndicator() {
        if let indicator = gifIndicator {
            UIView.transition(with: indicator,
                              duration: 0.3,
                              options: .transitionCrossDissolve,
                              animations: {
                                indicator.removeFromSuperview()
            }, completion: nil)
        }
    }
    
    override func prepareForReuse() {
        stopIndicator()
        
        gifIndicator?.removeFromSuperview()
        gifIndicator = nil
        
        model.delegate = nil
        model.stopFetching()
        model = nil
        
        imageView.image = nil
        imageView.animatedImage = nil
        super.prepareForReuse()
    }
}

extension AMGifCell: AMGifViewModelDelegate {
    
    func giphyModelDidBeginLoadingGif(_ item: AMGifViewModel?) {
        showGifIndicator()
    }
    
    func giphyModelDidBeginLoadingThumbnail(_ item: AMGifViewModel?) {
        startIndicator()
    }
    
    func giphyModelDidEndLoadingThumbnail(_ item: AMGifViewModel?) {
        stopIndicator()
    }
    
    func giphyModel(_ item: AMGifViewModel?, thumbnail data: Data?) {
        DispatchQueue.main.async {
            if let imageData = data {
                UIView.transition(with: self.imageView,
                                  duration: 0.1,
                                  options: .transitionCrossDissolve,
                                  animations: {
                                    self.imageView.image = UIImage(data: imageData)
                },
                                  completion: nil)
            }
        }
    }
    
    func giphyModel(_ item: AMGifViewModel?, gifData data: Data?) {
        DispatchQueue.main.async {
            if let data = data {
                UIView.transition(with: self.imageView,
                                  duration: 0.1,
                                  options: .transitionCrossDissolve,
                                  animations: {
                                    self.imageView.animatedImage = FLAnimatedImage(animatedGIFData: data)
                },
                                  completion: {(_) in
                                    self.hideGifIndicator()
                })
                
            }
        }
    }
    
    func giphyModel(_ item: AMGifViewModel?, gifProgress progress: CGFloat) {
        gifIndicator?.updateIndicator(with: progress, isAnimated: true)
    }
}
