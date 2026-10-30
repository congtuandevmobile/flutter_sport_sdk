#
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html.
#
Pod::Spec.new do |s|
  s.name             = 'flutter_sport_ble'
  s.version          = '0.0.1-beta'
  s.summary          = 'Bluetooth LE sport sensors for Flutter.'
  s.description      = <<-DESC
Bluetooth LE sport sensors for Flutter: several devices at once, one resolved value per metric.
                       DESC
  s.homepage         = 'https://github.com/congtuandevmobile/flutter_sport_sdk'
  s.license          = { :file => '../LICENSE' }
  s.author           = { 'Nguyễn Công Tuấn' => 'nguyencongtuan.devmobile@gmail.com' }
  s.source           = { :path => '.' }
  s.source_files = 'Classes/**/*.{swift,h,m}'
  s.dependency 'Flutter'
  s.platform = :ios, '15.0'

  s.pod_target_xcconfig = { 'DEFINES_MODULE' => 'YES', 'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'i386' }
  s.swift_version = '5.9'
  s.frameworks = 'CoreBluetooth'
  # Shared Kotlin sensor core, built by tool/build_core.sh (not committed).
  s.vendored_frameworks = 'Frameworks/SensorCore.xcframework'
end
