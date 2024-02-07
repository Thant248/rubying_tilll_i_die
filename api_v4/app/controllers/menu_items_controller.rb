class MenuItemsController < ApplicationController

    def index
        @MenuItems = MenuItem.all 
        render json: @MenuItems
    end 

    def show
        @MenuItem = MenuItem.find(params[:id])
        render json: @MenuItem
    end 

    def create
        @MenuItem = MenuItem.create(
            menu_name: params[:menu_name],
            restaurant_name: params[:restaurant_name],
            menu_description: params[:menu_description]
        )
        render json: @MenuItem
    end 

    def update
        @MenuItem = MenuItem.find(params[:id])
        @MenuItem.update(
            menu_name: params[:menu_name],
            restaurant_name: params[:restaurant_name],
            menu_description: params[:menu_description]
         )
         render json: @MenuItem
    end 

    def destroy
        @MenuItems = MenuItem.all 
        @MenuItem = MenuItem.find(params[:id])
        @MenuItem.destroy
        render json: @MenuItems
    end 
end
