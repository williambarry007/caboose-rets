
class CabooseRets::MultiFamilyProperty < ActiveRecord::Base
  self.table_name = "rets_multi_family"

  def agent
    return Agent.where(:la_code => self.la_code).first
  end
  
  def office
    return Office.where(:lo_code => self.lo_code).first
  end
  
  def images
    return Media.where(:mls_acct => self.id).order(:media_order).all
  end
  
  def self.geolocatable
    all(conditions: "latitude IS NOT NULL AND longitude IS NOT NULL")
  end

  def parse(data)
    self.acreage                   = data['ACREAGE']
    self.agent_notes               = data['AGENT_NOTES']
    self.agent_other_contact_desc  = data['AGENT_OTHER_CONTACT_DESC']
    self.agent_other_contact_phone = data['AGENT_OTHER_CONTACT_PHONE']
    self.annual_taxes              = data['ANNUAL_TAXES']
    self.area                      = data['AREA']
    self.bom_date                  = data['BOM_DATE']
    self.book_number               = data['BOOK_NUMBER']
    self.book_page                 = data['BOOK_PAGE']
    self.book_type                 = data['BOOK_TYPE']
    self.box_on_unit               = data['BOX_ON_UNIT']
    self.buyer_broker              = data['BUYER_BROKER']
    self.buyer_broker_type         = data['BUYER_BROKER_TYPE']
    self.buyer_name                = data['BUYER_NAME']
    self.category                  = data['CATEGORY']
    self.city                      = data['CITY']
    self.city_code                 = data['CITY_CODE']
    self.contacts                  = data['CONTACTS']
    self.contr_broker              = data['CONTR_BROKER']
    self.contr_broker_type         = data['CONTR_BROKER_TYPE']
    self.county                    = data['COUNTY']
    self.co_la_code                = data['CO_LA_CODE']
    self.co_lo_code                = data['CO_LO_CODE']
    self.co_sa_code                = data['CO_SA_CODE']
    self.co_so_code                = data['CO_SO_CODE']
    self.current_price             = data['CURRENT_PRICE']
    self.date_created              = data['DATE_CREATED']
    self.date_leased               = data['DATE_LEASED']
    self.date_modified             = data['DATE_MODIFIED']
    self.df_yn                     = data['DF_YN']
    self.directions                = data['DIRECTIONS']
    self.display_address_yn        = data['DISPLAY_ADDRESS_YN']
    self.dom                       = data['DOM']
    self.elem_school               = data['ELEM_SCHOOL']
    self.expenses_association      = data['EXPENSES_ASSOCIATION']
    self.expenses_insurance        = data['EXPENSES_INSURANCE']
    self.expenses_maintenance      = data['EXPENSES_MAINTENANCE']
    self.expenses_management       = data['EXPENSES_MANAGEMENT']
    self.expenses_other            = data['EXPENSES_OTHER']
    self.expenses_tax              = data['EXPENSES_TAX']
    self.expire_date               = data['EXPIRE_DATE']
    self.flood_plain               = data['FLOOD_PLAIN']
    self.ftr_building_type         = data['FTR_BUILDING_TYPE']
    self.ftr_construction          = data['FTR_CONSTRUCTION']
    self.ftr_cooling               = data['FTR_COOLING']
    self.ftr_exterior              = data['FTR_EXTERIOR']
    self.ftr_exterioramenit        = data['FTR_EXTERIORAMENIT']
    self.ftr_floors                = data['FTR_FLOORS']
    self.ftr_heating               = data['FTR_HEATING']
    self.ftr_interior              = data['FTR_INTERIOR']
    self.ftr_rent_incl             = data['FTR_RENT_INCL']
    self.ftr_roof                  = data['FTR_ROOF']
    self.ftr_roof_age              = data['FTR_ROOF_AGE']
    self.ftr_showing               = data['FTR_SHOWING']
    self.ftr_utils                 = data['FTR_UTILS']
    self.ftr_zoning                = data['FTR_ZONING']
    self.georesult                 = data['GEORESULT']
    self.geo_precision             = data['GEO_PRECISION']
    self.high_school               = data['HIGH_SCHOOL']
    self.hoa_fee                   = data['HOA_FEE']
    self.hoa_fee_yn                = data['HOA_FEE_YN']
    self.hoa_term                  = data['HOA_TERM']
    self.income                    = data['INCOME']
    self.income_other              = data['INCOME_OTHER']
    self.income_rent               = data['INCOME_RENT']
    self.internet_yn               = data['INTERNET_YN']
    self.la_code                   = data['LA_CODE']
    self.legals                    = data['LEGALS']
    self.limited_service_yn        = data['LIMITED_SERVICE_YN']
    self.listing_type              = data['LISTING_TYPE']
    self.list_date                 = data['LIST_DATE']
    self.list_price                = data['LIST_PRICE']
    self.lot_dimensions            = data['LOT_DIMENSIONS']
    self.lot_dimensions_source     = data['LOT_DIMENSIONS_SOURCE']
    self.lo_code                   = data['LO_CODE']
    self.management                = data['MANAGEMENT']
    self.media_flag                = data['MEDIA_FLAG']
    self.middle_school             = data['MIDDLE_SCHOOL']
    self.mls_acct                  = data['MLS_ACCT']
    self.municipality              = data['MUNICIPALITY']
    self.num_units                 = data['NUM_UNITS']
    self.num_units_occupied        = data['NUM_UNITS_OCCUPIED']
    self.office_notes              = data['OFFICE_NOTES']
    self.off_mkt_date              = data['OFF_MKT_DATE']
    self.off_mkt_days              = data['OFF_MKT_DAYS']
    self.orig_lp                   = data['ORIG_LP']
    self.orig_price                = data['ORIG_PRICE']
    self.other_fee                 = data['OTHER_FEE']
    self.other_fee_type            = data['OTHER_FEE_TYPE']
    self.owner_name                = data['OWNER_NAME']
    self.owner_phone               = data['OWNER_PHONE']
    self.parcel_id                 = data['PARCEL_ID']
    self.pending_date              = data['PENDING_DATE']
    self.photo_count               = data['PHOTO_COUNT']
    self.photo_date_modified       = data['PHOTO_DATE_MODIFIED']
    self.price_change_date         = data['PRICE_CHANGE_DATE']
    self.price_sqft                = data['PRICE_SQFT']
    self.proj_close_date           = data['PROJ_CLOSE_DATE']
    self.prop_id                   = data['PROP_ID']
    self.prop_type                 = data['PROP_TYPE']
    self.remarks                   = data['REMARKS']
    self.sale_notes                = data['SALE_NOTES']
    self.sale_rent                 = data['SALE_RENT']
    self.sa_code                   = data['SA_CODE']
    self.sold_date                 = data['SOLD_DATE']
    self.sold_price                = data['SOLD_PRICE']
    self.sold_terms                = data['SOLD_TERMS']
    self.so_code                   = data['SO_CODE']
    self.state                     = data['STATE']
    self.status                    = data['STATUS']
    self.status_date               = data['STATUS_DATE']
    self.status_flag               = data['STATUS_FLAG']
    self.street                    = data['STREET']
    self.street_dir                = data['STREET_DIR']
    self.street_name               = data['STREET_NAME']
    self.street_num                = data['STREET_NUM']
    self.subdivision               = data['SUBDIVISION']
    self.sub_agent                 = data['SUB_AGENT']
    self.sub_agent_type            = data['SUB_AGENT_TYPE']
    self.third_party_comm_yn       = data['THIRD_PARTY_COMM_YN']
    self.tot_heat_sqft             = data['TOT_HEAT_SQFT']
    self.u1_baths                  = data['U1_BATHS']
    self.u1_num                    = data['U1_NUM']
    self.u1_occ                    = data['U1_OCC']
    self.u1_rent                   = data['U1_RENT']
    self.u1_sqft                   = data['U1_SQFT']
    self.u1_yn                     = data['U1_YN']
    self.u2_baths                  = data['U2_BATHS']
    self.u2_num                    = data['U2_NUM']
    self.u2_occ                    = data['U2_OCC']
    self.u2_rent                   = data['U2_RENT']
    self.u2_sqft                   = data['U2_SQFT']
    self.u2_yn                     = data['U2_YN']
    self.u3_baths                  = data['U3_BATHS']
    self.u3_num                    = data['U3_NUM']
    self.u3_occ                    = data['U3_OCC']
    self.u3_rent                   = data['U3_RENT']
    self.u3_sqft                   = data['U3_SQFT']
    self.u3_yn                     = data['U3_YN']
    self.u4_baths                  = data['U4_BATHS']
    self.u4_num                    = data['U4_NUM']
    self.u4_occ                    = data['U4_OCC']
    self.u4_rent                   = data['U4_RENT']
    self.u4_sqft                   = data['U4_SQFT']
    self.u4_yn                     = data['U4_YN']
    self.u5_baths                  = data['U5_BATHS']
    self.u5_num                    = data['U5_NUM']
    self.u5_occ                    = data['U5_OCC']
    self.u5_rent                   = data['U5_RENT']
    self.u5_sqft                   = data['U5_SQFT']
    self.u5_yn                     = data['U5_YN']
    self.u6_baths                  = data['U6_BATHS']
    self.u6_num                    = data['U6_NUM']
    self.u6_occ                    = data['U6_OCC']
    self.u6_rent                   = data['U6_RENT']
    self.u6_sqft                   = data['U6_SQFT']
    self.u6_yn                     = data['U6_YN']
    self.u7_baths                  = data['U7_BATHS']
    self.u7_num                    = data['U7_NUM']
    self.u7_occ                    = data['U7_OCC']
    self.u7_rent                   = data['U7_RENT']
    self.u7_sqft                   = data['U7_SQFT']
    self.u7_yn                     = data['U7_YN']
    self.u8_num                    = data['U8_NUM']
    self.u8_occ                    = data['U8_OCC']
    self.u8_rent                   = data['U8_RENT']
    self.u8_sqft                   = data['U8_SQFT']
    self.u8_yn                     = data['U8_YN']
    self.unit_num                  = data['UNIT_NUM']
    self.upload_source             = data['UPLOAD_SOURCE']
    self.valuation_yn              = data['VALUATION_YN']
    self.vt_yn                     = data['VT_YN']
    self.withdrawn_date            = data['WITHDRAWN_DATE']
    self.year_built                = data['YEAR_BUILT']
    self.zip                       = data['ZIP']
  end
end
