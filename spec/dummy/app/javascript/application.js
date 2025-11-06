import "@hotwired/turbo-rails"
import { Application } from "@hotwired/stimulus"
import { start as startTurboHmr } from "turbo-hmr"

window.Stimulus = Application.start()
import { eagerLoadControllersFrom } from "@hotwired/stimulus-loading"
eagerLoadControllersFrom("controllers", window.Stimulus)

startTurboHmr(window.Stimulus)
