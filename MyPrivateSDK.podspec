Pod::Spec.new do |s|
  s.name         = 'MyPrivateSDK'
  s.version      = '2.0.7.6'
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
  # GoogleUtilitiesComponents.xcframework is excluded here — it's a leftover
  # artifact from building the Dart-side google_mlkit_* plugins, and duplicates
  # the GoogleUtilitiesComponents pod now pulled in transitively by the
  # 'GoogleMLKit/TextRecognition' dependency below (GULCC* duplicate symbols
  # at link time otherwise).
  s.vendored_frameworks = Dir[File.join(__dir__, 'Frameworks/*.xcframework')]
    .reject { |f| f.include?('GoogleUtilitiesComponents') }
    .map { |f| f.sub("#{__dir__}/", '') } + [
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

  # ✅ Intercom — required by intercom_flutter (bundled in Frameworks/*.xcframework)
  s.dependency 'Intercom', '16.6.1'

  # ✅ GoogleMLKit — required by google_mlkit_text_recognition / google_mlkit_commons
  # (bundled in Frameworks/*.xcframework). Must match the native chain that the
  # Flutter module's google_mlkit_text_recognition version pulls in — pubspec.yaml
  # pins it to 0.13.1, whose own podspec depends on 'GoogleMLKit/TextRecognition', '~> 6.0.0'
  # (GoogleUtilities < 8.0). Pinning this any higher (e.g. ~> 7.0.0, which needs
  # GoogleUtilities ~> 8.0 and ships its own copy of MLKitCommon) causes two
  # incompatible copies of GoogleMLKit's GULCC* classes to be linked at once —
  # "duplicate symbol '_OBJC_CLASS_$_GULCCComponent'" etc. at build time.
  s.dependency 'GoogleMLKit/TextRecognition', '~> 6.0.0'
end
