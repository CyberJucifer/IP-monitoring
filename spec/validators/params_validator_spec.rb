require 'spec_helper'

RSpec.describe ParamsValidator do
  describe '.validate_ip_params' do
    context 'with valid data' do
      it 'returns valid result for valid IPv4' do
        data = { 'ip' => '8.8.8.8', 'enabled' => true }
        result = described_class.validate_ip_params(data)
        expect(result[:valid]).to be true
        expect(result[:errors]).to be_empty
        expect(result[:data]).to eq({ ip: '8.8.8.8', enabled: true })
      end

      it 'returns valid result for valid IPv6' do
        data = { 'ip' => '2001:4860:4860::8888', 'enabled' => false }
        result = described_class.validate_ip_params(data)
        expect(result[:valid]).to be true
        expect(result[:errors]).to be_empty
        expect(result[:data]).to eq({ ip: '2001:4860:4860::8888', enabled: false })
      end

      it 'strips whitespace from IP address' do
        data = { 'ip' => '  8.8.8.8  ', 'enabled' => true }
        result = described_class.validate_ip_params(data)
        expect(result[:valid]).to be true
        expect(result[:data][:ip]).to eq('8.8.8.8')
      end
    end

    context 'with invalid data' do
      it 'returns error for non-hash data' do
        result = described_class.validate_ip_params('invalid')
        expect(result[:valid]).to be false
        expect(result[:errors]).to include('Request body must be a JSON object')
      end

      it 'returns error for missing ip field' do
        data = { 'enabled' => true }
        result = described_class.validate_ip_params(data)
        expect(result[:valid]).to be false
        expect(result[:errors]).to include('Missing required field: ip')
      end

      it 'returns error for missing enabled field' do
        data = { 'ip' => '8.8.8.8' }
        result = described_class.validate_ip_params(data)
        expect(result[:valid]).to be false
        expect(result[:errors]).to include('Missing required field: enabled')
      end

      it 'returns error for invalid IP format' do
        data = { 'ip' => 'invalid-ip', 'enabled' => true }
        result = described_class.validate_ip_params(data)
        expect(result[:valid]).to be false
        expect(result[:errors]).to include('Invalid IP address format')
      end

      it 'returns error for non-boolean enabled field' do
        data = { 'ip' => '8.8.8.8', 'enabled' => 'yes' }
        result = described_class.validate_ip_params(data)
        expect(result[:valid]).to be false
        expect(result[:errors]).to include('Field "enabled" must be boolean (true/false)')
      end

      it 'returns error for unpermitted parameters' do
        data = { 'ip' => '8.8.8.8', 'enabled' => true, 'extra_field' => 'value' }
        result = described_class.validate_ip_params(data)
        expect(result[:valid]).to be false
        expect(result[:errors]).to include('Unpermitted parameters: extra_field')
      end

      it 'returns multiple errors for multiple issues' do
        data = { 'ip' => 'invalid', 'enabled' => 'yes', 'extra' => 'field' }
        result = described_class.validate_ip_params(data)
        expect(result[:valid]).to be false
        expect(result[:errors]).to include('Invalid IP address format')
        expect(result[:errors]).to include('Field "enabled" must be boolean (true/false)')
        expect(result[:errors]).to include('Unpermitted parameters: extra')
      end
    end
  end

  describe '.validate_id_param' do
    it 'returns valid result for valid numeric ID' do
      result = described_class.validate_id_param('123')
      expect(result[:valid]).to be true
      expect(result[:id]).to eq(123)
    end

    it 'returns error for non-numeric ID' do
      result = described_class.validate_id_param('abc')
      expect(result[:valid]).to be false
      expect(result[:error]).to eq('Invalid IP address ID format')
    end

    it 'returns error for negative ID' do
      result = described_class.validate_id_param('-1')
      expect(result[:valid]).to be false
      expect(result[:error]).to eq('Invalid IP address ID format')
    end

    it 'returns error for decimal ID' do
      result = described_class.validate_id_param('1.5')
      expect(result[:valid]).to be false
      expect(result[:error]).to eq('Invalid IP address ID format')
    end

    it 'returns error for zero ID' do
      result = described_class.validate_id_param('0')
      expect(result[:valid]).to be false
      expect(result[:error]).to eq('IP address ID must be a positive integer')
    end
  end

  describe '.validate_time_params' do
    context 'with valid time parameters' do
      it 'returns valid result for valid time range' do
        time_from = 1.hour.ago.iso8601
        time_to = Time.now.iso8601
        result = described_class.validate_time_params(time_from, time_to)
        expect(result[:valid]).to be true
        expect(result[:errors]).to be_empty
        expect(result[:time_from]).to be_a(Time)
        expect(result[:time_to]).to be_a(Time)
      end
    end

    context 'with invalid time parameters' do
      it 'returns error for missing time_from' do
        result = described_class.validate_time_params(nil, Time.now.iso8601)
        expect(result[:valid]).to be false
        expect(result[:errors]).to include('Missing required parameters: time_from, time_to')
      end

      it 'returns error for missing time_to' do
        result = described_class.validate_time_params(1.hour.ago.iso8601, nil)
        expect(result[:valid]).to be false
        expect(result[:errors]).to include('Missing required parameters: time_from, time_to')
      end

      it 'returns error for invalid time format' do
        result = described_class.validate_time_params('invalid-time', 'also-invalid')
        expect(result[:valid]).to be false
        expect(result[:errors]).to include('Invalid time format. Use ISO 8601 format (e.g., 2024-01-01T00:00:00Z)')
      end

      it 'returns error when time_from is after time_to' do
        time_from = Time.now.iso8601
        time_to = 1.hour.ago.iso8601
        result = described_class.validate_time_params(time_from, time_to)
        expect(result[:valid]).to be false
        expect(result[:errors]).to include('time_from must be earlier than time_to')
      end

      it 'returns error for time range exceeding 1 year' do
        time_from = 2.years.ago.iso8601
        time_to = Time.now.iso8601
        result = described_class.validate_time_params(time_from, time_to)
        expect(result[:valid]).to be false
        expect(result[:errors]).to include('Time range cannot exceed 1 year')
      end

      it 'returns error for time_from more than 2 years in the past' do
        time_from = 3.years.ago.iso8601
        time_to = 2.years.ago.iso8601
        result = described_class.validate_time_params(time_from, time_to)
        expect(result[:valid]).to be false
        expect(result[:errors]).to include('time_from cannot be more than 2 years in the past')
      end

      it 'returns error for time_to in the future' do
        time_from = 1.hour.ago.iso8601
        time_to = 1.hour.from_now.iso8601
        result = described_class.validate_time_params(time_from, time_to)
        expect(result[:valid]).to be false
        expect(result[:errors]).to include('time_to cannot be in the future')
      end
    end
  end

  describe '.sanitize_ip_data' do
    it 'strips whitespace from IP address' do
      data = { 'ip' => '  8.8.8.8  ', 'enabled' => true }
      result = described_class.sanitize_ip_data(data)
      expect(result[:ip]).to eq('8.8.8.8')
    end

    it 'preserves boolean enabled value' do
      data = { 'ip' => '8.8.8.8', 'enabled' => false }
      result = described_class.sanitize_ip_data(data)
      expect(result[:enabled]).to be false
    end

    it 'handles non-hash input gracefully' do
      result = described_class.sanitize_ip_data('invalid')
      expect(result).to eq('invalid')
    end
  end
end
