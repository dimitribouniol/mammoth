//
//  PostCardProfilePic.swift
//  Mammoth
//
//  Created by Benoit Nolens on 12/06/2023.
//  Copyright © 2023 The BLVD. All rights reserved.
//

import Foundation
import UIKit
import SDWebImage

final class PostCardProfilePic: UIButton {
    
    enum ProfilePicSize {
        case small, regular, big
        
        func width() -> CGFloat {
            switch self {
            case .small:
                return 24
            case .regular:
                return 44
            case .big:
                return 109
            }
        }
        
        func height() -> CGFloat {
            return width() // height == width
        }
        
        func cornerRadius(isCircle: Bool = GlobalStruct.circleProfiles) -> CGFloat {
            if isCircle {
                return width() / 2
            } else {
                switch self {
                case .small:
                    return 4
                case .regular:
                    return 8
                case .big:
                    return 23
                }
            }
        }
    }
    
    static var transformer: SDImagePipelineTransformer {
        let scale = UIScreen.main.scale
        let thumbnailSize = CGSize(width: PostCardProfilePic.ProfilePicSize.regular.width() * scale, height: PostCardProfilePic.ProfilePicSize.regular.width() * scale)
        let resizeTransformer = SDImageResizingTransformer(size: thumbnailSize, scaleMode: .aspectFit)
        let roundTransformer = SDImageRoundCornerTransformer(
            radius: GlobalStruct.circleProfiles ? .greatestFiniteMagnitude : PostCardProfilePic.ProfilePicSize.regular.cornerRadius(isCircle: false),
            corners: .allCorners,
            borderWidth: 0,
            borderColor: nil)
        return SDImagePipelineTransformer(transformers: [resizeTransformer, roundTransformer])
    }
    
    // MARK: - Properties
    
    private(set) var profileImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFill
        imageView.image = UIImage()
        imageView.isOpaque = true
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.isUserInteractionEnabled = true
        imageView.layer.isOpaque = true
        imageView.layer.masksToBounds = true
        imageView.layer.backgroundColor = UIColor.custom.background.cgColor
        return imageView
    }()
    
    private lazy var badge: BlurredBackground = {
        let view = BlurredBackground()
        view.layer.cornerRadius = 11
        view.clipsToBounds = true
        view.layer.cornerCurve = .continuous
        view.translatesAutoresizingMaskIntoConstraints = false
        view.isUserInteractionEnabled = false
        return view
    }()
    
    private lazy var badgeIconView: UIImageView = {
        let imageView = UIImageView()
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.contentMode = .scaleAspectFit
        imageView.tag = 11
        imageView.tintColor = .custom.linkText
        return imageView
    }()
        
    private var user: UserCardModel?
    private var size: ProfilePicSize = ProfilePicSize.regular
    public var onPress: PostCardButtonCallback?
    public var isContextMenuEnabled = true
        
    init(withSize profilePicSize: ProfilePicSize) {
        super.init(frame: .zero)
        self.size = profilePicSize
        self.setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func prepareForReuse() {
        self.user = nil
        self.onPress = nil
        self.profileImageView.sd_cancelCurrentImageLoad()
        self.profileImageView.image = nil
    }
}

// MARK: - Setup UI
private extension PostCardProfilePic {
    func setupUI() {
        self.isOpaque = true
        self.addSubview(profileImageView)
        self.translatesAutoresizingMaskIntoConstraints = false
        
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(self.profileTapped))
        self.profileImageView.addGestureRecognizer(tapGesture)
                
        let widthImageC = profileImageView.widthAnchor.constraint(equalToConstant: self.size.width())
        widthImageC.priority = .required
        
        let heightImageC = profileImageView.heightAnchor.constraint(equalToConstant: self.size.height())
        heightImageC.priority = .required
        
        NSLayoutConstraint.activate([
            widthImageC,
            heightImageC,
            profileImageView.topAnchor.constraint(equalTo: self.topAnchor),
            profileImageView.bottomAnchor.constraint(equalTo: self.bottomAnchor),
            profileImageView.leadingAnchor.constraint(equalTo: self.leadingAnchor),
            profileImageView.trailingAnchor.constraint(equalTo: self.trailingAnchor),
        ])
        
        let interaction = UIContextMenuInteraction(delegate: self)
        self.profileImageView.addInteraction(interaction)
        
        self.addSubview(self.badge)
        self.badge.addSubview(self.badgeIconView)
        NSLayoutConstraint.activate([
            self.badge.widthAnchor.constraint(equalToConstant: 22),
            self.badge.heightAnchor.constraint(equalToConstant: 22),
            self.badge.leadingAnchor.constraint(equalTo: self.leadingAnchor, constant: -6),
            self.badge.topAnchor.constraint(equalTo: self.topAnchor, constant: -6),
            
            self.badgeIconView.widthAnchor.constraint(equalToConstant: 10),
            self.badgeIconView.heightAnchor.constraint(equalToConstant: 10),
            self.badgeIconView.centerXAnchor.constraint(equalTo: self.badge.centerXAnchor),
            self.badgeIconView.centerYAnchor.constraint(equalTo: self.badge.centerYAnchor)
        ])
    }
}

// MARK: - Configuration
extension PostCardProfilePic {
    func configure(user: UserCardModel, badgeIcon: UIImage? = nil) {
        self.user = user
        
        if self.profileImageView.sd_currentImageURL?.absoluteString != user.imageURL {
            self.profileImageView.sd_cancelCurrentImageLoad()
        }
        
        if let profileStr = user.imageURL, let profileURL = URL(string: profileStr) {
            let userForImage = user
            
            self.profileImageView.ma_setImage(with: profileURL,
                                              cachedImage: self.user?.decodedProfilePic,
                                              imageTransformer: PostCardProfilePic.transformer) { image in
                if userForImage == self.user {
                    user.decodedProfilePic = image
                }
            }
        }
        
        self.profileImageView.layer.cornerRadius = self.size.cornerRadius()
                
        if let badgeIcon {
            self.badgeIconView.image = badgeIcon
            self.badge.isHidden = false
        } else {
            self.badge.isHidden = true
        }
    }
    
    func optimisticUpdate(image: UIImage) {
        self.profileImageView.image = image.roundedCornerImage(with: self.size.cornerRadius() * 2)
    }
    
    func onThemeChange() {
        self.profileImageView.backgroundColor = .custom.OVRLYSoftContrast
        
        if let user = self.user {
            self.configure(user: user)
        }
    }
    
    @objc func profileTapped() {
        if let user = user {
            self.onPress?(.profile, true, .user(user))
        }
    }
    
    func willDisplay() {
        if self.profileImageView.sd_currentImageURL?.absoluteString != self.user?.imageURL {
            self.profileImageView.sd_cancelCurrentImageLoad()
            
            if let profileStr = self.user?.imageURL, let profileURL = URL(string: profileStr) {
                self.profileImageView.ma_setImage(with: profileURL,
                                                  cachedImage: self.user?.decodedProfilePic,
                                                  imageTransformer: PostCardProfilePic.transformer) { image in }
            }
        }
    }
}

// MARK: - Context menu creators
extension PostCardProfilePic {
    
    override func contextMenuInteraction(_ interaction: UIContextMenuInteraction, configurationForMenuAtLocation location: CGPoint) -> UIContextMenuConfiguration? {
        guard isContextMenuEnabled else { return nil }
        
        if let account = self.user?.account {
            FollowManager.shared.followStatusForAccount(account, requestUpdate: .whenUncertain)
        }
        
        return UIContextMenuConfiguration(
            identifier: nil,
            previewProvider: nil,
            actionProvider: { _ in
                self.createContextMenu()
            })
    }
    
    func createContextMenu() -> UIMenu {
        guard let account = self.user?.account else { return UIMenu() }
        let isFollowing = FollowManager.shared.followStatusForAccount(account) == .following || (self.user?.isFollowing ?? false)
        
        if let user = self.user {
            if user.isSelf {
                let options = [
                    createContextMenuAction("Mention", .mention, isActive: true, data: nil),
                    createContextMenuAction("Share Link", .share, isActive: true, data: nil),
                ]

                return UIMenu(title: "", options: [.displayInline], children: options)
            }
            
            let options = [
                
                createContextMenuAction("Mention", .mention, isActive: true, data: nil),

                ( isFollowing
                  ? createContextMenuAction("Unfollow", .follow, isActive: false, data: nil)
                  : createContextMenuAction("Follow", .follow, isActive: true, data: nil)),
                
                ( isFollowing
                    ? UIMenu(title: "Manage Lists", image: MAMenu.list.image.withRenderingMode(.alwaysTemplate), options: [], children: [
                            UIMenu(title: MAMenu.addToList.title, image: MAMenu.addToList.image, options: [], children: ListManager.shared.allLists(includeTopFriends: false).map({
                                createContextMenuAction($0.title, .addToList, isActive: true, data: PostCardButtonCallbackData.list($0.id))
                            })),
                            UIMenu(title: MAMenu.removeFromList.title, image: MAMenu.removeFromList.image, options: [], children: ListManager.shared.allLists(includeTopFriends: false).map({
                                createContextMenuAction($0.title, .removeFromList, isActive: true, data: PostCardButtonCallbackData.list($0.id))
                            })),
                            createContextMenuAction("Create new List", .createNewList, isActive: true, data: nil)
                        ])
                    : nil),
                
                (user.isMuted
                 ? createContextMenuAction("Unmute", .unmute, isActive: true, data: nil)
                 : UIMenu(title: "Mute @\(user.username)", image: MAMenu.muteOneDay.image.withRenderingMode(.alwaysTemplate), options: [], children: [
                    createContextMenuAction("Mute 1 Day", .muteOneDay, isActive: true, data: nil),
                    createContextMenuAction("Mute Forever", .muteForever, isActive: true, data: nil)
                ])),
                
                createContextMenuAction("Report @\(user.username)", .reportUser, isActive: true, data: nil, attributes: .destructive),
                
                (user.isBlocked
                 ? createContextMenuAction("Unblock @\(user.username)", .unblock, isActive: true, data: nil)
                 : createContextMenuAction("Block @\(user.username)", .block, isActive: true, data: nil, attributes: .destructive)),
                                
                createContextMenuAction("Share Link", .share, isActive: true, data: nil),
            ].compactMap({$0})

            return UIMenu(title: "", options: [.displayInline], children: options)
        }
        
        log.error("[PostCardProfilePic]: created an empty UIMenu")
        return UIMenu()
    }

    private func createContextMenuAction(_ title: String, _ buttonType: PostCardButtonType, isActive: Bool, data: PostCardButtonCallbackData?, attributes:  UIMenuElement.Attributes = []) -> UIAction {
        var color: UIColor = .black
        if GlobalStruct.overrideTheme == 1 || self.traitCollection.userInterfaceStyle == .light {
            color = .black
        } else if GlobalStruct.overrideTheme == 2 || self.traitCollection.userInterfaceStyle == .dark  {
            color = .white
        }
        
        if attributes.contains(.destructive) {
            color = UIColor.systemRed
        }
        
        let action = UIAction(title: title,
                                  image: buttonType.icon(symbolConfig: postCardSymbolConfig)?.withTintColor(color).withRenderingMode(.alwaysTemplate),
                                  identifier: nil, attributes: attributes) { _ in
            self.onPress?(buttonType, isActive, data)
        }
        action.accessibilityLabel = title
        return action
    }
}