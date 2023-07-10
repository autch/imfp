
require 'rubygems'
require 'bundler'
require 'yaml'
require 'time'

Bundler.require

ActiveRecord::Base.logger = Logger.new('log/debug.log')
configuration = YAML::load(IO.read('config/database.yml'))
ActiveRecord::Base.establish_connection(configuration['production'])

class Sim < ActiveRecord::Base
  self.primary_key = :hdo_code
  has_many :daily_usages, foreign_key: :hdo_code
end

class DailyUsage < ActiveRecord::Base
  belongs_to :sim, foreign_key: :hdo_code
end
