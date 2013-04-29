require 'bamboo-client'

class Bamboo::Client::Rest::Plan

  def queue(params)
    @http.post File.join(SERVICE, "queue/#{URI.escape key}"), params, @http.cookies
  end

end