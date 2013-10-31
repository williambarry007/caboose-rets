
class CabooseRets::Office < ActiveRecord::Base
  self.table_name = "rets_offices"
  attr_accessible :id, :name, :lo_code
  
  def parse(data)
    self.lo_date_created 	    = data['LO_DATE_CREATED']
    self.lo_date_modified 	  = data['LO_DATE_MODIFIED']
    self.lo_email 		        = data['LO_EMAIL']
    self.lo_fax_phone 	      = data['LO_FAX_PHONE']
    self.lo_idx_yn 		        = data['LO_IDX_YN']
    self.lo_lo_code 	        = data['LO_LO_CODE']
    self.lo_mailaddr1 	      = data['LO_MAILADDR1']
    self.lo_mailaddr2 	      = data['LO_MAILADDR2']
    self.lo_mailcity 	        = data['LO_MAILCITY']
    self.lo_mailstate 	      = data['LO_MAILSTATE']
    self.lo_mailzip 	        = data['LO_MAILZIP']
    self.lo_main_lo_code 	    = data['LO_MAIN_LO_CODE']
    self.lo_name 	            = data['LO_NAME']
    self.lo_other_phone 	    = data['LO_OTHER_PHONE']
    self.lo_page 		          = data['LO_PAGE']
    self.lo_phone 	          = data['LO_PHONE']
    self.lo_status 		        = data['LO_STATUS']
    self.photo_count 		      = data['PHOTO_COUNT']
    self.photo_date_modified  = data['PHOTO_DATE_MODIFIED']
  end
end
