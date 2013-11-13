# Author:: Mike Evans <mike@urlgonomics.com>
# Copyright:: 2013 Urlgonomics LLC.
# License:: Apache License, Version 2.0
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

module Couchbase::Operations
  module Utils

    private

    def validate_key(key)
      if key_prefix
        "#{key_prefix}key"
      else
        key.to_s
      end
    end

    def extract_options_hash(args)
      if args.size > 1 && args.last.respond_to?(:to_hash)
        args.pop
      else
        {}
      end
    end

    def sync_block_error
      raise ArgumentError, "synchronous mode doesn't support callbacks"
    end

    def not_found_error(error, options = {})
      if error
        if options.key?(:quiet)
          raise Couchbase::Error::NotFound.new if !options[:quiet]
        elsif !quiet?
          raise Couchbase::Error::NotFound.new
        end
      end
    end

    def future_cas(future)
      future.get && future.getCas
    rescue Java::JavaLang::UnsupportedOperationException
      # TODO: don't return fake cas
      1
    end

  end
end
