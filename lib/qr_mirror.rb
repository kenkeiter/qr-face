$: << File.dirname(__FILE__)

# remove the following for packaging
require 'rubygems'
require 'bundler/setup'

require 'eventmachine'
require 'em-http'
require 'em-net-http'
require 'evma_httpserver'
require 'json'
require 'happening'
require 'thor'
require 'yaml'

require 'qr_mirror/version'
require 'qr_mirror/init'
require 'qr_mirror/camera'
require 'qr_mirror/server'

if $0 == __FILE__
  require 'qr_mirror/cli'
  QRMirror::CLI.start
end