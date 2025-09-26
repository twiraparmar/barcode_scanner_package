#
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html.
# Run `pod lib lint barcode_scanner_package.podspec` to validate before publishing.
#
Pod::Spec.new do |s|
  s.name             = 'barcode_scanner_package'
  s.version          = '0.0.1'
  s.summary          = 'A custom barcode scanner package for Flutter with camera preview and ML Kit integration'
  s.description      = <<-DESC
A custom barcode scanner package for Flutter with camera preview and ML Kit integration.
                       DESC
  s.homepage         = 'https://github.com/twiraparmar/barcode_scanner_package'
  s.license          = { :file => '../LICENSE' }
  s.author           = { 'Twira Parmar' => 'twiraparmar@example.com' }
  s.source           = { :path => '.' }
  s.source_files = 'Classes/**/*'
  s.dependency 'Flutter'
  s.platform = :ios, '12.0'

  # Flutter.framework does not contain a i386 slice.
  s.pod_target_xcconfig = { 'DEFINES_MODULE' => 'YES', 'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'i386' }
  s.swift_version = '5.0'

  # Privacy manifest for camera usage
  s.resource_bundles = {'barcode_scanner_package_privacy' => ['Resources/PrivacyInfo.xcprivacy']}
end
