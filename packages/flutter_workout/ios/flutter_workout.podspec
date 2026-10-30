#
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html.
#
Pod::Spec.new do |s|
  s.name             = 'flutter_workout'
  s.version          = '0.0.1-beta'
  s.summary          = 'A workout session with a durable journal for Flutter.'
  s.description      = <<-DESC
A workout session for Flutter: one distance from counters and speeds, and a journal that survives the process dying.
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
  # Shared Kotlin workout core, built by tool/build_core.sh (not committed).
  s.vendored_frameworks = 'Frameworks/WorkoutCore.xcframework'
end
