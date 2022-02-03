class EpochDetail < ApplicationRecord
    before_destroy :destroy_callback, prepend: true 
    def destroy_callback
      throws :abort 
    end
  
end
