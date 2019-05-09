Pod::Spec.new do |s|
  s.name         = "EFNetworking"
  s.version      = "1.1.0"
  s.summary      = "EFNetworking，iOS网络层组件，支持POST/GET/PUT/DELETE等网络请求和上传下载及断点续传功能，自带网络缓存处理机制、灵活设置接口签名、自定义HEADER和公共参数等功能"
  s.homepage     = "https://github.com/DandreYang/EFNetworking.git"
  s.license      = "MIT"
  s.author             = { "‘Dandre’" => "mkshow@126.com" }
  s.social_media_url   = "https://github.com/DandreYang/EFNetworking.git"
  s.source       = { :git => "https://github.com/DandreYang/EFNetworking.git", :tag => "#{s.version}" }
  s.source_files  = "EFNetworking/Core/*.{h,m}"
  s.public_header_files = "EFNetworking/Core/*.h"
  s.requires_arc  = true
  s.ios.deployment_target = "8.0"

  s.subspec 'Categories' do |ss|
    ss.public_header_files = 'EFNetworking/Core/Categories/**.h'
    ss.source_files = 'EFNetworking/Core/Categories/*.{h,m}'
  end

  s.subspec 'Request' do |sss|
    sss.public_header_files = 'EFNetworking/Core/Request/**.h','EFNetworking/Core/EFNHeader.h'
    sss.source_files = 'EFNetworking/Core/Request/*.{h,m}','EFNetworking/Core/EFNHeader.h'
    sss.dependency  'EFNetworking/Categories'
  end

  s.subspec 'Response' do |sss|
    sss.public_header_files = 'EFNetworking/Core/Response/**.h'
    sss.source_files = 'EFNetworking/Core/Response/*.{h,m}'
  end

  s.subspec 'CacheHelper' do |sss|
    sss.public_header_files = 'EFNetworking/Core/CacheHelper/**.h'
    sss.source_files = 'EFNetworking/Core/CacheHelper/*.{h,m}'
    sss.dependency  'EFNetworking/Request'
    sss.dependency  'EFNetworking/Response'
    sss.dependency  'YYCache', '~> 1.0.4'
  end

  s.subspec 'NetProxy' do |sss|
    sss.public_header_files = 'EFNetworking/Core/NetProxy/**.h'
    sss.source_files = 'EFNetworking/Core/NetProxy/*.{h,m}'
    sss.dependency  'EFNetworking/Request'
    sss.dependency  'EFNetworking/Response'
    sss.dependency  'AFNetworking', '~> 3.0'
  end

end
