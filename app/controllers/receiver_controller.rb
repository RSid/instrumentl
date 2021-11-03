class ReceiverController < ApplicationController
    def index()
        receivers = Receiver.where(state: params[:state])
        render json: receivers
    end
end
