# -*- coding: utf-8 -*-

require 'dcmgr/endpoints/12.03/responses/security_group'

Dcmgr::Endpoints::V1203::CoreAPI.namespace '/security_groups' do
  
  def send_reference_events(group,old_referencees,new_referencees)
    (old_referencees - new_referencees).each { |ref|
      Dcmgr.messaging.event_publish("#{ref.canonical_uuid}/referencer_removed",:args=>[group.canonical_uuid])
    }
    
    (new_referencees - old_referencees).each { |ref|
      Dcmgr.messaging.event_publish("#{ref.canonical_uuid}/referencer_added",:args=>[group.canonical_uuid])
    }
  end
  
  get do
    # description 'Show lists of the security groups'
    ds = M::SecurityGroup.dataset
    if params[:account_id]
      ds = ds.filter(:account_id=>params[:account_id])
    end
    
    collection_respond_with(ds) do |paging_ds|
      R::SecurityGroupCollection.new(paging_ds).generate
    end
  end

  get '/:id' do
    # description 'Show the security group'
    g = find_by_uuid(:SecurityGroup, params[:id])
    raise E::UnknownSecurityGroup, params[:id] if g.nil?

    respond_with(R::SecurityGroup.new(g).generate)
  end

  post do
    # description 'Register a new security group'
    # params description, string
    # params rule, string
    begin
      g = M::SecurityGroup.create(:account_id=>@account.canonical_uuid,
                                  :description=>params[:description],
                                  :rule=>params[:rule])

      send_reference_events(g,[],g.referencees)
    rescue M::InvalidSecurityGroupRuleSyntax => e
      raise E::InvalidSecurityGroupRule, e.message
    end
    
    respond_with(R::SecurityGroup.new(g).generate)
  end

  put '/:id' do
    # description "Update parameters for the security group"
    # params description, string
    # params rule, string
    g = find_by_uuid(:SecurityGroup, params[:id])

    raise E::UnknownSecurityGroup if g.nil?

    if params[:description]
      g.description = params[:description]
    end
    if params[:rule]
      old_referencees = g.referencees_dataset.to_a
      g.rule = params[:rule]
    end

    begin
      g.save
    rescue M::InvalidSecurityGroupRuleSyntax => e
      raise E::InvalidSecurityGroupRule, e.message
    end

    commit_transaction
    # refresh security group rules on host nodes.
    Dcmgr.messaging.event_publish('hva/security_group_updated', :args=>[g.canonical_uuid])
    Dcmgr.messaging.event_publish("#{g.canonical_uuid}/rules_updated")

    send_reference_events(g,old_referencees,g.referencees) if params[:rule]

    respond_with(R::SecurityGroup.new(g).generate)
  end

  delete '/:id' do
    #description "Delete the security group"
    g = find_by_uuid(:SecurityGroup, params[:id])

    raise E::UnknownSecurityGroup if g.nil?

    # raise E::OperationNotPermitted if g.instances.size > 0
    begin
      g.destroy
    rescue => e
      # logger.error(e)
      raise E::OperationNotPermitted
    end

    response_to([g.canonical_uuid])
  end
end
