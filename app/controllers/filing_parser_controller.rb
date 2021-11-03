class FilingParserController < ApplicationController
    def index
        file = File.join(Rails.root, 'app', 'example1.xml')
        doc = File.open(file) { |f| Nokogiri::XML(f) }
    
        filer = parse__and_create_filer(doc)
        debugger
        awards = parse_and_create_awards(filer.id, doc)
        render json: {filer: filer, awards: awards.to_json(include: :receiver)}
    end

    private

    def parse__and_create_filer(xml_doc)
        parsed_ein = xml_doc.at('Return/ReturnHeader/Filer/EIN').text
        parsed_name = xml_doc.at('Return/ReturnHeader/Filer/Name/BusinessNameLine1').text
        parsed_address = xml_doc.at('Return/ReturnHeader/Filer/USAddress/AddressLine1').text
        parsed_city = xml_doc.at('Return/ReturnHeader/Filer/USAddress/City').text
        parsed_state = xml_doc.at('Return/ReturnHeader/Filer/USAddress/State').text
        parsed_zip = xml_doc.at('Return/ReturnHeader/Filer/USAddress/ZIPCode').text

        filer = Filer.find_or_create_by( ein: parsed_ein) do |filer|
            filer.name = parsed_name
            filer.address = parsed_address, 
            filer.city = parsed_city, 
            filer.state = parsed_state, 
            filer.zip = parsed_zip
        end

        return filer
    end

    def parse_and_create_awards(filer_id, xml_doc)
        awards = []
        for recipient_award_element in xml_doc.at('Return/ReturnData/IRS990ScheduleI').element_children do
            #skipping the RecordsMaintained element, and any others that don't have more data
            if recipient_award_element.element_children.length > 0
                parsed_grant_purpose = recipient_award_element.element_children.at('PurposeOfGrant')&.text
                parsed_cash_amount = recipient_award_element.element_children.at('AmountOfCashGrant')&.text
                if parsed_grant_purpose.nil? || parsed_cash_amount.nil?
                    next
                end
                award = Award.new(filer_id: filer_id, 
                    purpose: parsed_grant_purpose, 
                    cash_amount: parsed_cash_amount)

                parsed_recipient_ein = recipient_award_element.element_children.at('EINOfRecipient')&.text
                parsed_recipient_name = recipient_award_element.element_children.at('RecipientNameBusiness/BusinessNameLine1').text
                parsed_recipient_address = recipient_award_element.element_children.at('AddressUS/AddressLine1').text
                parsed_recipient_city = recipient_award_element.element_children.at('AddressUS/City').text
                parsed_recipient_state = recipient_award_element.element_children.at('AddressUS/State').text
                parsed_recipient_zip = recipient_award_element.element_children.at('AddressUS/ZIPCode').text

                receiver = Receiver.new(ein: parsed_recipient_ein, 
                    name: parsed_recipient_name, 
                    address: parsed_recipient_address, 
                    city: parsed_recipient_city, 
                    state: parsed_recipient_state, 
                    zip: parsed_recipient_zip)
                
                award.build_receiver(ein: parsed_recipient_ein, 
                    name: parsed_recipient_name, 
                    address: parsed_recipient_address, 
                    city: parsed_recipient_city, 
                    state: parsed_recipient_state, 
                    zip: parsed_recipient_zip)
                
                award.save
                awards << award
            end
        end
        
        return awards
    end
end
