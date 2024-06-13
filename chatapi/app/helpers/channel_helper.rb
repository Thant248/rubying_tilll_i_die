module ChannelHelper
  def render_view(params)
    ApplicationController.render(params)
    end
  
    def render_json(params)
    JSON.parse render_view(params)
    end
  
    def broadcast channel, message
    ActionCable.server.broadcast channel, message
    end
end
