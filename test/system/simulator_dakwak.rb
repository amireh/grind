#!/usr/bin/env ruby

$root = File.dirname(__FILE__)

require 'securerandom' # for UUIDs
require 'yaml'

apps = [ "dakwakd", "dakapi", "dakTM" ]
uuid = SecureRandom.uuid
msg_pool = YAML.load_file(File.join($root, "..", "fixture", "dakwak", "messages.yml"))