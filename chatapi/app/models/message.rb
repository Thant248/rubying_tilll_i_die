class Message < ApplicationRecord
  validates :content, presence: true

  belongs_to :user
  belongs_to :room, optional: true

  # createの後にコミットする { MessageBroadcastJobのperformを遅延実行 引数はself }
  # after_create_commit { MessageBroadcastJob.perform_later self }
end
