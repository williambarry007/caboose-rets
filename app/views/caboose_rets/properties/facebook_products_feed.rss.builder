domain = Caboose::Domain.where(:site_id => @site.id, :primary => true).first.domain
hp = Caboose::Page.where(:site_id => @site.id, :title => "Home").first
xml.instruct! :xml, :version => "1.0"
xml.rss :version => "2.0", "xmlns:g" => "http://base.google.com/ns/1.0" do
  xml.channel do
    xml.title @site.description
    xml.description hp ? hp.meta_description : @site.description
    xml.link "https://" + domain
    xml.language "en"
    for property in @properties
      xml.item do
        xml.g(:id, property.mls_number)
        xml.g(:title, property.full_address)
        xml.g(:description, property.public_remarks)
        xml.g(:link, "https://" + domain + "/properties/#{property.mls_number}/details?utm_source=Nine&utm_medium=Facebook&utm_campaign=Retargeting")
        first_image = property.images.first if property.images
        m = Caboose::Media.where(:id => first_image.media_id).first if first_image && !first_image.media_id.blank?
        if m && m.image
          xml.g(:image_link, "https:" + m.image.url(:large))
        else
          xml.g(:image_link, 'https://cabooseit.s3.amazonaws.com/rets/house.png')
        end
        if !property.construction_status.blank?
          if property.construction_status.include?('New') || property.construction_status.include?('Under Construction') || property.construction_status.include?('Proposed Construction')
            xml.g(:condition, 'new')
          else
            xml.g(:condition, 'used')
          end
        else
          xml.g(:condition, 'used')
        end
        xml.g(:price, number_to_currency(property.list_price).gsub("$","") + " USD")
        xml.g(:availability, 'in stock')
        xml.g(:brand, @site.description)
      end
    end
  end
end
