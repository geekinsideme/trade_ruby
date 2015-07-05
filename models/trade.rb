require 'bundler/setup'
require 'active_record'

class Trade < ActiveRecord::Base
  establish_connection(
    'adapter' => 'sqlite3',
    'database' => 'db/trades.sqlite3',
    'timeout' => '15000'
  )
  def label
    read_attribute(:label).to_sym
  end

  def status
    read_attribute(:status).to_sym
  end

  def trade_type
    read_attribute(:trade_type).to_sym
  end

  def entry_type
    read_attribute(:entry_type).to_sym
  end

  def exit_type
    read_attribute(:exit_type).to_sym
  end
end
