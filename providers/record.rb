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
    @zone ||= Fog::DNS.new({ :provider => "aws",
                             :aws_access_key_id => new_resource.aws_access_key_id,
                             :aws_secret_access_key => new_resource.aws_secret_access_key }
                           ).zones.get( new_resource.zone_id )
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
    if overwrite
      record.destroy
      create
      Chef::Log.info "Record overwritten: #{name}"
    else
      record.destroy
      record.value << value
      record.save
      new_resource.updated_by_last_action(true)
      Chef::Log.info "Record appended: #{name}"
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
    @zone ||= Fog::DNS.new({ :provider => "aws",
                             :aws_access_key_id => new_resource.aws_access_key_id,
                             :aws_secret_access_key => new_resource.aws_secret_access_key }
                           ).zones.get( new_resource.zone_id )
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
