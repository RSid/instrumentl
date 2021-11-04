class FilingParserController < ApplicationController
    def index
        file_list = ['app/201132069349300318_public.xml',
                'app/201401839349300020_public.xml',
                'app/201521819349301247_public.xml',
                'app/201522139349100402_public.xml',
                'app/201612429349300846_public.xml',
                'app/201641949349301259_public.xml',
                'app/201823309349300127_public.xml',
                'app/201831309349303578_public.xml',
                'app/201831359349101003_public.xml',
                'app/201921719349301032_public.xml']
        
        single_test = ['app/201401839349300020_public.xml']

        for f in file_list do 
            file = File.join(Rails.root, f)
            xml_doc = File.open(file) { |f| Nokogiri::XML(f) }
        
            filer = parse_and_create_filer(xml_doc)
            
            award_and_recipient_list = get_recipient_award_list(xml_doc)
    
            for recipient_award_element in award_and_recipient_list do
                #skipping the RecordsMaintained element, and any others that don't have more data
                parse_and_create_award(recipient_award_element, filer.id)
                end
            end
            
            #render json: {filer: filer, awards: awards.to_json(include: :receiver)}
        end
        debugger
        render json: {ok: 200}
    end

    private

    def get_recipient_award_list(xml_doc)
        if xml_doc.at('Return/ReturnData/IRS990ScheduleI').nil?
            award_and_recipient_list = xml_doc.at('Return/ReturnData/IRS990PF/SupplementaryInformationGrp').element_children
        else
            award_and_recipient_list = xml_doc.at('Return/ReturnData/IRS990ScheduleI').element_children
        end
        return award_and_recipient_list
    end

    def parse_and_create_filer(xml_doc)
        parsed_ein = xml_doc.at('Return/ReturnHeader/Filer/EIN').text

        #try getting each element, and get their text if not nil. If nil, try the next one
        parsed_name ||= xml_doc.at('Return/ReturnHeader/Filer/Name/BusinessNameLine1')&.text
        parsed_name ||= xml_doc.at('Return/ReturnHeader/Filer/BusinessName/BusinessNameLine1Txt')&.text
        parsed_name ||= xml_doc.at('Return/ReturnHeader/Filer/BusinessName/BusinessNameLine1')&.text
        
        parsed_address ||= xml_doc.at('Return/ReturnHeader/Filer/USAddress/AddressLine1')&.text 
        parsed_address ||= xml_doc.at('Return/ReturnHeader/Filer/USAddress/AddressLine1Txt')&.text

        parsed_city ||= xml_doc.at('Return/ReturnHeader/Filer/USAddress/City')&.text 
        parsed_city ||= xml_doc.at('Return/ReturnHeader/Filer/USAddress/CityNm')&.text

        parsed_state ||= xml_doc.at('Return/ReturnHeader/Filer/USAddress/State')&.text 
        parsed_state ||= xml_doc.at('Return/ReturnHeader/Filer/USAddress/StateAbbreviationCd')&.text

        parsed_zip ||= xml_doc.at('Return/ReturnHeader/Filer/USAddress/ZIPCode')&.text 
        parsed_zip ||= xml_doc.at('Return/ReturnHeader/Filer/USAddress/ZIPCd').text

        filer = Filer.find_or_create_by( ein: parsed_ein) do |filer|
            filer.name = parsed_name
            filer.address = parsed_address, 
            filer.city = parsed_city, 
            filer.state = parsed_state, 
            filer.zip = parsed_zip
        end

        return filer
    end

    def parse_and_create_award(recipient_award_element, filer_id)
        if recipient_award_element.element_children.length > 0
            parsed_grant_purpose ||= recipient_award_element.element_children.at('PurposeOfGrant')&.text
            parsed_grant_purpose ||= recipient_award_element.element_children.at('PurposeOfGrantTxt')&.text
            parsed_grant_purpose ||= recipient_award_element.element_children.at('GrantOrContributionPurposeTxt')&.text
            
            parsed_cash_amount ||= recipient_award_element.element_children.at('AmountOfCashGrant')&.text
            parsed_cash_amount ||= recipient_award_element.element_children.at('CashGrantAmt')&.text
            parsed_cash_amount ||= recipient_award_element.element_children.at('Amt')&.text
            
            if parsed_grant_purpose.nil? || parsed_cash_amount.nil?
                #depends on shape of other files whether we can skip these or need better parsing
                puts recipient_award_element.element_children
                #next
            end
            
            award = Award.new(filer_id: filer_id, 
                purpose: parsed_grant_purpose, 
                cash_amount: parsed_cash_amount)

            parsed_recipient_ein ||= recipient_award_element.element_children.at('EINOfRecipient')&.text
            parsed_recipient_ein ||= recipient_award_element.element_children.at('RecipientEIN')&.text

            parsed_recipient_name ||= recipient_award_element.element_children.at('RecipientNameBusiness/BusinessNameLine1')&.text
            parsed_recipient_name ||= recipient_award_element.element_children.at('RecipientBusinessName/BusinessNameLine1Txt')&.text
            parsed_recipient_name ||= recipient_award_element.element_children.at('RecipientBusinessName/BusinessNameLine1')&.text

            parsed_recipient_address ||= recipient_award_element.element_children.at('AddressUS/AddressLine1')&.text
            parsed_recipient_address ||= recipient_award_element.element_children.at('USAddress/AddressLine1Txt')&.text
            parsed_recipient_address ||= recipient_award_element.element_children.at('USAddress/AddressLine1')&.text
            parsed_recipient_address ||= recipient_award_element.element_children.at('RecipientUSAddress/AddressLine1Txt')&.text

            parsed_recipient_city ||= recipient_award_element.element_children.at('AddressUS/City')&.text
            parsed_recipient_city ||= recipient_award_element.element_children.at('USAddress/CityNm')&.text
            parsed_recipient_city ||= recipient_award_element.element_children.at('USAddress/City')&.text
            parsed_recipient_city ||= recipient_award_element.element_children.at('RecipientUSAddress/CityNm')&.text

            parsed_recipient_state ||= recipient_award_element.element_children.at('AddressUS/State')&.text
            parsed_recipient_state ||= recipient_award_element.element_children.at('USAddress/StateAbbreviationCd')&.text
            parsed_recipient_state ||= recipient_award_element.element_children.at('USAddress/State')&.text
            parsed_recipient_state ||= recipient_award_element.element_children.at('RecipientUSAddress/StateAbbreviationCd')&.text

            parsed_recipient_zip ||= recipient_award_element.element_children.at('AddressUS/ZIPCode')&.text
            parsed_recipient_zip ||= recipient_award_element.element_children.at('USAddress/ZIPCd')&.text
            parsed_recipient_zip ||= recipient_award_element.element_children.at('USAddress/ZIPCode')&.text
            parsed_recipient_zip ||= recipient_award_element.element_children.at('RecipientUSAddress/ZIPCd')&.text

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
    end
end
