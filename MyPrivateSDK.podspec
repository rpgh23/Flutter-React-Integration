Pod::Spec.new do |s|
  s.name         = 'MyPrivateSDK'
  s.version      = '1.1.0'
  s.summary      = 'Internal Flutter based SDK'
  s.description  = 'Private SDK wrapping Flutter engine and plugins'
  s.homepage     = 'https://github.com/saurabhdwive/FlutterFramework'
  s.license      = { :type => 'MIT' }
  s.author       = { 'YourOrg' => 'dev@yourorg.com' }

  s.platform     = :ios, '13.0'
  s.swift_version = '5.0'

  # ✅ HTTPS REQUIRED
  s.source = {
    :git => 'https://github.com/saurabhdwive/FlutterFramework.git',
    :tag => s.version.to_s
  }

  # ✅ REQUIRED FOR FLUTTER
  s.static_framework = true

  # ✅ XCFrameworks (Flutter, App, Plugins, FFmpeg, etc.)
  s.vendored_frameworks = [
    'Frameworks/*.xcframework'
  ]
  s.source_files = 'Sources/FlutterBridge/**/*.{swift,h,m}'
  s.dependency 'React-Core'

  # ❌ DO NOT EXCLUDE ARCHS
  # ❌ DO NOT USE source_files
end
