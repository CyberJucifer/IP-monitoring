FactoryBot.define do
  factory :ip_address do
    ip { Faker::Internet.ip_v4_address }
    enabled { true }
  end

  factory :ip_address_v6, class: 'IpAddress' do
    ip { Faker::Internet.ip_v6_address }
    enabled { true }
  end

  factory :disabled_ip_address, class: 'IpAddress' do
    ip { Faker::Internet.ip_v4_address }
    enabled { false }
  end
end

