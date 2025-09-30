require_relative '../interfaces/service_interface'

class RequestHandler
  include ServiceInterface

  class << self
    def handle_post_ips(request_body)
      data = Oj.load(request_body)
      IpAddressesController.create(data)
    end

    def handle_get_ips
      IpAddressesController.index
    end

    def handle_get_ip(id)
      IpAddressesController.show(id)
    end

    def handle_delete_ip(id)
      IpAddressesController.destroy(id)
    end

    def handle_enable_ip(id)
      IpAddressesController.enable(id)
    end

    def handle_disable_ip(id)
      IpAddressesController.disable(id)
    end

    def handle_ip_stats(id, time_from, time_to)
      IpAddressesController.stats(id, time_from, time_to)
    end

    def handle_health_check
      HealthController.check
    end
  end
end
