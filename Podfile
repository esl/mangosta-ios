source 'https://github.com/CocoaPods/Specs.git'
#source 'ssh://git@github.com/private-specs-registry.git'
# got this structure from https://github.com/robbiehanson/XMPPFramework/issues/688

platform :ios, '8.0'
use_frameworks!

workspace 'Mangosta'

def main_app_pods
   pod 'XMPPFramework', git: 'https://github.com/esl/XMPPFramework/', branch: 'andres.XMPPMUCLight'
   pod 'MBProgressHUD', '~> 0.9.2'
end

target 'Mangosta' do
  main_app_pods
end

pre_install do |installer|
  def installer.verify_no_static_framework_transitive_dependencies; end
end

post_install do |installer_representation|
  installer_representation.pods_project.targets.each do |target|
    target.build_configurations.each do |config|
      config.build_settings['ONLY_ACTIVE_ARCH'] = 'NO'
      config.build_settings['ENABLE_BITCODE'] = 'NO'
    end
  end
  
  installer_representation.pods_project.build_configuration_list.build_configurations.each do |configuration|
    configuration.build_settings['ONLY_ACTIVE_ARCH'] = 'NO'
  end
end
