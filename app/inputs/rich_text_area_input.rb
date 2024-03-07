class RichTextAreaInput < Formtastic::Inputs::TextInput
  def to_html
    input_wrapping do
      label_html <<
        builder.rich_text_area(method, input_html_options)
    end
  end
end
