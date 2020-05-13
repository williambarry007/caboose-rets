class CabooseRets::RetsMailer < ActionMailer::Base

  default from: "noreply <noreply@caboosecms.com>"

  def new_user(agent, user, from_address)
    @agent = agent
    @user = user
    @site = user.site
    to_address = Rails.env.development? ? 'billy@nine.is' : agent.email
    bcc_address = Rails.env.development? ? 'billyswifty@gmail.com' : @site.contact_email
    mail(
      :to => to_address,
      :bcc => bcc_address,
      :from => from_address,
      :subject => "New User Registration",
      :reply_to => bcc_address
    )
  end

end