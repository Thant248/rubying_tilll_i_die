class SchoolItemsController < ApplicationController

    def index 
        @school = SchoolItem.all
        render json: @school
    end

    def show 
        @SchoolItem = SchoolItem.find(params[:id])
        redner json: @SchoolItem
    end
    
    def create 
        @SchoolItem = SchoolItem.create(
            name:  params[:name],
            age:  params[:age],
            school: params[:school],
            sex: params[:sex]
        )
        redner josn: @SchoolItem
    end

    def update 
        @SchoolItem = SchoolItem.find(params[:id])
        @SchoolItem.update(
            name: params[:name],
            age: params[:age],
            school: params[:school],
            sex: params[:sex]
        )
        render json: @SchoolItem
    end

    def destroy 
        
        @SchoolItems  = SchoolItem.all
        @SchoolItem = SchoolItem.find(params[:id])
        @SchoolItem.destroy
        redner json: @SchoolItems
    end
end
