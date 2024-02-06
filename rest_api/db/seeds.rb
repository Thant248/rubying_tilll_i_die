# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).
#
# Example:
#
#   ["Action", "Comedy", "Drama", "Horror"].each do |genre_name|
#     MovieGenre.find_or_create_by!(name: genre_name)
#   end

menu1 = MenuItem.create(menu_name: "Chipotle Nachos", restaurant_name: "Chipotle", menu_description:"Build a plate of nachos with all of your favorite fixings")
menu2 = MenuItem.create(menu_name: "Chipotle Nachos", restaurant_name: "Chipotle", menu_description:"Build a plate of nachos with all of your favorite fixings")

