prawn_document(:page_layout => :landscape, :page_size => @page_size) do |pdf|
  ParticipantsHelper::render_certificate( pdf, @certificate, @page_size, @certificate_store)
end
