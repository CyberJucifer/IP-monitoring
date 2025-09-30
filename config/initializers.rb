require_relative 'database'
require_relative 'logger'

# Load interfaces first
require_relative '../lib/interfaces/model_interface'
require_relative '../lib/interfaces/service_interface'
require_relative '../lib/interfaces/validator_interface'

# Load concerns
require_relative '../lib/concerns/id_validation'
require_relative '../lib/concerns/time_validation'

# Load models
require_relative '../lib/models/ip_address'
require_relative '../lib/models/ping_result'

# Load services
require_relative '../lib/services/ping_service'
require_relative '../lib/services/stats_service'
require_relative '../lib/services/request_handler'

# Load validators
require_relative '../lib/validators/base_validator'
require_relative '../lib/validators/params_validator'

# Load controllers
require_relative '../lib/controllers/base_controller'
require_relative '../lib/controllers/ip_addresses_controller'
require_relative '../lib/controllers/health_controller'

# Load scheduler
require_relative '../lib/scheduler'
