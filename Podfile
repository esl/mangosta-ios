source 'https://github.com/CocoaPods/Specs.git'
#source 'ssh://git@github.com/private-specs-registry.git'
# got this structure from https://github.com/robbiehanson/XMPPFramework/issues/688

platform :ios, '9.3'
use_frameworks!

workspace 'Mangosta'

def main_app_pods
  # Using a fork until pending pull requests are accepted
  pod 'XMPPFramework', :git => "https://github.com/esl/XMPPFramework.git", :branch => 'pending-fixes'
  #pod 'XMPPFramework', '~> 3.7.0'
  pod 'MBProgressHUD', '~> 0.9.2'
  pod 'Chatto', '= 3.1.0’
  pod 'ChattoAdditions', '= 3.1.0’
end

target 'Mangosta' do
  main_app_pods
end

target 'Mangosta REST' do
  main_app_pods
  pod 'Jayme'
end
