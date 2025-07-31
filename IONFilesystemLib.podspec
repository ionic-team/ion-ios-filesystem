Pod::Spec.new do |spec|
  spec.name                   = 'IONFilesystemLib'
  spec.version                = '1.0.1'

  spec.summary                = 'Library for accessing iOS filesystem.'
  spec.description            = <<-DESC
  A Swift library for iOS that provides access to the native file system. With this library, you can write and read files in different locations, manage directories, and more.
  DESC

  spec.homepage               = 'https://github.com/ionic-team/ion-ios-filesystem'
  spec.license                = { :type => 'MIT', :file => 'LICENSE' }
  spec.author                 = { 'OutSystems Mobile Ecosystem' => 'rd.mobileecosystem.team@outsystems.com' }
  
  spec.source                 = { :http => "https://github.com/ionic-team/ion-ios-filesystem/releases/download/#{spec.version}/IONFilesystemLib.zip", :type => "zip" }
  spec.vendored_frameworks    = "IONFilesystemLib.xcframework"

  spec.ios.deployment_target  = '14.0'
  spec.swift_versions         = ['5.0', '5.1', '5.2', '5.3', '5.4', '5.5', '5.6', '5.7', '5.8', '5.9']
end
