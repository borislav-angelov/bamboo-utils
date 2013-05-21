
module Bamboo
  module Client
    module Http
      class Json < Abstract

        class Doc

          def auto_expand(klass, client)
            key_to_expand = @data.fetch('expand')

            obj = @data[key_to_expand]
            if obj
              case obj
                when Hash
                  if obj.has_key?('expand')
                    Doc.new(obj).auto_expand(klass, client)
                  else
                    klass.new(obj, client)
                  end
                when Array
                  obj.map { |e| klass.new(e, client) }
                else
                  raise TypeError, "don't know how to auto-expand #{obj.inspect}"
              end
            end
          end

        end # Doc

        def post(uri_or_path, data = {}, cookies = nil, query = nil)
          resp = RestClient.post(uri_for(uri_or_path, query), data.to_json, :accept => :json, :content_type => :json, :cookies => cookies)
          Doc.from(resp) unless resp.empty?
        end

      end # Json
    end # Http

    class Rest < Abstract
      class Plan

        def latest_results
          doc = @http.get File.join(SERVICE, "result/#{URI.escape key}/latest"), {}, @http.cookies
          doc.auto_expand Result, @http
        end

        def queue(query = nil)
          @http.post File.join(SERVICE, "queue/#{URI.escape key}"), {}, @http.cookies, query
        end

      end # Plan
    end # Rest

  end # Client
end # Bamboo