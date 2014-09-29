module Deployd
  module Controllers
    class Base
      include Deployd::Controllers::Resource

      def mount_actions
        raise 'please implement #mount_actions'
      end
    end
  end
end
