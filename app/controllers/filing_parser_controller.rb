class FilingParserController < ApplicationController
    def index
        file = File.join(Rails.root, 'app', 'example1.xml')
        doc = File.open(file) { |f| Nokogiri::XML(f) }

        filer = doc.at('Return/ReturnHeader/Filer').text

        puts filer.class

        render json: filer
    end
end
