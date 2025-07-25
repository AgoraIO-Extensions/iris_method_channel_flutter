#
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html.
# Run `pod lib lint iris_method_channel.podspec` to validate before publishing.
#
Pod::Spec.new do |s|
  s.name             = 'iris_method_channel'
  s.version          = '0.0.1'
  s.summary          = 'A new Flutter plugin project.'
  s.description      = <<-DESC
A new Flutter plugin project.
                       DESC
  s.homepage         = 'http://example.com'
  s.license          = { :file => '../LICENSE' }
  s.author           = { 'Your Company' => 'email@example.com' }
  s.source           = { :path => '.' }
  s.source_files = 'iris_method_channel/Sources/**/*'
  s.public_header_files = 'iris_method_channel/Sources/iris_method_channel/include/**/*.h'
  s.dependency 'Flutter'
  s.platform = :ios, '9.0'
  s.libraries = 'stdc++'

  # Flutter.framework does not contain a i386 slice.
  s.pod_target_xcconfig = { 'DEFINES_MODULE' => 'YES', 'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'i386' }
end
