class FilingParserController < ApplicationController
    def index
        file = File.join(Rails.root, 'app', 'example1.xml')
        doc = File.open(file) { |f| Nokogiri::XML(f) }

        debugger
        parsed_ein = doc.at('Return/ReturnHeader/Filer/EIN').text
        parsed_name = doc.at('Return/ReturnHeader/Filer/Name/BusinessNameLine1').text
        parsed_address = doc.at('Return/ReturnHeader/Filer/USAddress/AddressLine1').text
        parsed_city = doc.at('Return/ReturnHeader/Filer/USAddress/City').text
        parsed_state = doc.at('Return/ReturnHeader/Filer/USAddress/State').text
        parsed_zip = doc.at('Return/ReturnHeader/Filer/USAddress/ZIPCode').text

        filer = Filer.new(ein: parsed_ein, 
            name: parsed_name, 
            address: parsed_address, 
            city: parsed_city, 
            state: parsed_state, 
            zip: parsed_zip)

        render json: filer
    end
end
