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

require 'yaml'
require 'digest/md5'

require 'torchat/version'
require 'torchat/session'
require 'torchat/protocol'

class Torchat
	attr_reader :config, :session

	def initialize (path)
		@config = YAML.parse_file(path).transform
	end

	def start (&block)
		@session = Session.new(@config, &block)
		
		@session.start
	end

	def send_packet_to (name, packet)
		@session.buddies[name].send_packet(packet)
	end
end
