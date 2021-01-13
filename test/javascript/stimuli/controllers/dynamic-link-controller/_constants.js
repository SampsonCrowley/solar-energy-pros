import { DynamicLinkController } from "stimuli/controllers/dynamic-link-controller"
import { controllerRegistration } from "test-helpers/generators/stimulus/controller-registration"
import { TemplateController } from "test-helpers/generators/stimulus/template-controller"

DynamicLinkController.bless()

export const getElements = () => {
  const wrapper            = document.getElementById("controller-wrapper"),
        firstLink          = document.getElementById("first-link"),
        secondLink         = document.getElementById("second-link"),
        noReplacePhoneIcon = document.getElementById("no-replace-phone-icon"),
        noReplacePhoneSpan = document.getElementById("no-replace-phone-span"),
        replacePhoneIcon   = document.getElementById("replace-phone-icon"),
        replacePhoneSpan   = document.getElementById("replace-phone-span"),
        replaceAllDiv      = document.getElementById("replace-all-div"),
        nestedWrapper       = document.getElementById("nested-wrapper"),
        nestedLink         = document.getElementById("nested-link"),
        nestedReplace      = document.getElementById("nested-replace")

  return {
    wrapper,
    firstLink,
    secondLink,
    noReplacePhoneIcon,
    noReplacePhoneSpan,
    replacePhoneIcon,
    replacePhoneSpan,
    replaceAllDiv,
    nestedWrapper,
    nestedLink,
    nestedReplace
  }
}

export const template = `
<div id="controller-wrapper" data-controller="dynamic-link">
  <a
    id="first-link"
    data-action="click->dynamic-link#follow"
    href="mailto:benjcrowley@gmail.com"
    rel="noopener noreferrer"
    target="_blank"
  >
    benjcrowley@gmail.com
  </a>
  <a
    id="second-link"
    data-action="click->dynamic-link#follow"
    href="tel:+14357578004"
    rel="noopener noreferrer"
    target="_blank"
  >
    <i id="no-replace-phone-icon">
      phone
    </i>
    <span id="no-replace-phone-span">
      435-757-8004
    </span>
    <i id="replace-phone-icon" data-replace="tel|sms">
      sms
    </i>
    <span id="replace-phone-span" data-replace="tel|sms">
      Send Text
    </span>
    <div id="replace-all-div" data-replace="tel:+14357578004|https://solarenergypros.online">
      Replace All
    </div>
  </a>
  <div
    id="nested-wrapper"
    click="click->dynamic-link#follow"
  >
    <a id="nested-link" href="https://google.com">Google</a>
    <span
      id="nested-replace"
      data-replace="google|youtube"
    >
      Replace Google
    </span>
  </div>
</div>
`

export const createTemplateController = TemplateController(DynamicLinkController, template, "#controller-wrapper")

export const { registerController, unregisterController } = controllerRegistration(DynamicLinkController, template)
