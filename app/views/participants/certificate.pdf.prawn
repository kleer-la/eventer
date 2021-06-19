if @is_download
  prawn_document(filename: "#{@certificate.name}.pdf", disposition: "attachment", :page_layout => :landscape, :page_size => @page_size) do |pdf|
    ParticipantsHelper::render_certificate( pdf, @certificate, @page_size, @certificate_store)
  end
else
  prawn_document(:page_layout => :landscape, :page_size => @page_size) do |pdf|
    ParticipantsHelper::render_certificate( pdf, @certificate, @page_size, @certificate_store)
  end
end
