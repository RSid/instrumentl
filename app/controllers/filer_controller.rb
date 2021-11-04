class FilerController < ApplicationController
    def index()
        filers = Filer.preload(awards: :receiver)
        render json: filers.to_json(include: {
            awards: {
              include: :receiver
          }
        })
    end
end
