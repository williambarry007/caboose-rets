
class CabooseRets::LandProperty < ActiveRecord::Base
  self.table_name = "rets_land"

  def url()     return "/land/#{self.id}" end  
  def agent()   return CabooseRets::Agent.where(:la_code => self.la_code).first end  
  def office()  return CabooseRets::Office.where(:lo_code => self.lo_code).first end
  def images()  return CabooseRets::Media.where(:mls_acct => self.mls_acct).order(:media_order).all end
    
  def virtual_tour
    return nil if !CabooseRets::Media.exists?("mls_acct = '#{self.mls_acct}' and media_type = 'Virtual Tour'")
    media = CabooseRets::Media.where(:mls_acct => self.mls_acct, :media_type => 'Virtual Tour').first
    return media.url    
  end
  
  def self.geolocatable()   all(conditions: "latitude IS NOT NULL AND longitude IS NOT NULL") end
  #def self.property_types() self.unique_field("prop_type"     ) end    
  #def self.statuses()       self.unique_field("status"        ) end
  #def self.zips()           self.unique_field("zip"           ) end
  #def self.cities()         self.unique_field("city"          ) end
  #def self.counties()       self.unique_field("county"        ) end    
  #def self.subdivisions()   self.unique_field("subdivision"   ) end
  #def self.elem_schools()   self.unique_field("elem_school"   ) end
  #def self.middle_schools() self.unique_field("middle_school" ) end
  #def self.high_schools()   self.unique_field("high_school"   ) end

  def parse(data)
    self.acreage                    = data['ACREAGE']
    self.acreage_source             = data['ACREAGE_SOURCE']
    self.adjoining_land_use         = data['ADJOINING_LAND_USE']
    self.agent_notes                = data['AGENT_NOTES']
    self.agent_other_contact_desc   = data['AGENT_OTHER_CONTACT_DESC']
    self.agent_other_contact_phone  = data['AGENT_OTHER_CONTACT_PHONE']
    self.annual_taxes               = data['ANNUAL_TAXES']
    self.area                       = data['AREA']
    self.bom_date                   = data['BOM_DATE']
    self.book_number                = data['BOOK_NUMBER']
    self.book_page                  = data['BOOK_PAGE']
    self.book_type                  = data['BOOK_TYPE']
    self.buyer_broker               = data['BUYER_BROKER']
    self.buyer_broker_type          = data['BUYER_BROKER_TYPE']
    self.buyer_name                 = data['BUYER_NAME']
    self.category                   = data['CATEGORY']
    self.city                       = data['CITY']
    self.city_code                  = data['CITY_CODE']
    self.co_la_code                 = data['CO_LA_CODE']
    self.co_lo_code                 = data['CO_LO_CODE']
    self.co_sa_code                 = data['CO_SA_CODE']
    self.co_so_code                 = data['CO_SO_CODE']
    self.contacts                   = data['CONTACTS']
    self.contr_broker               = data['CONTR_BROKER']
    self.contr_broker_type          = data['CONTR_BROKER_TYPE']
    self.converted                  = data['CONVERTED']
    self.county                     = data['COUNTY']
    self.current_price              = data['CURRENT_PRICE']
    self.date_created               = data['DATE_CREATED']
    self.date_modified              = data['DATE_MODIFIED']
    self.df_yn                      = data['DF_YN']
    self.directions                 = data['DIRECTIONS']
    self.display_address_yn         = data['DISPLAY_ADDRESS_YN']
    self.dom                        = data['DOM']
    self.elem_school                = data['ELEM_SCHOOL']
    self.expire_date                = data['EXPIRE_DATE']
    self.ftr_access                 = data['FTR_ACCESS']
    self.ftr_docs_on_file           = data['FTR_DOCS_ON_FILE']
    self.ftr_existing_struct        = data['FTR_EXISTING_STRUCT']
    self.ftr_extras                 = data['FTR_EXTRAS']
    self.ftr_internet               = data['FTR_INTERNET']
    self.ftr_lotdesc                = data['FTR_LOTDESC']
    self.ftr_mineralrights          = data['FTR_MINERALRIGHTS']
    self.ftr_possibleuse            = data['FTR_POSSIBLEUSE']
    self.ftr_restrictions           = data['FTR_RESTRICTIONS']
    self.ftr_sewer                  = data['FTR_SEWER']
    self.ftr_showing                = data['FTR_SHOWING']
    self.ftr_terms                  = data['FTR_TERMS']
    self.ftr_topography             = data['FTR_TOPOGRAPHY']
    self.ftr_utils                  = data['FTR_UTILS']
    self.ftr_zoning                 = data['FTR_ZONING']
    self.geo_precision              = data['GEO_PRECISION']
    self.georesult                  = data['GEORESULT']
    self.high_school                = data['HIGH_SCHOOL']
    self.internet_yn                = data['INTERNET_YN']
    self.la_code                    = data['LA_CODE']
    self.legal_block                = data['LEGAL_BLOCK']
    self.legal_lot                  = data['LEGAL_LOT']
    self.legal_section              = data['LEGAL_SECTION']
    self.legals                     = data['LEGALS']
    self.list_date                  = data['LIST_DATE']
    self.list_price                 = data['LIST_PRICE']
    self.listing_type               = data['LISTING_TYPE']
    self.lo_code                    = data['LO_CODE']
    self.lot_dim_source             = data['LOT_DIM_SOURCE']
    self.lot_dimensions             = data['LOT_DIMENSIONS']
    self.media_flag                 = data['MEDIA_FLAG']
    self.middle_school              = data['MIDDLE_SCHOOL']
    self.mls_acct                   = data['MLS_ACCT']
    self.municipality               = data['MUNICIPALITY']
    self.off_mkt_date               = data['OFF_MKT_DATE']
    self.off_mkt_days               = data['OFF_MKT_DAYS']
    self.office_notes               = data['OFFICE_NOTES']
    self.orig_lp                    = data['ORIG_LP']
    self.orig_price                 = data['ORIG_PRICE']
    self.other_fee                  = data['OTHER_FEE']
    self.other_fee_type             = data['OTHER_FEE_TYPE']
    self.owner_name                 = data['OWNER_NAME']
    self.owner_phone                = data['OWNER_PHONE']
    self.parcel_id                  = data['PARCEL_ID']
    self.pending_date               = data['PENDING_DATE']
    self.photo_count                = data['PHOTO_COUNT']
    self.photo_date_modified        = data['PHOTO_DATE_MODIFIED']
    self.price_change_date          = data['PRICE_CHANGE_DATE']
    self.price_sqft                 = data['PRICE_SQFT']
    self.proj_close_date            = data['PROJ_CLOSE_DATE']
    self.prop_id                    = data['PROP_ID']
    self.prop_type                  = data['PROP_TYPE']
    self.remarks                    = data['REMARKS']
    self.road_frontage_ft           = data['ROAD_FRONTAGE_FT']
    self.sa_code                    = data['SA_CODE']
    self.sale_lease                 = data['SALE_LEASE']
    self.sale_notes                 = data['SALE_NOTES']
    self.so_code                    = data['SO_CODE']
    self.sold_date                  = data['SOLD_DATE']
    self.sold_price                 = data['SOLD_PRICE']
    self.sold_terms                 = data['SOLD_TERMS']
    self.state                      = data['STATE']
    self.status                     = data['STATUS']
    self.status_date                = data['STATUS_DATE']
    self.status_flag                = data['STATUS_FLAG']
    self.street                     = data['STREET']
    self.street_dir                 = data['STREET_DIR']
    self.street_name                = data['STREET_NAME']
    self.street_num                 = data['STREET_NUM']
    self.sub_agent                  = data['SUB_AGENT']
    self.sub_agent_type             = data['SUB_AGENT_TYPE']
    self.subdivision                = data['SUBDIVISION']
    self.third_party_comm_yn        = data['THIRD_PARTY_COMM_YN']
    self.unit_num                   = data['UNIT_NUM']
    self.upload_source              = data['UPLOAD_SOURCE']
    self.valuation_yn               = data['VALUATION_YN']
    self.vt_yn                      = data['VT_YN']
    self.waterfront                 = data['WATERFRONT']
    self.waterfront_yn              = data['WATERFRONT_YN']
    self.wf_feet                    = data['WF_FEET']
    self.withdrawn_date             = data['WITHDRAWN_DATE']
    self.zip                        = data['ZIP']
    self.zoning_northport           = data['ZONING_NORTHPORT']
    self.zoning_tusc                = data['ZONING_TUSC']    
	end
end
