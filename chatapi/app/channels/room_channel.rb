class RoomChannel < ApplicationCable::Channel
  include ChannelHelper

  def subscribed
    # stream_from "some_channel"
    stream_from "room"
  end

  def unsubscribed
    # Any cleanup needed when channel is unsubscribed
  end

  def speak(data)
    # @mobj = Message.create! content: data['message']
    @message = current_user.messages.create! content: data['message']
    json_data = render_json(partial: 'v1/rooms/messages', locals: { message: @message })
    broadcast 'room', json_data
  end
end
