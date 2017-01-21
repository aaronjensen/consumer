module Consumer
  module Defaults
    def self.cycle_maximum_milliseconds
      100
    end

    def self.cycle_timeout_milliseconds
      1000
    end

    def self.position_store_update_interval
      100
    end
  end
end
