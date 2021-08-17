class CabooseRets::Notification < ActiveRecord::Base

  self.table_name = "rets_notifications"

  belongs_to :user, :class_name => "Caboose::User"
  belongs_to :site, :class_name => "Caboose::Site"

  def self.property_status_changed(property, old_status)
    return if property.nil?
    
    us = Caboose::Setting.where(:site_id => 541, :name => "test_usernames").first
    allowed_users = us ? us.value : ""
    allowed_users = 'billyswifty' if Rails.env.development?
    uwhere = allowed_users.blank? ? "" : "('#{allowed_users}' ILIKE '%' || username || '%')"

    user_ids = CabooseRets::SavedProperty.where(:mls_number => property.mls_number).pluck(:user_id)
    if user_ids.count > 0
      user_ids.each do |user_id|
        user = Caboose::User.where(uwhere).where(:id => user_id, :tax_exempt => false).first
        d1 = DateTime.now - 24.hours
        if user && user.site && user.site.use_rets && !Caboose::BouncedEmail.where(:email_address => user.email).exists?
          # Check if a similar notification has already been sent
          n = CabooseRets::Notification.where(
            :user_id => user.id,
            :site_id => user.site_id,
            :kind => "Property Status Changed",
            :sent_to => user.email,
            :object_kind => "Property",
            :object_id => property.mls_number,
            :old_value => old_status,
            :new_value => property.status
          ).where("date_sent >= ?", d1).first
          if n.nil?
            n = CabooseRets::Notification.create(
              :user_id => user.id,
              :site_id => user.site_id,
              :date_sent => DateTime.now,
              :kind => "Property Status Changed",
              :sent_to => user.email,
              :object_kind => "Property",
              :object_id => property.mls_number,
              :old_value => old_status,
              :new_value => property.status
            )
            CabooseRets::RetsMailer.configure_for_site(user.site_id).property_status_change(user, property, old_status).deliver_later
          else
            puts "Found a duplicate notification, not sending..."
          end
        end
      end
    end
  end

  def self.property_price_changed(property, old_price)
    return if property.nil? || property.status != 'Active'
    
    us = Caboose::Setting.where(:site_id => 541, :name => "test_usernames").first
    allowed_users = us ? us.value : ""
    allowed_users = 'billyswifty' if Rails.env.development?
    uwhere = allowed_users.blank? ? "" : "('#{allowed_users}' ILIKE '%' || username || '%')"

    user_ids = CabooseRets::SavedProperty.where(:mls_number => property.mls_number).pluck(:user_id)
    if user_ids.count > 0
      user_ids.each do |user_id|
        user = Caboose::User.where(uwhere).where(:id => user_id, :tax_exempt => false).first
        d1 = DateTime.now - 24.hours
        if user && user.site && user.site.use_rets && !Caboose::BouncedEmail.where(:email_address => user.email).exists?
          # Check if a similar notification has already been sent
          n = CabooseRets::Notification.where(
            :user_id => user.id,
            :site_id => user.site_id,
            :kind => "Property Price Changed",
            :sent_to => user.email,
            :object_kind => "Property",
            :object_id => property.mls_number,
            :old_value => old_price,
            :new_value => property.list_price
          ).where("date_sent >= ?", d1).first
          if n.nil?
            n = CabooseRets::Notification.create(
              :user_id => user.id,
              :site_id => user.site_id,
              :date_sent => DateTime.now,
              :kind => "Property Price Changed",
              :sent_to => user.email,
              :object_kind => "Property",
              :object_id => property.mls_number,
              :old_value => old_price,
              :new_value => property.list_price
            )
            CabooseRets::RetsMailer.configure_for_site(user.site_id).property_price_change(user, property, old_price).deliver_later
          else
            puts "Found a duplicate notification, not sending..."
          end
        end
      end
    end
  end

  def self.send_new_suggested_emails
    roles = Caboose::Role.where(:name => "RETS Visitor").order(:id).all
    if roles.count > 0
      role_ids = roles.map{|r| r.id}

      us = Caboose::Setting.where(:site_id => 541, :name => "test_usernames").first
      allowed_users = us ? us.value : ""
      allowed_users = 'billyswifty' if Rails.env.development?
      uwhere = allowed_users.blank? ? "" : "('#{allowed_users}' ILIKE '%' || username || '%')"
      
      users = Caboose::User.joins(:role_memberships).where(uwhere).where("role_memberships.role_id in (?)", role_ids).where(:tax_exempt => false).order(:id).all
      
      if users.count > 0

        new_listings = CabooseRets::Property.where(:status => 'Active', :property_type => 'Residential').order('original_entry_timestamp desc').take(3)

        users.each do |user|

          next if user.email.blank? || Caboose::BouncedEmail.where(:email_address => user.email).exists?

          puts "Gathering data for user: #{user.username}" if Rails.env.development?

          saved_mls = CabooseRets::SavedProperty.where(:user_id => user.id).pluck(:mls_number)
          saved_properties = saved_mls && saved_mls.count > 0 ? CabooseRets::Property.where(:status => 'Active', :property_type => 'Residential').where(:mls_number => saved_mls).limit(100) : []

          if saved_properties.count > 0

            puts "Saved listings: #{saved_properties.count}" if Rails.env.development?

            price_where = "list_price is not null and (list_price >= ? AND list_price <= ?)"
            beds_where = "beds_total is not null and (beds_total >= ? AND beds_total <= ?)"

            all_prices = saved_properties.map{|p| p.list_price}
            price_min = all_prices.count > 0 ? (all_prices.min * 0.8) : 150000
            price_max = all_prices.count > 0 ? (all_prices.max * 1.2) : 350000

            puts "Price range: #{price_min} - #{price_max}" if Rails.env.development?

            all_beds = saved_properties.map{|p| p.beds_total}
            beds_min = all_beds.count > 0 ? (all_beds.min - 1) : 2
            beds_max = all_beds.count > 0 ? (all_beds.max + 1) : 5

            puts "Beds range: #{beds_min} - #{beds_max}" if Rails.env.development?

            property_subtypes = []
            property_areas = []

            saved_properties.each do |sp|
              property_subtypes << sp.property_subtype if !property_subtypes.include?(sp.property_subtype)
              property_areas << sp.area if !property_areas.include?(sp.area)
            end

            puts "Property subtypes: #{property_subtypes}" if Rails.env.development?
            puts "Property areas: #{property_areas}" if Rails.env.development?

            related_listings = CabooseRets::Property.where(:property_type => 'Residential', :status => 'Active', :property_subtype => property_subtypes, :area => property_areas).where("mls_number not in (?)", saved_mls).where(price_where,price_min,price_max).where(beds_where,beds_min,beds_max).order('original_entry_timestamp desc').take(3)

          else

            related_listings = []

          end

          if new_listings.count > 0 || related_listings.count > 0

            msg = ""

            if new_listings.count > 0
              mls1 = new_listings.map{ |l| l.mls_number }
              msg += "New Listings: #{mls1.join(', ')}"
            end

            if related_listings.count > 0
              mls2 = related_listings.map{ |l| l.mls_number }
              msg += "\n" if new_listings.count > 0
              msg += "Related Listings: #{mls2.join(', ')}"
            end

            d = DateTime.now - 7.days
            n = CabooseRets::Notification.where(
              :user_id => user.id,
              :site_id => user.site_id,
              :kind => "New and Suggested Listings",
              :sent_to => user.email,
              :message => msg
            ).where("date_sent >= ?", d).first

            if n.nil?
              n = CabooseRets::Notification.create(
                :user_id => user.id,
                :site_id => user.site_id,
                :date_sent => DateTime.now,
                :kind => "New and Suggested Listings",
                :sent_to => user.email,
                :message => msg
              )
              CabooseRets::RetsMailer.configure_for_site(user.site_id).daily_report(user, new_listings, related_listings).deliver_later
            else
              puts "Found a duplicate notification, not sending..."
            end

          end

        end
      end
    end
  end
  
end