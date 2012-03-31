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

require 'torchat/session/incoming'
require 'torchat/session/outgoing'

class Torchat; class Session

class Buddy
	class Avatar
		attr_writer :rgb, :alpha

		def to_image
			return unless @rgb

			require 'RMagick'

			Magick::Image.new(64, 64).tap {|image|
				@rgb.bytes.each_slice(3).with_index {|(r, g, b), index|
					x, y = index % 64, index / 64

					image.pixel_color(x, y, Magick::Pixel.new(r, g, b, @alpha ? @alpha[index] : nil))
				}
			}
		end
	end

	Client = Struct.new(:name, :version)

	attr_reader   :session, :id, :address, :avatar, :client
	attr_writer   :status
	attr_accessor :name, :description

	def port; 11009; end

	def initialize (session, id, incoming = nil, outgoing = nil)
		unless Protocol.valid_address?(id)
			raise ArgumentError, "#{id} is an invalid onion id"
		end

		@session = session
		@id      = id[/^(.*?)(\.onion)?$/, 1]
		@address = "#{@id}.onion"
		@avatar  = Avatar.new
		@client  = Client.new

		own! incoming
		own! outgoing

		connect unless @outgoing
	end

	def status
		online? ? @status : :offline
	end

	def on (what, &block)
		session.on what do |*args|
			if (args.first.is_a?(Buddy) && args.first == self) || (args.first.is_a?(Protocol::Packet) && args.first.from == self)
				block.call(*args)
			end
		end
	end

	alias when on

	def own! (what)
		if what.is_a? Incoming
			@incoming = what
		elsif what.is_a? Outgoing
			@outgoing = what
		end

		@incoming.owner = self if @incoming
		@outgoing.owner = self if @outgoing
	end

	def pinged?; @pinged;         end
	def ping!;   @pinged = true;  end
	def pong!;   @pinged = false; end

	def send_packet (*args)
		raise 'you cannot send packets yet' unless @outgoing

		@outgoing.send_packet *args
	end

	def send_packet! (*args)
		raise 'you cannot send packets yet' unless @outgoing

		@outgoing.send_packet! *args
	end

	def send_message (text)
		send_packet :message, text
	end

	def online?; connected?; end
	def offline?; !online?;  end

	def ready?; @ready;        end
	def ready!; @ready = true; end

	def connecting?; @connecting; end

	def connect
		return if connecting? || connected?

		@connecting = true

		EM.connect session.tor.host, session.tor.port, Outgoing do |outgoing|
			own! outgoing

			outgoing.instance_variable_set :@session, session

			outgoing.pending_connect_timeout = session.connection_timeout

			session.fire :outgoing, outgoing
		end
	end

	def connected?; @connected; end

	def connected
		return if connected?

		@connecting = false
		@connected  = true

		send_packet! :ping, session.address

		ping!

		session.fire :connection, self
	end

	def verified?; @verified; end

	def verified
		return if verified?

		@verified = true

		@outgoing.verification_completed

		session.fire :verification, self
	end

	def disconnect
		return if disconnected?

		@incoming.close_connection_after_writing if @incoming
		@outgoing.close_connection_after_writing if @outgoing

		@outgoing = @incoming = nil

		disconnected
	end

	def disconnected?; !@connected; end

	def disconnected
		return if disconnected?

		@verified = @ready = @connecting = @connected = false

		disconnect

		session.fire :disconnection, self
	end

	def inspect
		"#<Torchat::Buddy(#{id})#{": #{name}#{", #{description}" if description}" if name}>"
	end
end

end; end