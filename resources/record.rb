actions :create, :delete

default_action :create

attribute :name,                  :kind_of => String
attribute :value,                 :kind_of => String
attribute :type,                  :kind_of => String
attribute :zone_id,               :kind_of => String
attribute :aws_access_key_id,     :kind_of => String, :required => false
attribute :aws_secret_access_key, :kind_of => String, :required => false
attribute :ttl,                   :kind_of => String, :default => "300"
attribute :overwrite,             :kind_of => [ TrueClass, FalseClass ], :default => true
