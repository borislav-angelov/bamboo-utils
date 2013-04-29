require 'bamboo-client'

module Bamboo
  module Client

    class Rest
      class Plan

        def queue
          data = "repositoryFullName=spookysv/bamboo-pull-requests"
          @http.post File.join(SERVICE, "queue/#{URI.escape key}"), data, @http.cookies
        end

      end
    end

  end
end