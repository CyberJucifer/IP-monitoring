require_relative '../interfaces/service_interface'

class StatsService
  include ServiceInterface

  def initialize(ip_address, time_from, time_to)
    @ip_address = ip_address
    @time_from = time_from
    @time_to = time_to
  end

  def call
    calculate
  end

  def calculate
    results = relevant_ping_results

    if results.empty?
      raise StandardError, 'No data available for the specified time period'
    end

    stats = calculate_stats_with_sql(results)

    {
      time_from: @time_from.iso8601,
      time_to: @time_to.iso8601,
      total_pings: stats[:total_pings],
      successful_pings: stats[:successful_pings],
      packet_loss_percentage: stats[:packet_loss_percentage],
      rtt_stats: {
        min: stats[:min_rtt],
        max: stats[:max_rtt],
        mean: stats[:mean_rtt],
        median: stats[:median_rtt],
        std_dev: stats[:std_dev_rtt],
      },
    }
  end

  private

  def relevant_ping_results
    PingResult
      .for_ip(@ip_address.id)
      .for_period(@time_from, @time_to)
      .order(:created_at)
  end

  def calculate_stats_with_sql(results)
    query = results
            .select(
              Sequel.function(:count, :id).as(:total_pings),
              Sequel.function(:count, :rtt).as(:successful_pings),
              Sequel.function(:min, :rtt).as(:min_rtt),
              Sequel.function(:max, :rtt).as(:max_rtt),
              Sequel.function(:avg, :rtt).as(:mean_rtt),
              Sequel.function(:stddev, :rtt).as(:std_dev_rtt)
            )
            .first

    successful_results = results.where(Sequel.~(rtt: nil)).order(:rtt).all
    median_rtt = calculate_median(successful_results.map(&:rtt))

    total_pings = query[:total_pings] || 0
    successful_pings = query[:successful_pings] || 0
    packet_loss_percentage = if total_pings.positive?
                               ((total_pings - successful_pings).to_f / total_pings * 100).round(2)
                             else
                               0
                             end

    {
      total_pings: total_pings,
      successful_pings: successful_pings,
      packet_loss_percentage: packet_loss_percentage,
      min_rtt: query[:min_rtt]&.round(2),
      max_rtt: query[:max_rtt]&.round(2),
      mean_rtt: query[:mean_rtt]&.round(2),
      median_rtt: median_rtt&.round(2),
      std_dev_rtt: query[:std_dev_rtt]&.round(2),
    }
  end

  def calculate_median(values)
    return nil if values.empty?

    sorted_values = values.sort
    n = sorted_values.length

    if n.odd?
      sorted_values[n / 2]
    else
      (sorted_values[(n / 2) - 1] + sorted_values[n / 2]) / 2.0
    end
  end
end
