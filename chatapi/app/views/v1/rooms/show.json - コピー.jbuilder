json.array! @messages do |msg|
  json.id msg.id
  json.content msg.content
  json.user_id msg.user_id
  json.room_id msg&.room_id
  json.user_name msg.user&.name
  json.created_at msg.created_at
  json.updated_at msg.updated_at
end
