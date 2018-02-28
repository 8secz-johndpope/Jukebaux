# Uncomment this line to define a global platform for your project
# platform :ios, '9.0'

target 'JamSesh' do
  use_frameworks!

  # Pods for JamSesh
	pod 'IQKeyboardManagerSwift'
	pod 'Firebase/Core'
    pod 'Firebase/Database'
    pod 'Firebase/Auth'
    pod 'Firebase/Storage'
    pod 'Firebase/Invites'
    pod 'NVActivityIndicatorView'
    pod 'SCLAlertView'
    pod 'AMWaveTransition'
    pod 'RAMAnimatedTabBarController', "~> 2.0.13" 
    pod 'SimpleAnimation', '~> 0.3'
    pod 'IQKeyboardManagerSwift'
    pod 'MarqueeLabel/Swift'
    pod 'JSQMessagesViewController'
    pod 'Shimmer'
    pod 'KYDrawerController'
    pod 'EmptyDataSet-Swift'
    pod 'GoogleSignIn'
    pod 'SnapKit'
    pod 'SwiftyJSON'
    pod 'GiphyCoreSDK'
    pod 'SDWebImage/GIF'
    pod 'Alamofire'
    pod 'Cache'
    pod 'iCarousel'
    pod 'LiquidFloatingActionButton', :git => 'https://github.com/alexsanderkhitev/LiquidFloatingActionButton.git'

        post_install do |installer|
        installer.pods_project.targets.each do |target|
            target.build_configurations.each do |config|
                config.build_settings['SWIFT_VERSION'] = '3.0'
            end
        end
    end

end
