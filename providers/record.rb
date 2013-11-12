action :create do
  require "fog"
  require "nokogiri"

  def name
    @name ||= new_resource.name + "."
  end

  def value
    @value ||= new_resource.value
  end

  def type
    @type ||= new_resource.type
  end

  def ttl
    @ttl ||= new_resource.ttl
  end

  def overwrite
    @overwrite ||= new_resource.overwrite
  end

  def zone
    if new_resource.aws_access_key_id and new_resource.aws_secret_access_key
      @zone ||= Fog::DNS.new({ :provider => "aws",
                               :aws_access_key_id => new_resource.aws_access_key_id,
                               :aws_secret_access_key => new_resource.aws_secret_access_key }
                             ).zones.get( new_resource.zone_id )
    else
      Chef::Log.info "No AWS credentials supplied, going to attempt to use IAM roles instead"
      @zone ||= Fog::DNS.new({ :provider => "aws", :use_iam_profile => true }
                             ).zones.get( new_resource.zone_id )
    end
  end

  def create
    begin
      zone.records.create({ :name => name,
                            :value => value,
                            :type => type,
                            :ttl => ttl })
    rescue Excon::Errors::BadRequest => e
      Chef::Log.info Nokogiri::XML( e.response.body ).xpath( "//xmlns:Message" ).text
    end
    new_resource.updated_by_last_action(true)
  end

  record = zone.records.get(name, type)

  if record.nil?
    create
    Chef::Log.info "Record created: #{name}"
    new_resource.updated_by_last_action(true)
  elsif value != record.value.first
    unless overwrite == false
      record.destroy
      create
      Chef::Log.info "Record modified: #{name}"
    else
      Chef::Log.info "Record #{name} should have been modified, but overwrite is set to false."
      Chef::Log.debug "Current value: #{record.value.first}"
      Chef::Log.debug "Desired value: #{value}"
    end
  end
end

action :delete do
  require "fog"
  require "nokogiri"

  def name
    @name ||= new_resource.name + "."
  end

  def type
    @type ||= new_resource.type
  end

  def zone
    if new_resource.aws_access_key_id and new_resource.aws_secret_access_key
      @zone ||= Fog::DNS.new({ :provider => "aws",
                               :aws_access_key_id => new_resource.aws_access_key_id,
                               :aws_secret_access_key => new_resource.aws_secret_access_key }
                             ).zones.get( new_resource.zone_id )
    else
      Chef::Log.info "No AWS credentials supplied, going to attempt to use IAM roles instead"
      @zone ||= Fog::DNS.new({ :provider => "aws", :use_iam_profile => true }
                             ).zones.get( new_resource.zone_id )
    end
  end

  record = zone.records.all.select do |record|
    record.name == name && record.type == type
  end.first

  if not record.nil?
    record.destroy
    create
    Chef::Log.info "Record modified: #{name}"
    new_resource.updated_by_last_action(true)
  end
end
