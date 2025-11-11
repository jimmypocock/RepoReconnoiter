class AddUserIdToAnalyses < ActiveRecord::Migration[8.1]
  def change
    add_reference :analyses, :user, foreign_key: true
  end
end
