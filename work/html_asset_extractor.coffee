class HtmlAssetExtractor
  NODE_TYPE =
    ELEMENT: 1
    TEXT: 3
    COMMENT: 8

  INTERNAL_HOST = "http://assets.pagefork.io"

  extract: (html, host, forkId, sourceProtocol) ->
    this.sourceProtocol ?= "http"
    this.sourceHost ?= "localhost"
    this.forkId = forkId

    # find all the assets, and inject new URLS, returning cleaned HTML
    assetMap = { stylesheets: [], images: [], scripts: [] }
    container = document.createElement('html')
    container.innerHTML = html

    this.extractAssetsFromNode(container, assetMap, false)

    newBody = $("body", container)
    newBody = $(container) unless newBody.length > 0

    { assets: assetMap, html: newBody.html() }

  extractAssetsFromNode: (node, assetMap, isHead) ->
    if node.nodeType == NODE_TYPE.ELEMENT
      collection = null
      tag = node.tagName.toLowerCase()

      switch tag
        when "head"
          isHead = true
        when "script"
          asset = this.assetPackageFromNode(node, "src")
          collection = assetMap.scripts if asset
        when "link"
          attributes = this.attributeMapForNode(node)

          if attributes.rel == "stylesheet"
            asset = this.assetPackageFromNode(node, "href")
            collection = assetMap.stylesheets if asset
        when "img"
          asset = this.assetPackageFromNode(node, "src")
          collection = assetMap.images if asset

      asset.isHead = isHead if asset && isHead
      collection[collection.length] = asset if asset && collection

    this.extractAssetsFromNode(childNode, assetMap, isHead) for childNode in node.childNodes


  attributeMapForNode: (node) ->
    attributeMap = {}

    for attribute in node.attributes
      attributeMap[attribute.name.toLowerCase()] = attribute.value

    attributeMap

  assetPackageFromNode: (node, urlAttribute) ->
    attributes = this.attributeMapForNode(node)
    return null unless attributes[urlAttribute]?

    asset = { attributes: {} }

    for name, value of attributes
      asset.attributes[name] = value

    for attribute in node.attributes
      if attribute.name.toLowerCase() == urlAttribute
        externalUrl = this.absolutizeUrl(attribute.value)
        internalUrl = this.externalToInternalUrl(externalUrl)
        attribute.value = internalUrl

        asset.source = externalUrl
        asset.attributes[name] = internalUrl

    asset

  externalToInternalUrl: (externalUrl) ->
    a = document.createElement("a")
    a.href = externalUrl

    internalUrl = "#{INTERNAL_HOST}/#{this.forkId}/#{a.host}#{a.pathname}"
    internalUrl += "/#{a.search.replace(/^\?/, "")}" if a.search && a.search.length > 0
    internalUrl

  absolutizeUrl: (url) ->
    if url.toLowerCase().indexOf("http") == 0
      url
    else if url.toLowerCase().indexOf("//") == 0
      "#{this.sourceProtocol}:#{url}"
    else
      url = "/#{url}" unless url.indexOf("/") == 0
      "#{this.sourceProtocol}//#{this.sourceHost}#{url}"

window.HtmlAssetExtractor = HtmlAssetExtractor
