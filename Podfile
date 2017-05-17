source 'https://github.com/CocoaPods/Specs.git'
#source 'ssh://git@github.com/private-specs-registry.git'
# got this structure from https://github.com/robbiehanson/XMPPFramework/issues/688

platform :ios, '8.0'
use_frameworks!

workspace 'Mangosta'

def main_app_pods
  # Using a fork until pending pull requests are accepted
  pod 'XMPPFramework', :git => "https://github.com/pwetrifork/XMPPFramework.git", :branch => 'pending-fixes'
  # The version pushed to CocoaPods is very out of date, use master branch for now
  #pod 'XMPPFramework', :git => "https://github.com/robbiehanson/XMPPFramework.git", :branch => 'master'
  #   pod 'XMPPFramework', git: 'https://github.com/esl/XMPPFramework/' # TODO: Update ELS's fork.
  pod 'MBProgressHUD', '~> 0.9.2'
  pod 'Chatto', '= 3.0.1'
  pod 'ChattoAdditions', '= 3.0.1'
end

target 'Mangosta' do
  main_app_pods
end

target 'Mangosta REST' do
  main_app_pods
  pod 'Jayme'
end
