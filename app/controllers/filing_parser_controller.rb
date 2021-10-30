class FilingParserController < ApplicationController
    def index
        file = File.join(Rails.root, 'app', 'example1.xml')
        doc = File.open(file) { |f| Nokogiri::XML(f) }

        debugger
        parsed_name = doc.at('Return/ReturnHeader/Filer/Name/BusinessNameLine1').text

        filer = Filer.new(name: parsed_name)

        render json: filer
    end
end
