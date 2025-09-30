FactoryBot.define do
  factory :ping_result do
    association :ip_address
    rtt { Faker::Number.decimal(l_digits: 2, r_digits: 2) }
    success { true }
  end

  factory :failed_ping_result, class: 'PingResult' do
    association :ip_address
    rtt { nil }
    success { false }
  end
end

