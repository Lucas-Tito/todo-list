class AddPhotoUrlToUsers < ActiveRecord::Migration[8.0]
  def change
    add_column :users, :photo_url, :string
  end
end
