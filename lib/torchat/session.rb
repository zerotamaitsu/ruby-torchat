#--
# Copyleft meh. [http://meh.paranoid.pk | meh@paranoici.org]
#
# This file is part of torchat for ruby.
#
# torchat for ruby is free software: you can redistribute it and/or modify
# it under the terms of the GNU Affero General Public License as published
# by the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# torchat for ruby is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU Affero General Public License for more details.
#
# You should have received a copy of the GNU Affero General Public License
# along with torchat for ruby. If not, see <http://www.gnu.org/licenses/>.
#++

require 'eventmachine'
require 'em-socksify'

require 'torchat/session/buddies'

class Torchat

class Session
	attr_reader :config, :buddies, :name, :description
	attr_writer :client, :version

	def initialize (config)
		@config = config

		@callbacks = Hash.new { |h, k| h[k] = [] }
		@buddies   = Buddies.new
		@timers    = []

		on :verification do |buddy|
			buddy.send_packet :client,  client
			buddy.send_packet :version, version

			buddy.send_packet :add_me

			buddy.send_packet :status,  :available
		end

		on :profile_name do |packet, buddy|
			buddy.name = packet.to_str
		end

		on :profile_text do |packet, buddy|
			buddy.description = packet.to_str
		end

		on :profile_avatar_alpha do |packet, buddy|
			buddy.avatar.alpha = packet.data
		end

		on :profile_avatar do |packet, buddy|
			buddy.avatar.rgb = packet.data
		end

		yield self if block_given?
	end

	def id
		@config['address'][/^(.*?)(\.onion)?$/, 1]
	end

	def address
		"#{id}.onion"
	end

	def client
		@client || 'ruby-torchat'
	end
	
	def version
		@version || Torchat.version
	end

	def tor
		Struct.new(:host, :port).new(
			@config['connection']['outgoing']['host'],
			@config['connection']['outgoing']['port'].to_i
		)
	end

	def name= (value)
		@name = value

		buddies.each {|buddy|
			buddy.send_packet :profile_name, value
		}
	end

	def description= (value)
		@description = value

		buddies.each {|buddy|
			buddy.send_packet :profile_text, value
		}

	end

	def add_buddy (address)
		buddies << Buddy.new(self, address)
	end

	def on (what, &block)
		@callbacks[what] << block
	end

	def received (packet)
		@callbacks[packet.type].each {|block|
			block.call(packet, packet.from)
		}
	end

	def fire (name, *args, &block)
		@callbacks[name].each {|block|
			block.call *args, &block
		}
	end

	def start (host = nil, port = nil)
		host ||= @config['connection']['incoming']['host']
		port ||= @config['connection']['incoming']['port'].to_i

		zelf = self

		@signature = EM.start_server host, port, Incoming do |incoming|
			incoming.instance_eval { @session = zelf }
		end
	end

	def stop
		EM.stop_server @signature

		@timers.each {|timer|
			EM.cancel_timer(timer)
		}
	end

	def set_timeout (*args, &block)
		EM.schedule {
			EM.add_timer(*args, &block).tap {|timer|
				@timers.push(timer)
			}
		}
	end

	def set_interval (*args, &block)
		EM.schedule {
			EM.add_periodic_timer(*args, &block).tap {|timer|
				@timers.push(timer)
			}
		}
	end

	def clear_timeout (what)
		EM.schedule {
			EM.cancel_timer(what)
		}
	end

	alias clear_interval clear_timeout
end

end
