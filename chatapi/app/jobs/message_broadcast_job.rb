class MessageBroadcastJob < ApplicationJob
  queue_as :default

  def perform(message)
    # Do something later
    # ActionCable.server.broadcast 'room_channel', message: message.content
    # ActionCable.server.broadcast('room', { message: data['message'] })
    ActionCable.server.broadcast('room', { message: 'test' })
  end
end
