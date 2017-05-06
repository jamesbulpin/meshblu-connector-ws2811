http = require 'http'

class XenLights
  constructor: ({@connector}) ->
    throw new Error 'XenLights requires connector' unless @connector?

  do: ({data}, callback) =>
    return callback @_userError(422, 'data.mode is required') unless data?.mode?

    {mode} = data
    @connector.setMode {mode}
    if data?.color?
      {color} = data
      @connector.setColor {color}

    metadata =
      code: 200
      status: http.STATUS_CODES[200]

    callback null, {metadata, data}

  _userError: (code, message) =>
    error = new Error message
    error.code = code
    return error

module.exports = XenLights
