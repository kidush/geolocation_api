class CreateGeolocations < ActiveRecord::Migration[8.1]
  def change
    create_table :geolocations do |t|
      t.string :ip, null: false, index: { unique: true }
      t.string :url
      t.string :country_code
      t.string :country
      t.string :region
      t.string :city
      t.float :latitude
      t.float :longitude
      t.json :raw_data

      t.timestamps
    end
  end
end
