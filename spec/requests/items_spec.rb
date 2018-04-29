require 'rails_helper'

RSpec.describe 'Items API', type: :request do
  describe 'GET /items' do
    it 'returns list of items' do
      create_list(:item, 5)
      get '/items'
      expect_api_list(count: 5)
    end
  end

  describe 'GET /items/:id' do
    it 'returns an item' do
      item = create(:item, name: 'Some Item')
      get "/items/#{item.id}"
      expect(json).not_to be_empty
      expect(json).to include({ id: item.id, name: item.name }.stringify_keys)
    end
    it 'returns 404 when item does not exist' do
      get '/items/0'
      expect(response).to have_http_status(404)
    end
  end

  describe 'POST /items' do
    it 'creates an item when data is valid' do
      params = { name: 'Some Item' }
      post '/items', params: params
      expect(response).to have_http_status(201)
      expect(json).not_to be_empty
      expect(json).to include(params.stringify_keys)
    end
    it 'returns unprocessable when data is invalid' do
      params = {}
      post '/items', params: params
      expect_unprocessable_in_response
    end
  end

  describe 'PUT /items/:id' do
    it 'updates an item' do
      item = create(:item, name: 'Some Item')
      params = { name: 'New Name' }
      put "/items/#{item.id}", params: params
      expect(response).to have_http_status(204)
      expect(response.body).to be_empty
      expect(item.reload.name).to eq(params[:name])
    end
    it 'returns 404 when item does not exist' do
      item = create(:item, name: 'Some Item')
      params = { name: 'New Name' }
      put '/items/0', params: params
      expect(response).to have_http_status(404)
    end
  end

  describe 'DELETE /items/:id' do
    it 'deletes an item record' do
      item = create(:item)
      delete "/items/#{item.id}"
      expect(response).to have_http_status(204)
      expect(Item.count).to eq(0)
    end
    it 'returns 404 when item does not exist' do
      delete '/items/0'
      expect(response).to have_http_status(404)
    end
  end
end
