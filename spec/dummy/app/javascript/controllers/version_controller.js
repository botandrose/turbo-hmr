import { Controller } from "@hotwired/stimulus"
import version from "../utility"

export default class extends Controller {
  connect() {
    this.element.textContent = version
  }
}
