{EventEmitter}  = require 'events'
debug           = require('debug')('meshblu-connector-ws2811:index')
ws281x          = require 'rpi-ws281x-native'
tinycolor       = require 'tinycolor2'

class Ws2811Leds extends EventEmitter
  constructor: ->
    @numleds = 50
    @initializedAs = -1
    @swapRG = false
    @offset = 0
    @color = "red"
    @mode = "off"
    @slide = 0
    @slidemax = @numleds
    @percent = 100
    @directcontrol = undefined
    @pixelData = new Uint32Array(@numleds)
    @modulate = new Uint32Array(@numleds)

    setInterval ((x) ->
      i = 0
      while i < x.numleds
        if ((i + x.offset) % 20) == 0
          if Math.random() > 0.5
            x.modulate[i] = 1
          else
            x.modulate[i] = 0

        switch x.mode
          when 'off'
            x.pixelData[i] = 0
          when 'color'
            color = tinycolor(x.color)
            rgb = color.toRgb()
            x.pixelData[i] = x.rgb2Int(rgb.r, rgb.g, rgb.b)
          when 'solid'
            color = tinycolor(x.color)
            rgb = color.toRgb()
            x.pixelData[i] = x.rgb2Int(rgb.r, rgb.g, rgb.b)
          when 'slide'
            rgb1 = tinycolor("green").toRgb()
            rgb2 = tinycolor("orange").toRgb()
            rgb3 = tinycolor("red").toRgb()
            if (i + 1) < x.slide
              x.pixelData[i] = x.rgb2Int(rgb1.r, rgb1.g, rgb1.b)
            else if (i + 1) == x.slide
              x.pixelData[i] = x.rgb2Int(rgb2.r, rgb2.g, rgb2.b)
            else if (i + 1) <= x.slidemax
              x.pixelData[i] = x.rgb2Int(rgb3.r, rgb3.g, rgb3.b)
            else
              x.pixelData[i] = 0
          when 'colorwheel'
            x.pixelData[i] = x.colorwheel(i, x.offset)
          when 'twinkle'
            x.pixelData[i] = x.colorwheel(i, x.offset) * x.modulate[i]
          when 'percent'
            threshold = Math.round((x.percent/100.0)*x.numleds)
            color = tinycolor(x.color)
            rgb = color.toRgb()
            if i < threshold
              x.pixelData[i] = x.rgb2Int(rgb.r, rgb.g, rgb.b)
            else
              x.pixelData[i] = 0
          when 'direct'
            colortxt = undefined
            if x.directcontrol?.groups?
              for group in x.directcontrol.groups
                if group.leds?
                  if group.leds.indexOf(i) > -1
                    colortxt = group.color
            if colortxt
              color = tinycolor(colortxt)
              rgb = color.toRgb()
              x.pixelData[i] = x.rgb2Int(rgb.r, rgb.g, rgb.b)
            else
              x.pixelData[i] = 0

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

  setColor: (color) =>
    @color = color
    debug 'color', @color

  setSlide: (slide) =>
    @slide = parseInt(slide)
    debug 'slide', @slide

  setSlideMax: (slidemax) =>
    @slidemax = parseInt(slidemax)
    @debug 'slidemax', @slidemax

  setPercent: (percent) =>
    @percent = parseInt(percent)
    debug 'percent', @percent

  setConfig: (config) =>
    @directcontrol = config
    debug 'directcontrol', @directcontrol

  setMode: ({ mode }) =>
    @mode = mode
    debug 'mode', @mode

  onConfig: (device={}) =>
    debug 'on config', device.options
    { @numleds, @swapRG } = device.options ? {}
    @mode = device.options.mode if device?.options?.mode?
    @color = device.options.color if device?.options?.color?
    if @initializedAs != @numleds
      debug 'initialising ws281x driver for LED count', @numleds
      ws281x.init @numleds
      @initializedAs = @numleds
    @pixelData = new Uint32Array(@numleds)
    @modulate = new Uint32Array(@numleds)
    debug 'mode and color are', @mode, @color
    debug 'swapRG', @swapRG
    
  rgb2Int: (r, g, b) =>
    if @swapRG
      ((r & 0xff) << 8) + ((g & 0xff) << 16) + (b & 0xff)
    else
      ((r & 0xff) << 16) + ((g & 0xff) << 8) + (b & 0xff)

  colorwheel: (pos, offset) =>
    pos = (pos + offset) % 256
    pos = 255 - pos
    if pos < 85
      @rgb2Int 255 - (pos * 3), 0, pos * 3
    else if pos < 170
      pos -= 85
      @rgb2Int 0, pos * 3, 255 - (pos * 3)
    else
      pos -= 170
      @rgb2Int pos * 3, 255 - (pos * 3), 0

  start: (device, callback) =>
    debug 'started'
    @onConfig device
    callback()



module.exports = Ws2811Leds
