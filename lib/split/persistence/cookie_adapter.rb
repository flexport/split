# frozen_string_literal: true
require "json"

module Split
  module Persistence
    class CookieAdapter

      def initialize(context)
        @request, @response = context.request, context.response
        @cookies = @request.cookies
        @expires = Time.now + cookie_length_config
      end

      def [](key)
        hash[key.to_s]
      end

      def []=(key, value)
        set_cookie(hash.merge!(key.to_s => value))
      end

      def delete(key)
        set_cookie(hash.tap { |h| h.delete(key.to_s) })
      end

      def keys
        hash.keys
      end

      private

      def set_cookie(value = {})
        @response.set_cookie :split.to_s, default_options.merge(value: JSON.generate(value))
      end

      # Taken from Rails ActionDispatch::Cookies
      # https://github.com/rails/rails/blob/91ae6531976d0d2e7690bde0c1d5e6cc651f2578/actionpack/lib/action_dispatch/middleware/cookies.rb#L373
      def domain_from_host
        domain_regexp = /[^.]*\.([^.]*|..\...|...\...)$/
        host = @request.host
        domain = if (host !~ /^[\d.]+$/) && (host =~ domain_regexp)
          ".#{$&}"
        end
        domain
      end

      def default_options
        options_base = { expires: @expires, path: '/' }
        explicit_domain = domain_from_host
        if explicit_domain.present?
          options_base.merge({domain: explicit_domain})
        else
          options_base
        end
      end

      def hash
        @hash ||= begin
          if cookies = @cookies[:split.to_s]
            begin
              JSON.parse(cookies)
            rescue JSON::ParserError
              {}
            end
          else
            {}
          end
        end
      end

      def cookie_length_config
        Split.configuration.persistence_cookie_length
      end

    end
  end
end
