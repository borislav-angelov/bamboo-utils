require 'bamboo-client'

module Bamboo
  module Client

    class Rest
      class Plan

        def queue
          @http.post File.join(SERVICE, "queue/#{URI.escape key}?repositoryFullName=spookysv/bamboo-pull-requests"), {}, @http.cookies
        end

      end
    end

  end
end