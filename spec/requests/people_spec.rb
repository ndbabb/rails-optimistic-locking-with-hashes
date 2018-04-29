require 'rails_helper'

RSpec.describe 'People API', type: :request do
  describe 'GET /people' do
    it 'returns list of people' do
      create_list(:person, 5)
      get '/people'
      expect_api_list(count: 5)
    end
  end

  describe 'GET /people/:id' do
    it 'returns an person' do
      person = create(:person, first_name: 'Bob', last_name: 'Smith')
      get "/people/#{person.id}"
      expect(json).not_to be_empty
      expect(json).to include({ first_name: person.first_name, last_name: person.last_name }.stringify_keys)
    end
    it 'returns 404 when person does not exist' do
      get '/people/0'
      expect(response).to have_http_status(404)
    end
  end

  describe 'POST /people' do
    it 'creates an person when data is valid' do
      params = { first_name: 'Bob', last_name: 'Smith' }
      post '/people', params: params
      expect(response).to have_http_status(201)
      expect(json).not_to be_empty
      expect(json).to include(params.stringify_keys)
    end
    it 'returns unprocessable when data is invalid' do
      params = {}
      post '/people', params: params
      expect_unprocessable_in_response
    end
  end

  describe 'PUT /people/:id' do
    it 'updates an person' do
      person = create(:person, first_name: 'Bob', last_name: 'Smith')
      params = { last_name: 'Wilson', lock_fingerprint: person.lock_fingerprint }
      put "/people/#{person.id}", params: params
      expect(response).to have_http_status(204)
      expect(response.body).to be_empty
      expect(person.reload.last_name).to eq(params[:last_name])
    end
    it 'returns 404 when person does not exist' do
      person = create(:person, first_name: 'Bob', last_name: 'Smith')
      params = { last_name: 'Wilson' }
      put '/people/0', params: params
      expect(response).to have_http_status(404)
    end
    it 'returns 422 when record\'s fingerprint is stale (updated by someone else)' do
      person = create(:person, first_name: 'Bob', last_name: 'Smith')
      params = { first_name: 'Jane', lock_fingerprint: person.lock_fingerprint }
      person.update!(first_name: 'Mary') # simulates record being changed by someone else
      put "/people/#{person.id}", params: params
      expect_unprocessable_in_response
    end
  end

  describe 'DELETE /people/:id' do
    it 'deletes an person record' do
      person = create(:person)
      delete "/people/#{person.id}"
      expect(response).to have_http_status(204)
      expect(Person.count).to eq(0)
    end
    it 'returns 404 when person does not exist' do
      delete '/people/0'
      expect(response).to have_http_status(404)
    end
  end
end
