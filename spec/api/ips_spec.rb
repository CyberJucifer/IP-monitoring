require 'spec_helper'

RSpec.describe 'IP Addresses API' do
  describe 'POST /ips' do
    context 'with valid data' do
      it 'creates a new IP address' do
        post '/ips', {
          ip: '8.8.8.8',
          enabled: true,
        }.to_json, { 'CONTENT_TYPE' => 'application/json' }

        expect(last_response).to have_http_status(:created)
        response_data = Oj.load(last_response.body)
        expect(response_data['ip']).to eq('8.8.8.8')
        expect(response_data['enabled']).to be true
      end

      it 'creates a disabled IP address' do
        post '/ips', {
          ip: '1.1.1.1',
          enabled: false,
        }.to_json, { 'CONTENT_TYPE' => 'application/json' }

        expect(last_response).to have_http_status(:created)
        response_data = Oj.load(last_response.body)
        expect(response_data['enabled']).to be false
      end
    end

    context 'with invalid data' do
      it 'returns error for missing fields' do
        post '/ips', {
          ip: '8.8.8.8',
        }.to_json, { 'CONTENT_TYPE' => 'application/json' }

        expect(last_response).to have_http_status(:bad_request)
        response_data = Oj.load(last_response.body)
        expect(response_data['error']).to include('Missing required field: enabled')
      end

      it 'returns error for invalid IP' do
        post '/ips', {
          ip: 'invalid-ip',
          enabled: true,
        }.to_json, { 'CONTENT_TYPE' => 'application/json' }

        expect(last_response).to have_http_status(:bad_request)
        response_data = Oj.load(last_response.body)
        expect(response_data['error']).to include('Invalid IP address format')
      end

      it 'returns error for non-boolean enabled field' do
        post '/ips', {
          ip: '8.8.8.8',
          enabled: 'yes',
        }.to_json, { 'CONTENT_TYPE' => 'application/json' }

        expect(last_response).to have_http_status(:bad_request)
        response_data = Oj.load(last_response.body)
        expect(response_data['error']).to include('Field "enabled" must be boolean')
      end

      it 'returns error for non-JSON body' do
        post '/ips', 'invalid json', { 'CONTENT_TYPE' => 'application/json' }

        expect(last_response).to have_http_status(:bad_request)
        response_data = Oj.load(last_response.body)
        expect(response_data['error']).to include('Invalid JSON format')
      end
    end
  end

  describe 'POST /ips/:id/enable' do
    let(:ip_address) { create(:ip_address, enabled: false) }

    it 'enables the IP address' do
      post "/ips/#{ip_address.id}/enable"

      expect(last_response).to have_http_status(:ok)
      response_data = Oj.load(last_response.body)
      expect(response_data['message']).to eq('IP address enabled')

      ip_address.reload
      expect(ip_address.enabled).to be true
    end

    it 'returns 404 for non-existent IP' do
      post '/ips/999/enable'

      expect(last_response).to have_http_status(:not_found)
      response_data = Oj.load(last_response.body)
      expect(response_data['error']).to eq('IP address not found')
    end

    it 'returns 400 for invalid ID format' do
      post '/ips/abc/enable'

      expect(last_response).to have_http_status(:bad_request)
      response_data = Oj.load(last_response.body)
      expect(response_data['error']).to eq('Invalid IP address ID format')
    end
  end

  describe 'POST /ips/:id/disable' do
    let(:ip_address) { create(:ip_address, enabled: true) }

    it 'disables the IP address' do
      post "/ips/#{ip_address.id}/disable"

      expect(last_response).to have_http_status(:ok)
      response_data = Oj.load(last_response.body)
      expect(response_data['message']).to eq('IP address disabled')

      ip_address.reload
      expect(ip_address.enabled).to be false
    end
  end

  describe 'GET /ips/:id/stats' do
    let(:ip_address) { create(:ip_address) }
    let(:time_from) { 1.hour.ago }
    let(:time_to) { Time.now }

    before do
      # Create some ping results
      create_list(:ping_result, 5, ip_address: ip_address, created_at: 30.minutes.ago)
      create_list(:failed_ping_result, 2, ip_address: ip_address, created_at: 20.minutes.ago)
    end

    it 'returns statistics for the IP address' do
      get "/ips/#{ip_address.id}/stats", {
        time_from: time_from.iso8601,
        time_to: time_to.iso8601,
      }

      expect(last_response).to have_http_status(:ok)
      response_data = Oj.load(last_response.body)

      expect(response_data).to have_key('total_pings')
      expect(response_data).to have_key('successful_pings')
      expect(response_data).to have_key('packet_loss_percentage')
      expect(response_data).to have_key('rtt_stats')
      expect(response_data['rtt_stats']).to have_key('min')
      expect(response_data['rtt_stats']).to have_key('max')
      expect(response_data['rtt_stats']).to have_key('mean')
      expect(response_data['rtt_stats']).to have_key('median')
      expect(response_data['rtt_stats']).to have_key('std_dev')
    end

    it 'returns error for invalid time format' do
      get "/ips/#{ip_address.id}/stats", {
        time_from: 'invalid-time',
        time_to: time_to.iso8601,
      }

      expect(last_response).to have_http_status(:bad_request)
      response_data = Oj.load(last_response.body)
      expect(response_data['error']).to include('Invalid time format')
    end

    it 'returns error for missing time parameters' do
      get "/ips/#{ip_address.id}/stats"

      expect(last_response).to have_http_status(:bad_request)
      response_data = Oj.load(last_response.body)
      expect(response_data['error']).to include('Missing required parameters')
    end

    it 'returns error for invalid ID format' do
      get '/ips/abc/stats', {
        time_from: time_from.iso8601,
        time_to: time_to.iso8601,
      }

      expect(last_response).to have_http_status(:bad_request)
      response_data = Oj.load(last_response.body)
      expect(response_data['error']).to eq('Invalid IP address ID format')
    end

    it 'returns error when time_from is after time_to' do
      get "/ips/#{ip_address.id}/stats", {
        time_from: time_to.iso8601,
        time_to: time_from.iso8601,
      }

      expect(last_response).to have_http_status(:bad_request)
      response_data = Oj.load(last_response.body)
      expect(response_data['error']).to include('time_from must be earlier than time_to')
    end
  end

  describe 'DELETE /ips/:id' do
    let(:ip_address) { create(:ip_address) }

    it 'deletes the IP address' do
      delete "/ips/#{ip_address.id}"

      expect(last_response).to have_http_status(:ok)
      response_data = Oj.load(last_response.body)
      expect(response_data['message']).to eq('IP address deleted')

      expect(IpAddress[ip_address.id]).to be_nil
    end

    it 'returns 404 for non-existent IP' do
      delete '/ips/999'

      expect(last_response).to have_http_status(:not_found)
      response_data = Oj.load(last_response.body)
      expect(response_data['error']).to eq('IP address not found')
    end

    it 'returns 400 for invalid ID format' do
      delete '/ips/abc'

      expect(last_response).to have_http_status(:bad_request)
      response_data = Oj.load(last_response.body)
      expect(response_data['error']).to eq('Invalid IP address ID format')
    end
  end

  describe 'GET /ips' do
    it 'returns list of all IP addresses' do
      create(:ip_address, ip: '8.8.8.8')
      create(:ip_address, ip: '1.1.1.1')

      get '/ips'

      expect(last_response).to have_http_status(:ok)
      response_data = Oj.load(last_response.body)
      expect(response_data.length).to eq(2)
      expect(response_data.map { |ip| ip['ip'] }).to contain_exactly('8.8.8.8', '1.1.1.1')
    end
  end
end
