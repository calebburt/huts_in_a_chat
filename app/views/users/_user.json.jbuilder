json.extract! user, :id, :name, :bio, :img_url, :confirmed, :is_moderator, :created_at, :updated_at
json.url user_url(user, format: :json)
json.avatar_url(url_for(user.avatar)) if user.avatar.attached?
