Pod::Spec.new do |s|
  s.name             = 'JDVideoKit'
  s.version          = '1.0.0'
  s.summary          = 'You can easily transfer your video into Three common video type.'
 
  s.description      = <<-DESC
You can easily transfer your video into Three common video type.
You can use set up camera easily.
                       DESC
 
  s.homepage         = 'https://github.com/jamesdouble/JDVideoKit'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'JamesDouble' => 'jameskuo12345@gmail.com' }
  s.source           = { :git => 'https://github.com/jamesdouble/JDVideoKit.git', :tag => s.version.to_s }
 
  s.ios.deployment_target = '8.0'
  s.source_files = 'JDAVKit/JDVideoKit/*'
 
end
