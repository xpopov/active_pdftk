module PdftkForms
  # Represents a fillable form on a particular PDF.
  # it is your prefered abstraction layer, all actions on a PDF could be triggered from here.
  # Use a PdftkForms::Form object as an electronic document, read, edit & save it!
  # @bic = PdftkForms::Form.new('bic.pdf')
  # @bic.dummy_filling!
  # @bic.save
  #
  class Form

    attr_reader :template

    # Open a pdf file as a PdftkForms::Form object.
    # @bic = PdftkForms::Form.new(pdf_file, {:path => 'pdfxt_path'})
    # @bic = PdftkForms::Form.new('bic.pdf')
    #
    def initialize(template, wrapper_options = {})
      @pdftk = Wrapper.new(wrapper_options)
      @template = template
    end

    # Access all PdftkForms::Field objects associated to a given PdftkForms::Form.
    # @bic = PdftkForms::Form.new('bic.pdf')
    # @bic.fields #=> array of PdftkForms::Field
    #
    # fields are lazily loaded from the pdf file.
    def fields
      @fields ||= @pdftk.fields(@template)
    end

    # Get a PdftkForms::Field by his 'field_name'.
    # @bic = PdftkForms::Form.new('bic.pdf')
    # @bic.get('filled_field') #=> #<PdftkForms::Field:0x... >
    # @bic.get('not_a_field') #=> nil
    #
    def get(field_name)
      #TODO check if several inputs with same names are allowed
      fields.detect {|f| f.name == field_name.to_s}
    end

    # Set a PdftkForms::Field value by his 'field_name'.
    # @bic = PdftkForms::Form.new('bic.pdf')
    # @bic.set('filled_field', 'SomeString') #=> 'SomeString'
    # @bic.set('not_a_field', 'SomeString') #=> false
    # calling #set on a read_only? field will result in false as well
    #
    def set(field_name, value)
      f = get(field_name)
      (f.nil? || f.read_only?) ? false : f.value = value
    end

    # Save the PdftkForms::Form form to a new pdf file.
    # Return the path to the created file or false
    # @bic = PdftkForms::Form.new('bic.pdf')
    # @bic.set(..., ...) #=> ...
    # @bic.save #=> 'bic.pdf.filled'
    # @bic.save('bic.custom.pdf') #=> 'bic.custom.pdf'
    #
    def save(path = nil, options = {})
      #TODO Flatten should be an option
      @pdftk.fill_form(@template, path ||= @template + '.filled', to_h)
      path
    end

    # Save the PdftkForms::Form form to the current pdf file and overwrite it.
    # Return the path to the overwritten file or false
    # @bic = PdftkForms::Form.new('bic.pdf')
    # @bic.save! #=> 'bic.pdf'
    #
    def save!(options = {})
      save(@template, options)
    end

    # Create the fdf file corresponding to the PdftkForms::Form state.
    # Return a PdftkForms::Fdf object
    # Empty fields are discarded unless you pass +true+ as only argument.
    # @bic = PdftkForms::Form.new('bic.pdf')
    # @bic.to_fdf #=> #<PdftkForms::Fdf:0x... >
    # @bic.to_fdf(true) #=> #<PdftkForms::Fdf:0x... >
    #
    def to_fdf(full = false)
      Fdf.new(to_h(full))
    end

    # Create the xfdf file corresponding to the PdftkForms::Form state (empty fields are discarded).
    # Return a PdftkForms::Xfdf object
    # Empty fields are discarded unless you pass +true+ as only argument.
    # @bic = PdftkForms::Form.new('bic.pdf')
    # @bic.to_xfdf #=> #<PdftkForms::Xfdf:0x... >
    # @bic.to_xfdf(true) #=> #<PdftkForms::Xfdf:0x... >
    #
    def to_xfdf(full = false)
      Xfdf.new(to_h(full))
    end

    # Fill the form values with fields name
    # Helpfull for autogenerated forms which are not mnemonic compliant.
    # return self, so the methods could be chained.
    # @bic.dummy_filling! #=> #<PdftkForms::Field:0x... >
    #
    def dummy_filling!
      fields.each { |f| f.value = f.name.to_s if f.type == 'Text'}
      self
    end

    def to_h(full = false)
      hash = {}
      fields.each do |f|
        hash[f.name.to_s] = f.value.to_s if (full || f.value)
      end
      hash
    end

    def to_s
      to_h(true).to_s
    end

    def respond_to?(method_name, include_private = false)
      field_name = method_name.to_s.delete('=')
      fields.any? {|f| f.name == field_name} ? true : super
    end

    private

    def method_missing(method_name, *args)
      field_name = method_name.to_s.delete('=')
      if fields.any? {|f| f.name == field_name}
        method_name.to_s =~ /=/ ?  set(field_name, *args) : get(field_name)
      else
        super
      end
    end
  end
end

