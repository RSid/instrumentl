class FilingParserController < ApplicationController
    def index
        file = File.join(Rails.root, 'app', '201401839349300020_public.xml')
        doc = File.open(file) { |f| Nokogiri::XML(f) }
    
        filer = parse__and_create_filer(doc)
        
        awards = parse_and_create_awards(filer.id, doc)
        render json: {filer: filer, awards: awards.to_json(include: :receiver)}
    end

    private

    def parse__and_create_filer(xml_doc)
        parsed_ein = xml_doc.at('Return/ReturnHeader/Filer/EIN').text

        if xml_doc.at('Return/ReturnHeader/Filer/Name').nil?
            #cyclomatic complexity boo
            if xml_doc.at('Return/ReturnHeader/Filer/BusinessName/BusinessNameLine1Txt').nil?
                parsed_name = xml_doc.at('Return/ReturnHeader/Filer/BusinessName/BusinessNameLine1').text
            else
                parsed_name = xml_doc.at('Return/ReturnHeader/Filer/BusinessName/BusinessNameLine1Txt').text
            end
        else
            parsed_name = xml_doc.at('Return/ReturnHeader/Filer/Name/BusinessNameLine1').text
        end
        
        if xml_doc.at('Return/ReturnHeader/Filer/USAddress/AddressLine1').nil?
            parsed_address = xml_doc.at('Return/ReturnHeader/Filer/USAddress/AddressLine1Txt').text
        else
            parsed_address = xml_doc.at('Return/ReturnHeader/Filer/USAddress/AddressLine1').text
        end

        if xml_doc.at('Return/ReturnHeader/Filer/USAddress/City').nil?
            parsed_city = xml_doc.at('Return/ReturnHeader/Filer/USAddress/CityNm').text
        else
            parsed_city = xml_doc.at('Return/ReturnHeader/Filer/USAddress/City').text
        end

        if xml_doc.at('Return/ReturnHeader/Filer/USAddress/State').nil?
            parsed_state = xml_doc.at('Return/ReturnHeader/Filer/USAddress/StateAbbreviationCd').text
        else
            parsed_state = xml_doc.at('Return/ReturnHeader/Filer/USAddress/State').text
        end

        if xml_doc.at('Return/ReturnHeader/Filer/USAddress/ZIPCode').nil?
            parsed_zip = xml_doc.at('Return/ReturnHeader/Filer/USAddress/ZIPCd').text
        else
            parsed_zip = xml_doc.at('Return/ReturnHeader/Filer/USAddress/ZIPCode').text
        end

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
                if recipient_award_element.element_children.at('PurposeOfGrant').nil?
                    if recipient_award_element.element_children.at('PurposeOfGrantTxt').nil?
                        #depends on shape of other files whether we can skip these or need better parsing
                        puts recipient_award_element.element_children
                        next
                    end
                    parsed_grant_purpose = recipient_award_element.element_children.at('PurposeOfGrantTxt').text
                else
                    parsed_grant_purpose = recipient_award_element.element_children.at('PurposeOfGrant').text
                end
                
                if recipient_award_element.element_children.at('AmountOfCashGrant').nil?
                    parsed_cash_amount = recipient_award_element.element_children.at('CashGrantAmt').text
                else
                    parsed_cash_amount = recipient_award_element.element_children.at('AmountOfCashGrant').text
                end
                
                if parsed_grant_purpose.nil? || parsed_cash_amount.nil?
                    next
                end
                award = Award.new(filer_id: filer_id, 
                    purpose: parsed_grant_purpose, 
                    cash_amount: parsed_cash_amount)

                if recipient_award_element.element_children.at('EINOfRecipient').nil?
                    #EINs can be missing (thanks, city of pasedena public library)
                    parsed_recipient_ein = recipient_award_element.element_children.at('RecipientEIN')&.text
                else
                    parsed_recipient_ein = recipient_award_element.element_children.at('EINOfRecipient').text
                end

                if recipient_award_element.element_children.at('RecipientNameBusiness/BusinessNameLine1').nil?
                    #cyclomatic complexity boo
                    if xml_doc.at('RecipientBusinessName/BusinessNameLine1Txt').nil?
                        parsed_name = xml_doc.at('RecipientBusinessName/BusinessNameLine1').text
                    else
                        parsed_name = xml_doc.at('RecipientBusinessName/BusinessNameLine1Txt').text
                    end
                else
                    parsed_recipient_name = recipient_award_element.element_children.at('RecipientNameBusiness/BusinessNameLine1').text
                end

                if recipient_award_element.element_children.at('AddressUS/AddressLine1').nil?
                    if recipient_award_element.element_children.at('USAddress/AddressLine1Txt').nil?
                        parsed_recipient_address = recipient_award_element.element_children.at('USAddress/AddressLine1').text
                    else
                        parsed_recipient_address = recipient_award_element.element_children.at('USAddress/AddressLine1Txt').text
                    end
                else
                    parsed_recipient_address = recipient_award_element.element_children.at('AddressUS/AddressLine1').text
                end

                if recipient_award_element.element_children.at('AddressUS/City').nil?
                    if recipient_award_element.element_children.at('USAddress/CityNm').nil?
                        parsed_recipient_city = recipient_award_element.element_children.at('USAddress/City').text
                    else
                        parsed_recipient_city = recipient_award_element.element_children.at('USAddress/CityNm').text
                    end
                else
                    parsed_recipient_city = recipient_award_element.element_children.at('AddressUS/City').text
                end

                if recipient_award_element.element_children.at('AddressUS/State').nil?
                    if recipient_award_element.element_children.at('USAddress/StateAbbreviationCd').nil?
                        parsed_recipient_state = recipient_award_element.element_children.at('USAddress/State').text
                    else
                        parsed_recipient_state = recipient_award_element.element_children.at('USAddress/StateAbbreviationCd').text
                    end
                else
                    parsed_recipient_state = recipient_award_element.element_children.at('AddressUS/State').text
                end

                if recipient_award_element.element_children.at('AddressUS/ZIPCode').nil?
                    if recipient_award_element.element_children.at('USAddress/ZIPCd').nil?
                        parsed_recipient_zip = recipient_award_element.element_children.at('USAddress/ZIPCode').text
                    else
                        parsed_recipient_zip = recipient_award_element.element_children.at('USAddress/ZIPCd').text
                    end
                else
                    parsed_recipient_zip = recipient_award_element.element_children.at('AddressUS/ZIPCode').text
                end

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
                
                #TODO: slow, let's figure out saving in bulk
                award.save
                awards << award
            end
        end
        
        return awards
    end

    def retrieve_xml_element_by_synonyms(xml_doc, list_of_element_synonyms)
        #TODO: maybe clean up this way?
    end
end
