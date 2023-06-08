Pod::Spec.new do |s|
  s.name             = 'TProgressHUD'
  s.version          = '1.0.0'
  s.summary          = 'A clean and lightweight progress HUD for your iOS.'
  s.description      = 'TProgressHUD is a clean and easy-to-use HUD meant to display the progress of an ongoing task on iOS.'
  s.homepage         = 'https://github.com/fanta1ty/TProgressHUD'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'thinhnguyen12389' => 'thinhnguyen12389@gmail.com' }
  s.source           = { :git => 'https://github.com/fanta1ty/TProgressHUD.git', :tag => s.version.to_s }
  s.ios.deployment_target = '12.0'
  s.platform = :ios
  s.source_files = 'Sources/TProgressHUD/**/*.{swift}'
  s.swift_version = '5.0'
  s.resources = 'Sources/TProgressHUD/Resources/*.xcassets'
end
