class CabooseRets::RetsMailer < ActionMailer::Base

  def from_address(site_id, from_name)
    settings = Caboose::SmtpConfig.where(:site_id => site_id).first
    fn = from_name.blank? ? (settings ? settings.site.description : "Caboose CMS") : from_name
    fn = fn.gsub(",","").gsub("<","").gsub(">","").gsub("@","").gsub(":","").truncate(30)
    return settings ? "#{fn} <#{settings.from_address}>" : "#{fn} <noreply@caboosecms.com>"
  end

  def new_user(agent, user)
    @agent = agent
    @user = user
    @site = user.site
    to_address = Rails.env.development? ? 'billy@nine.is' : agent.email
    bcc_address = Rails.env.development? ? 'billyswifty@gmail.com' : @site.contact_email
    mail(
      :to => to_address,
      :bcc => bcc_address,
      :from => from_address(@site.id, nil),
      :subject => "New User Registration",
      :reply_to => bcc_address
    )
  end

  def user_welcome(agent, user)
    @agent = agent
    @user = user
    @site = user.site
    to_address = user.email
    bcc_address = Rails.env.development? ? 'billyswifty@gmail.com' : @site.contact_email
    reply_to = @site.contact_email.blank? ? 'noreply@caboosecms.com' : @site.contact_email

    setting = Caboose::Setting.where(:site_id => @site.id, :name => "welcome_email_subject").first
    subject = setting && !setting.value.blank? ? setting.value : "Welcome to #{@site.description}"

    setting2 = Caboose::Setting.where(:site_id => @site.id, :name => "welcome_email_body").first
    @body = setting2 && !setting2.value.blank? ? setting2.value : "We're excited to see that you've registered for #{@site.description}. As a registered user, we'll notify you when there's a price drop or pending sale on your favorite properties. We'll also notify you of new listings and similar properties you may be interested in. Your assigned REALTOR® is |agent_name| and will be in touch with you shortly. Thank you for choosing #{@site.description}!"
    @body = @body.gsub("|agent_name|", "#{@agent.first_name} #{@agent.last_name}")

    @color = @site.theme ? @site.theme.color_main : @site.theme_color

    @url = "https://#{@site.primary_domain.domain}"
    @url += "/real-estate" if @site.id == 541

    @logo_url = @site.logo.url(:large)
    @logo_url = "https:#{@logo_url}" if !@logo_url.include?('http')

    @unsubscribe_url = "https://#{@site.primary_domain.domain}/rets-unsubscribe?token=7b8v9j#{@user.id}9b6h0c2n"

    mail(
      :to => to_address,
      :bcc => bcc_address,
      :from => from_address(@site.id, nil),
      :subject => subject,
      :reply_to => reply_to
    )
  end

  def daily_report(user, new_listings, related_listings)
    @user = user
    @new_listings = new_listings
    @related_listings = related_listings
    @site = user.site
    to_address = user.email
    reply_to = @site.contact_email.blank? ? 'noreply@caboosecms.com' : @site.contact_email
    @color = @site.theme ? @site.theme.color_main : @site.theme_color
    @domain = "https://#{@site.primary_domain.domain}"
    @domain = "http://dev.pmre.com:3000" if Rails.env.development?
    @url = @domain
    @url += "/real-estate" if @site.id == 541
    @logo_url = @site.logo.url(:large)
    subject = @site.id == 541 ? "New and Suggested Listings from Pritchett-Moore Real Estate" : "New and Suggested Listings from #{@site.description}"
    @logo_url = "https:#{@logo_url}" if !@logo_url.include?('http')
    @unsubscribe_url = "https://#{@site.primary_domain.domain}/rets-unsubscribe?token=7b8v9j#{@user.id}9b6h0c2n"
    mail(
      :to => to_address,
      :from => from_address(@site.id, nil),
      :subject => subject,
      :reply_to => reply_to
    )
  end

  def property_status_change(user, property, old_status)
    @user = user
    @property = property
    @old_status = old_status
    @site = user.site
    to_address = user.email
    reply_to = @site.contact_email.blank? ? 'noreply@caboosecms.com' : @site.contact_email
    @color = @site.theme ? @site.theme.color_main : @site.theme_color
    @domain = "https://#{@site.primary_domain.domain}"
    @domain = "http://dev.pmre.com:3000" if Rails.env.development?
    @url = @domain
    @url += "/real-estate" if @site.id == 541
    @logo_url = @site.logo.url(:large)
    subject = "Status Change for Listing MLS ##{@property.mls_number}"
    @logo_url = "https:#{@logo_url}" if !@logo_url.include?('http')
    @unsubscribe_url = "https://#{@site.primary_domain.domain}/rets-unsubscribe?token=7b8v9j#{@user.id}9b6h0c2n"
    mail(
      :to => to_address,
      :from => from_address(@site.id, nil),
      :subject => subject,
      :reply_to => reply_to
    )
  end

  def property_price_change(user, property, old_price)
    @user = user
    @property = property
    @old_price = old_price
    @site = user.site
    to_address = user.email
    reply_to = @site.contact_email.blank? ? 'noreply@caboosecms.com' : @site.contact_email
    @color = @site.theme ? @site.theme.color_main : @site.theme_color
    @domain = "https://#{@site.primary_domain.domain}"
    @domain = "http://dev.pmre.com:3000" if Rails.env.development?
    @url = @domain
    @url += "/real-estate" if @site.id == 541
    @logo_url = @site.logo.url(:large)
    subject = "Price Change for Listing MLS ##{@property.mls_number}"
    @logo_url = "https:#{@logo_url}" if !@logo_url.include?('http')
    @unsubscribe_url = "https://#{@site.primary_domain.domain}/rets-unsubscribe?token=7b8v9j#{@user.id}9b6h0c2n"
    mail(
      :to => to_address,
      :from => from_address(@site.id, nil),
      :subject => subject,
      :reply_to => reply_to
    )
  end

end