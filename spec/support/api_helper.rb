module ApiHelper
  def response_data_count
    json.count rescue -1
  end

  def expect_api_list(count: nil)
    expect(response.status).to eq(200)
    if count
      expect(response_data_count).to eq(count)
    else
      expect(response_data_count).to be > 0
    end
  end

  def expect_unprocessable_in_response
    expect(response.status).to eq(422)
    expect(json["error"]).to be_present
  end

  def json
    JSON.parse(response.body)
  end
end

RSpec.configure do |config|
  config.include ApiHelper, type: :request
end
