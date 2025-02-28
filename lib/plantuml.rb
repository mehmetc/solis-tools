require 'zlib'
require 'base64'

PLANTUML_ENCODING = '0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz-_'.chars
class PlantUML
  def self.url_for_uml(uml)
    encoded_uml = self.encode_plantuml(uml)
    "https://www.plantuml.com/plantuml/svg/#{encoded_uml}"
  end

  def self.encode_plantuml(uml)
    # Deflate (zlib) compression, removing the first two and last four bytes
    compressed = Zlib::Deflate.deflate(uml, Zlib::BEST_COMPRESSION)[2..-5]

    # Custom Base64 encoding
    encode6bit = ->(b) { PLANTUML_ENCODING[b] }

    encoded = ''
    buffer = 0
    bits = 0

    compressed.each_byte do |byte|
      buffer = (buffer << 8) | byte
      bits += 8
      while bits >= 6
        bits -= 6
        encoded << encode6bit.call((buffer >> bits) & 0b111111)
      end
    end

    # Handle remaining bits
    encoded << encode6bit.call((buffer << (6 - bits)) & 0b111111) if bits > 0
    encoded
  end
end