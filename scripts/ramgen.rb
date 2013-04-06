#!/usr/bin/env ruby

#        INIT_00 => X"0000000000000000000000000000000000000000000000000000000000000000",

def bits2bytes(bits)
    (0..(bits.length/8 - 1)).map {|i| bits[i*8, 8].inject(0) {|r, x| (r << 1) | x}}
end

pixels = (0..16383).map {|i| 0}

# 8x8 checkers fill
(0..63).each do |bx|
(0..63).each do |by|
    x = bx
    y = by
    pixels[y*256 + x] = ((x/8 + y/8) % 2 == 0)? 1 : 0
end
end

# 1 of 8 vlines fill
(0..63).each do |bx|
(0..63).each do |by|
    x = bx + 64
    y = by
    pixels[y*256 + x] = ((x % 8) == 0)? 1 : 0
end
end

# 1 of 8 hlines fill
(0..63).each do |bx|
(0..63).each do |by|
    x = bx + 128
    y = by
    pixels[y*256 + x] = ((y % 8) == 0)? 1 : 0
end
end

# 1x1 checkers fill
(0..63).each do |bx|
(0..63).each do |by|
    x = bx + 192
    y = by
    pixels[y*256 + x] = ((x + y) % 2 == 1)? 1 : 0
end
end


bytes = bits2bytes(pixels)

puts (0..0x3F).map {|i| "INIT_%02X => X\"%s\""%[i, bytes[i*32, 32].inject("") {|r, x| r + "%02X"%x}]}.join(",\n")

