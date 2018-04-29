class PeopleController < ApplicationController
  def index
    @people = Person.all
    render json: @people, status: :ok
  end

  def show
    @person = Person.find(params[:id])
    render json: @person, status: :ok
  end

  def create
    @person = Person.new(resource_params)
    @person.save!
    render json: @person, status: :created
  end

  def update
    @person = Person.find_with_fingerprint(params[:id], resource_params[:lock_fingerprint])
    @person.update!(resource_params)
    head :no_content
  end

  def destroy
    @person = Person.find(params[:id])
    @person.destroy!
    head :no_content
  end

  private

    def resource_params
      params.permit(:first_name, :last_name, :lock_fingerprint)
    end
end
