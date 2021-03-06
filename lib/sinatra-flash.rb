# frozen_string_literal: true

module Sinatra
  module Flash
    module Style
      def styled_flash(key = :flash)
        return '' if flash(key).empty?

        id = (key == :flash ? 'flash' : "flash_#{key}")
        close = '<button type="button" class="close" data-dismiss="alert"><span aria-hidden="true">×</span><span class="sr-only">Close</span></button>'
        messages = flash(key).collect do |message|
          "  <div class='alert alert-#{message[0]} fade in' role='alert'>#{close}\n <p>#{message[1]}</p></div>\n"
        end

        "<div id='#{id}'>\n#{messages.join}</div>"
      end
    end
  end
end
