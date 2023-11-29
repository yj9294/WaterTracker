//
//  GADNativeView.swift
//  WaterTracker
//
//  Created by yangjian on 2023/11/22.
//

import Foundation
import GoogleMobileAds
import SwiftUI

struct GADNativeView: UIViewRepresentable {
    let model: GADNativeViewModel?
    func makeUIView(context: Context) -> some UIView {
        return UINativeAdView()
    }
    
    func updateUIView(_ uiView: UIViewType, context: Context) {
        if let uiView = uiView as? UINativeAdView {
            uiView.refreshUI(ad: model?.model?.nativeAd)
        }
    }
}

struct GADNativeViewModel: Identifiable, Hashable, Equatable {
    
    static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.id == rhs.id
    }
    
    var id: String = UUID().uuidString
    var model: GADNativeModel?
    
    static let none = GADNativeViewModel.init()
}

class UINativeAdView: GADNativeAdView {

    init(){
        super.init(frame: UIScreen.main.bounds)
        setupUI()
        refreshUI(ad: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    lazy var adView: UIImageView = {
        let image = UIImageView(image: UIImage(named: "ad_tag"))
        return image
    }()
    
    lazy var iconImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.backgroundColor = .gray
        imageView.layer.cornerRadius = 6
        imageView.layer.masksToBounds = true
        imageView.contentMode = .scaleAspectFill
        return imageView
    }()
    
    lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 14.0, weight: .medium)
        label.textColor = .white
        label.numberOfLines = 1
        label.textAlignment = .left
        return label
    }()
    
    lazy var subTitleLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 11.0)
        label.textColor = .white
        label.numberOfLines = 1
        label.textAlignment = .left
        return label
    }()
    
    lazy var installLabel: UIButton = {
        let label = UIButton()
        label.titleLabel?.font = UIFont.systemFont(ofSize: 14, weight: .regular)
        label.setTitleColor(UIColor.white, for: .normal)
        label.layer.cornerRadius = 18
        label.layer.masksToBounds = true
        return label
    }()
}

extension UINativeAdView {
    func setupUI() {
        
        self.layer.cornerRadius = 12
        self.layer.masksToBounds = true

        addSubview(iconImageView)
        iconImageView.frame = CGRectMake(16, 20, 44, 44)
        
        
        addSubview(titleLabel)
        let width = self.bounds.size.width - iconImageView.frame.maxX - 12 - 4 - 25 - 16
        titleLabel.frame = CGRectMake(iconImageView.frame.maxX + 12, 16, width, 14)

        
        addSubview(adView)
        adView.frame = CGRectMake(titleLabel.frame.maxX + 4, 15, 25, 14)
        
        addSubview(subTitleLabel)
        subTitleLabel.frame = CGRectMake(titleLabel.frame.minX, titleLabel.frame.maxY + 7, width + 25 + 4, 17)

        
        addSubview(installLabel)
        let w = self.bounds.size.width - 32
        installLabel.frame = CGRectMake(16, iconImageView.frame.maxY + 8, w, 36)
        
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        setupUI()
    }
    
    func refreshUI(ad: GADNativeAd? = nil) {
        self.nativeAd = ad
        self.backgroundColor = UIColor(named: "#EDF5EF")
        self.adView.image = UIImage(named: "ad_tag")
        self.installLabel.setTitleColor(.white, for: .normal)
        self.installLabel.backgroundColor = UIColor(named: "#525050")
        self.subTitleLabel.textColor = UIColor(named: "#858585")
        self.titleLabel.textColor = UIColor(named: "#525050")
        
        self.iconView = self.iconImageView
        self.headlineView = self.titleLabel
        self.bodyView = self.subTitleLabel
        self.callToActionView = self.installLabel
        self.installLabel.setTitle(ad?.callToAction, for: .normal)
        self.iconImageView.image = ad?.icon?.image
        self.titleLabel.text = ad?.headline
        self.subTitleLabel.text = ad?.body
        
        self.hiddenSubviews(hidden: self.nativeAd == nil)
        
        if ad == nil {
            self.isHidden = true
        } else {
            self.isHidden = false
        }
    }
    
    func hiddenSubviews(hidden: Bool) {
        self.iconImageView.isHidden = hidden
        self.titleLabel.isHidden = hidden
        self.subTitleLabel.isHidden = hidden
        self.installLabel.isHidden = hidden
        self.adView.isHidden = hidden
    }
}
