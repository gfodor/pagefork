fs = require "fs"
async = require "async"

module.exports = class MHTMLIngestor
  ingest: (sourceDir, primaryContentPath, cb) ->
    self = this
    this.callback = cb

    this.getFiles sourceDir, (err, files) ->
      return self.callback(err) if err
      console.log(files)
      self.callback()

  getFiles: (dir, cb) ->
    pending = [dir]
    allFiles = []

    async.whilst (-> pending.length > 0), ((callback) ->
      next = pending.pop()

      fs.readdir next, (err, files) ->
        files ?= []

        for file in files
          path = "#{next}/#{file}"
          stat = fs.statSync(path)

          if stat.isFile()
            allFiles.push(path)
          else if stat.isDirectory()
            pending.push(path)

        callback()
    ), ((err) -> cb(err, allFiles))

