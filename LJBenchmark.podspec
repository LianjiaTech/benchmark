
Pod::Spec.new do |s|
  s.name             = 'LJBenchmark'
  s.version          = '0.1.0'
  s.summary          = '耗时监测等的工具'

  s.description      = "一个基于Runtime 耗时监测等的工具"

  s.homepage         = 'https://github.com/LianjiaTech/LJBenchmark.git'
  
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'mingtf' => 'bright_mingtf@126.com' }
  s.source           = { :git => 'https://github.com/LianjiaTech/LJBenchmark.git', :tag => s.version.to_s }

  s.ios.deployment_target = '8.0'

  s.source_files = 'LJBenchmark/Classes/**/*'
  
  s.frameworks = 'UIKit'
   
end
