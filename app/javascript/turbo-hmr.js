class TurboHmr {
  constructor() {
    this.currentImportmap = null
    this.application = null
    this.pendingImportmap = null
    this.changes = { controllers: [], others: [] }
  }

  start(application) {
    this.application = application
    this.currentImportmap = this.extractImportmapFromDoc(document)

    document.addEventListener("turbo:before-fetch-response", this.handleBeforeFetchResponse.bind(this))
    document.addEventListener("turbo:before-render", this.handleBeforeRender.bind(this))
  }

  async handleBeforeFetchResponse(event) {
    const response = event.detail.fetchResponse
    const html = await response.responseHTML
    this.pendingImportmap = this.extractImportmapFromHtml(html)
  }

  handleBeforeRender(event) {
    if (!this.pendingImportmap || !this.currentImportmap) return

    this.detectChanges(this.currentImportmap, this.pendingImportmap)

    // console.log("turbo-hmr: changes:", this.changes)

    if (this.changes.others.length > 0) {
      // console.log("turbo-hmr: Non-controller imports changed, triggering reload")
      event.preventDefault()
      location.reload()

    } else if (this.changes.controllers.length > 0) {
      // console.log("turbo-hmr: Hot-swapping controllers:", this.changes.controllers)

      // Unload removed controllers before render
      const removedControllers = this.changes.controllers.filter(c => c.newUrl === null)
      for (const change of removedControllers) {
        this.unloadController(change.identifier)
      }

      // Reload added/changed controllers after render
      requestAnimationFrame(() => {
        const addedOrChangedControllers = this.changes.controllers.filter(c => c.newUrl !== null)
        Promise.all(addedOrChangedControllers.map(change =>
          this.reloadController(change.identifier, change.newUrl)
        ))
          .then(() => {
            // console.log("turbo-hmr: successfully hot-swapped controllers")
            this.currentImportmap = this.pendingImportmap
          })
          .catch(error => {
            console.error("turbo-hmr: Failed to hot-swap controllers", error)
            location.reload()
          })
      })
    } else {
      this.currentImportmap = this.pendingImportmap
    }
  }

  extractImportmapFromDoc(doc) {
    const importmapScript = doc.querySelector('script[type="importmap"]')
    if (!importmapScript) return null
    return this.parseImportmap(importmapScript.textContent)
  }

  extractImportmapFromHtml(html) {
    // Avoid DOMParser: parsing HTML with inline style="..." attributes triggers
    // style-src CSP violations in Firefox. Extract the importmap <script> content via regex.
    const match = html.match(/<script[^>]*\btype\s*=\s*["']importmap["'][^>]*>([\s\S]*?)<\/script>/i)
    if (!match) return null
    return this.parseImportmap(match[1])
  }

  parseImportmap(text) {
    try {
      return JSON.parse(text)
    } catch (e) {
      console.error("turbo-hmr: Failed to parse importmap", e)
      return null
    }
  }

  detectChanges(oldMap, newMap) {
    this.changes = { controllers: [], others: [] }

    for (const [identifier, url] of Object.entries(newMap.imports)) {
      const oldUrl = oldMap.imports[identifier]
      const isController = this.isControllerImport(identifier)

      if (!oldUrl) {
        // Added
        const change = { identifier, oldUrl: null, newUrl: url }
        isController ? this.changes.controllers.push(change) : this.changes.others.push(change)
      } else if (oldUrl !== url) {
        // Changed
        const change = { identifier, oldUrl, newUrl: url }
        isController ? this.changes.controllers.push(change) : this.changes.others.push(change)
      }
    }

    // Removed
    for (const [identifier, url] of Object.entries(oldMap.imports)) {
      if (!newMap.imports[identifier]) {
        const isController = this.isControllerImport(identifier)
        const change = { identifier, oldUrl: url, newUrl: null }
        isController ? this.changes.controllers.push(change) : this.changes.others.push(change)
      }
    }
  }

  isControllerImport(identifier) {
    return identifier.startsWith("controllers/")
  }

  async hotSwapControllers() {
    for (const change of this.changes.controllers) {
      if (change.newUrl) {
        await this.reloadController(change.identifier, change.newUrl)
      } else {
        await this.unloadController(change.identifier)
      }
    }
  }

  async reloadController(identifier, url) {
    const controllerName = this.identifierToControllerName(identifier)
    const module = await import(url)
    this.application.unload(controllerName)
    this.application.register(controllerName, module.default)
    // console.log(`turbo-hmr: Reloaded controller "${controllerName}" from ${url}`)
  }

  async unloadController(identifier) {
    const controllerName = this.identifierToControllerName(identifier)
    this.application.unload(controllerName)
    // console.log(`turbo-hmr: Unloaded controller "${controllerName}"`)
  }

  identifierToControllerName(identifier) {
    // "controllers/version_controller" => "version"
    // "controllers/admin/users_controller" => "admin--users"
    return identifier
      .replace("controllers/", "")
      .replace("_controller", "")
      .replace(/\//g, "--")
      .replace(/_/g, "-")
  }
}

const hotswap = new TurboHmr()
export function start(application) {
  hotswap.start(application)
}
export default { start }
