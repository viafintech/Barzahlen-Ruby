require "grac"

require "barzahlen_v2/version"
require "barzahlen_v2/error"
require "barzahlen_v2/configuration"
require "barzahlen_v2/signature"
require "barzahlen_v2/request"
require "barzahlen_v2/slip"

module BarzahlenV2
  class << self
    attr_accessor :configuration
  end

  def self.configuration
    @configuration ||= Configuration.new
  end

  def self.reset
    @configuration = Configuration.new
  end

  def self.configure
    yield(configuration)
  end
end
