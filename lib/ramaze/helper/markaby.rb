#          Copyright (c) 2006 Michael Fellinger m.fellinger@gmail.com
# All files in this distribution are subject to the terms of the Ruby license.

module Ramaze
  module MarkabyHelper
    private

    # use this inside your controller to directly build Markaby
    # Refer to the Markaby-documentation and testsuite for more examples.
    # Usage:
    #   mab { h1 "Apples & Oranges"}                    #=> "<h1>Apples &amp; Oranges</h1>"
    #   mab { h1 'Apples', :class => 'fruits&floots' }  #=> "<h1 class=\"fruits&amp;floots\">Apples</h1>"

    def markaby(ivs = {}, helpers = nil, &block)
      builder = ::Markaby::Builder
      builder.extend(Ramaze::Helper)
      builder.send(:helper, :link)

      iv_hash = {}
      instance_variables.each do |iv|
        key, value = iv.gsub('@', '').to_sym, instance_variable_get(iv)
        iv_hash[key] = value unless ivs
      end

      builder.new(iv_hash.merge(ivs), helpers, &block).to_s
    end

    alias mab markaby
  end
end