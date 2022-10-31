class Admin::OperatorPortal::Fom::StepcgController < Admin::OperatorPortal::FomController

# WARNING: modifying this file is not recommended unless you are familiar with
# developing for the Ruby on Rails web application framework!
#
# This class inherits the default FOM operator portal's action methods from
# FomController. Methods defined here will be available as custom actions of
# this custom controller.
#
  before_action :hurricane_status
  def hurricane_status
    @hurricane_status = IpGroup.find_by(name: "Hurricane-ON").try(:addresses).to_a.any?
  end

  def hurricane_mode_on
   if template = ConfigTemplate.find_by(name: 'Hurricane Mode ON')
     if template.apply_template(current_admin: current_admin, client_ip: client_ip)
       flash[:notice] = 'Hurricane Mode ON!'
     else
       flash[:error] = 'Error Activating Hurricane Mode'
     end
    else
      flash[:error] = 'Hurricane Mode Not Configured'
    end
    redirect_to action: :hurricane_mode
  end

  def hurricane_mode_off
   if template = ConfigTemplate.find_by(name: 'Hurricane Mode OFF')
     if template.apply_template(current_admin: current_admin, client_ip: client_ip)
       flash[:notice] = 'Hurricane Mode OFF!'
     else
       flash[:error] = 'Error Deactivating Hurricane Mode'
     end
    else
      flash[:error] = 'Hurricane Mode Not Configured'
    end
    redirect_to action: :hurricane_mode
  end

  def mac_group_batch_operation

    strong_params = params.permit(:mac_group, :macs, :add_macs, :delete_macs, :utf8, :authenticity_token)

    mac_group = strong_params[:mac_group]
    macs = strong_params[:macs]
    add_macs = strong_params[:add_macs]
    delete_macs = strong_params[:delete_macs]

    ok = true

    unless @mac_group = MacGroup.find_by(id: mac_group)
      @notice = 'Mac Group not found'
      ok = false
    end

    unless add_macs || delete_macs
      @notice = 'Must Speciffy Add or Delete Macs'
      ok = false
    end

    @macs = []

    if ok
      macs.split(/[\s+,]/).reject(&:blank?).each_with_index do |mac, index|
        a_mac = Mac.clean_mac(mac.strip)
        unless Mac.is_valid_mac?(a_mac)
          @notice = "Invalid MAC at line #{index + 1}: #{mac}"
          ok = false
          break
        else 
          @macs << a_mac
        end
      end
    end

    if ok
      word = ''
      if add_macs
        some_macs = @macs.uniq.reject { |mac| @mac_group.macs.collect(&:mac).include? mac}.compact.collect { |mac| Mac.new(mac: mac) }
        @mac_group.macs.concat some_macs
        word = 'added to'
      elsif delete_macs
        @mac_group.macs.where('mac in (?)', @macs.compact).delete_all
        word = 'deleted from'
      end
      @mac_group.save
      @notice = "#{@macs.count} #{'MAC Address'.pluralize(@macs.count)} #{word} MAC Group #{@mac_group.name} (#{@mac_group.id})"
    end

    render_last_action_or_default :mac_group
  end

end
