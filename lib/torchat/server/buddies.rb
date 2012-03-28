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

require 'torchat/server/buddy'

class Torchat; class Server

class Buddies < Hash
	def [] (name)
		super(name) || super(name[/^(.*?)(\.onion)?$/, 1]) || find { |a, b| name === b.alias || name === b.name }
	end

	def []= (name, buddy)
		unless Protocol.valid_address?(name)
			name = find { |a, b| name === b.alias || name === b.name }.address
		end

		name = name[/^(.*?)(\.onion)?$/, 1]

		super(name, buddy)
	end

	def << (buddy)
		self[buddy.address] = buddy
	end
end

end; end
