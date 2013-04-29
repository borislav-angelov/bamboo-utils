require 'bamboo-client'

module Bamboo
  module Client

    class Rest
      class Plan

        def queue_params(params)
          @http.post File.join(SERVICE, "queue/#{URI.escape key}"), params, @http.cookies
        end

      end
    end

  end
end