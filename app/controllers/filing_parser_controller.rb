class FilingParserController < ApplicationController
    def index
        file = File.join(Rails.root, 'app', 'example1.xml')
        doc = File.open(file) { |f| Nokogiri::XML(f) }

        filer = parse_filer(doc)
        award = parse_award(doc)
        render json: {filer: filer, award: award}
    end

    private

    def parse_filer(xml_doc)
        parsed_ein = xml_doc.at('Return/ReturnHeader/Filer/EIN').text
        parsed_name = xml_doc.at('Return/ReturnHeader/Filer/Name/BusinessNameLine1').text
        parsed_address = xml_doc.at('Return/ReturnHeader/Filer/USAddress/AddressLine1').text
        parsed_city = xml_doc.at('Return/ReturnHeader/Filer/USAddress/City').text
        parsed_state = xml_doc.at('Return/ReturnHeader/Filer/USAddress/State').text
        parsed_zip = xml_doc.at('Return/ReturnHeader/Filer/USAddress/ZIPCode').text

        filer = Filer.new(ein: parsed_ein, 
            name: parsed_name, 
            address: parsed_address, 
            city: parsed_city, 
            state: parsed_state, 
            zip: parsed_zip)
        return filer
    end

    def parse_award(xml_doc)
        recipients = xml_doc.at('Return/ReturnData/IRS990ScheduleI/RecipientTable')
        #xml_doc.at('Return/ReturnData/IRS990ScheduleI').element_children[5].element_children[0].at('BusinessNameLine1').text
        debugger
        parsed_recipient_name = xml_doc.at('Return/ReturnData/IRS990ScheduleI/RecipientTable/RecipientNameBusiness/BusinessNameLine1').text

        parsed_purpose = xml_doc.at('Return/ReturnData/IRS990ScheduleI/RecipientTable/PurposeOfGrant').text
        parsed_cash_amount = xml_doc.at('Return/ReturnData/IRS990ScheduleI/RecipientTable/AmountOfCashGrant').text
        award = Award.new(purpose: parsed_purpose, cash_amount: parsed_cash_amount)
        return award
    end
end
