Pod::Spec.new do |s|

  s.name         = "VLC-WhiteRaccoon"
  s.version      = "1.0.0"
  s.summary      = "FTP client for iOS"

  s.description  = <<-DESC
  A fork of Valentin Radu's FTP client for iOS to be used with VLC. Ported to tvOS and various improvements added compared to the original version.
                   DESC

  s.homepage     = "https://github.com/fkuehne/WhiteRaccoon"

  s.license      = "MIT"

  s.authors            = { "Valentin Radu" => "radu.v.valentin@gmail.com", "Felix Paul Kühne" => "fkuehne@videolan.org", "Pierre SAGASPE" => "pierre.sagaspe@me.com" }

  s.ios.deployment_target = "6.1"
  s.tvos.deployment_target = "9.0"

  s.source       = { :git => "https://github.com/fkuehne/WhiteRaccoon.git", :tag => "#{s.version}" }

  s.source_files  = "WhiteRaccoon.{h,m}"

  s.framework  = "Foundation"

  s.requires_arc = true

end
