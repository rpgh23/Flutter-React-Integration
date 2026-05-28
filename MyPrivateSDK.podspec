Pod::Spec.new do |s|
  s.name         = 'MyPrivateSDK'
  s.version      = '2.0.5.2'
  s.summary      = 'Internal Flutter based SDK'
  s.description  = 'Private SDK wrapping Flutter engine and plugins'
  s.homepage     = 'https://github.com/rpgh23/Flutter-React-Integration'
  s.license      = { :type => 'MIT' }
  s.author       = { 'YourOrg' => 'dev@yourorg.com' }

  s.platform     = :ios, '13.0'
  s.swift_version = '5.0'

  # ✅ HTTPS REQUIRED
  s.source = {
    :git => 'https://github.com/rpgh23/Flutter-React-Integration.git',
    :tag => s.version.to_s
  }

  # ✅ REQUIRED FOR FLUTTER
  s.static_framework = true

  # ✅ XCFrameworks (Flutter, App, Plugins, FFmpeg, etc.)
  s.vendored_frameworks = [
    'Frameworks/*.xcframework',
    'Libraries/libffmpegkit_stub.xcframework'
  ]

s.source_files = 'Sources/FlutterBridge/**/*.{swift,h,m}'

  s.user_target_xcconfig = {
    'DEBUG_INFORMATION_FORMAT[config=Debug]' => 'dwarf'
  }

  s.dependency 'React-Core'

  # ✅ Facebook SDK — required by flutter_facebook_auth and flutter_share_me
  s.dependency 'FBSDKCoreKit', '~> 16.3.1'
  s.dependency 'FBSDKLoginKit', '~> 16.3.1'
  s.dependency 'FBSDKShareKit', '~> 16.3.1'
end
