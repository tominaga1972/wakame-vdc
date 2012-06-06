# -*- coding: utf-8 -*-
module Hijiki::DcmgrResource::V1203
  module SecurityGroupMethods
    def self.included(base)
      base.extend(ClassMethods)
    end
    
    module ClassMethods
      def create(params)
        security_group = self.new
        security_group.display_name = params[:display_name]
        security_group.description = params[:description]
        security_group.rule = params[:rule]
        security_group.save
        security_group
      end

      def update(uuid,params)
        self.put(uuid,params).body
      end
      
      def destroy(uuid)
        self.delete(uuid).body
      end      
    end

    # workaround for the bug:
    #  the value of the key "rule" is encoded to JSON wrongly by
    #  ActiveSupport::JSON encoder.
    #  "{\"security_group\":{\"description\":\"\",\"rule\":[[null,[],null]]}}"
    #  So it has to use the encoder from JSON library.
    def to_json(options={})
      require 'json'
      {'security_group'=>@attributes}.to_json
    end
  end

  class SecurityGroup < Base
    include Hijiki::DcmgrResource::ListMethods
    include SecurityGroupMethods
  end
end
