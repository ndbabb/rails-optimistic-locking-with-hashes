class ItemsController < ApplicationController
  def index
    @items = Item.all
    render json: @items, status: :ok
  end

  def show
    @item = Item.find(params[:id])
    render json: @item, status: :ok
  end

  def create
    @item = Item.new(resource_params)
    @item.save!
    render json: @item, status: :created
  end

  def update
    @item = Item.find_by!(id: params[:id])
    @item.update!(resource_params)
    head :no_content
  end

  def destroy
    @item = Item.find_by!(id: params[:id])
    @item.destroy!
    head :no_content
  end

  private

    def resource_params
      params.permit(:name, :person_id)
    end
end
