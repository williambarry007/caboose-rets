domain = Caboose::Domain.where(:site_id => @site.id, :primary => true).first.domain
hp = Caboose::Page.where(:site_id => @site.id, :title => "Home").first
xml.instruct! :xml, :version => "1.0"
#xml.rss :version => "2.0", "xmlns:g" => "http://base.google.com/ns/1.0" do
  xml.listings do
    xml.title @site.description
 #   xml.description hp ? hp.meta_description : @site.description
    xml.link(("https://" + domain), :rel => "self")
  #  xml.language "en"
    for property in @properties
      xml.listing do
        kind = "#{property.res_style} #{property.style} #{property.property_type} #{property.property_subtype}" 
        xml.home_listing_id(property.mls_number)
        xml.name(property.full_address)
        xml.availability('for_sale')
        xml.description(property.public_remarks)
        xml.address :format => "simple" do 
          xml.component(property.full_address, :name => "addr1")
          xml.component(property.city, :name => "city")
          xml.component(property.state_or_province, :name => "region")
          xml.component("United States", :name => "country")
          xml.component(property.postal_code, :name => "postal_code")
        end
        xml.image do 
          property.images.each do |pi|
            m = Caboose::Media.find(pi.media_id)
            xml.url("https:" + m.image.url(:large)) if m
          end
        end
        xml.latitude(property.latitude.blank? ? '33.2098' : property.latitude)
        xml.longitude(property.longitude.blank? ? '-87.5692' : property.longitude)
        xml.neighborhood(property.subdivision)
        xml.listing_type('for_sale_by_agent')
        xml.num_baths(property.baths_total)
        xml.num_beds(property.beds_total)
        xml.url("https://" + domain + "/properties/#{property.mls_number}/details")
        xml.year_built(property.year_built)
        if !property.property_type.blank?
          if kind.include?('Land')
            xml.property_type('land')
          elsif kind.include?('Commercial')
            xml.property_type('other')
          elsif kind.include?('Condo')
            xml.property_type('condo')
          elsif kind.include?('Town') || kind.include?('Duplex')
            xml.property_type('townhouse')
          elsif kind.include?('Manufactured') || kind.include?('Prefab')
            xml.property_type('manufactured')
          elsif kind.include?('Other')
            xml.property_type('other')
          else
            xml.property_type('house')
          end
        else
          xml.property_type('house')
        end
        xml.price(number_to_currency(property.list_price).gsub("$","") + " USD")
        xml.availability('for_sale')
      end
    end
#  end
end