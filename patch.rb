require 'bamboo-client'

module Bamboo
  module Client

    class Rest
      class Plan

        def queue(params)
          key = key + "?repositoryFullName=spookysv/bamboo-pull-requests"
          puts key
          @http.post File.join(SERVICE, "queue/#{URI.escape key}"), params, @http.cookies
        end

      end
    end

  end
end