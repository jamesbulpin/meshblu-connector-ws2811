{EventEmitter}  = require 'events'
debug           = require('debug')('meshblu-connector-say-hello:index')
ws281x          = require 'rpi-ws281x-native'
tinycolor       = require 'tinycolor2'

class SayHello extends EventEmitter
  constructor: ->
    @numleds = 50
    @offset = 0
    @color = "red"
    @mode = "colorwheel"
    @slide = 0
    @slidemax = 50
    ws281x.init 50
    @pixelData = new Uint32Array(50)
    @modulate = new Uint32Array(50)

    setInterval ((x) ->
      i = 0
      while i < x.numleds
        if ((i + x.offset) % 20) == 0
          if Math.random() > 0.5
            x.modulate[i] = 1
          else
            x.modulate[i] = 0

        switch x.mode
          when 'color'
            color = tinycolor(x.color)
            rgb = color.toRgb()
            x.pixelData[i] = rgb2Int(rgb.r, rgb.g, rgb.b)
          when 'solid'
            color = tinycolor(x.color)
            rgb = color.toRgb()
            x.pixelData[i] = rgb2Int(rgb.r, rgb.g, rgb.b)
          when 'slide'
            rgb1 = tinycolor("green").toRgb()
            rgb2 = tinycolor("orange").toRgb()
            rgb3 = tinycolor("red").toRgb()
            if (i + 1) < x.slide
              x.pixelData[i] = rgb2Int(rgb1.r, rgb1.g, rgb1.b)
            else if (i + 1) == x.slide
              x.pixelData[i] = rgb2Int(rgb2.r, rgb2.g, rgb2.b)
            else if (i + 1) <= x.slidemax
              x.pixelData[i] = rgb2Int(rgb3.r, rgb3.g, rgb3.b)
            else
              x.pixelData[i] = 0
          when 'colorwheel'
            x.pixelData[i] = colorwheel(i, x.offset)
          when 'twinkle'
            x.pixelData[i] = colorwheel(i, x.offset) * x.modulate[i]

        i++
      x.offset = x.offset + 1
      ws281x.render x.pixelData
      return
    ).bind(null, this), 10

  isOnline: (callback) =>
    callback null, running: true

  close: (callback) =>
    debug 'on close'
    callback()

  getResponse: () =>
    return "#{@color}, #{@mode}"

  setColor: ({ color }) =>
    @color = color

  setMode: ({ mode }) =>
    if mode.indexOf("slide") == 0
      x = mode.indexOf("/")
      @slide = parseInt(mode.substring(5, x))
      @slidemax = parseInt(mode.substring(x+1))
      mode = "slide"
    @mode = mode

  onConfig: (device={}) =>
    { @greeting } = device.options ? {}
    #{ @numleds } = device.options ? {}
    debug 'on config', @options

  rgb2Int = (r, g, b) =>
    ((r & 0xff) << 8) + ((g & 0xff) << 16) + (b & 0xff)

  colorwheel = (pos, offset) =>
    pos = (pos + offset) % 256
    pos = 255 - pos
    if pos < 85
      rgb2Int 255 - (pos * 3), 0, pos * 3
    else if pos < 170
      pos -= 85
      rgb2Int 0, pos * 3, 255 - (pos * 3)
    else
      pos -= 170
      rgb2Int pos * 3, 255 - (pos * 3), 0

  start: (device, callback) =>
    debug 'started'
    @onConfig device
    callback()



module.exports = SayHello
