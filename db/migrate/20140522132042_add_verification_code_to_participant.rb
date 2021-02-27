class AddVerificationCodeToParticipant < ActiveRecord::Migration[5.0]
  def change
  	add_column :participants, :verification_code, :string

  	Participant.all.each do |participant|
  		participant.update_attribute(:verification_code, Digest::SHA1.hexdigest([Time.now, rand].join)[1..20].upcase)
  	end

  end
end
