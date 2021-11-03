class ReceiverController < ApplicationController
    def index()
        receivers = Receiver.where(state: params[:state])
        render json: receivers
    end

    private
    def receiver_params
        params.permit(:state)
    end
end
