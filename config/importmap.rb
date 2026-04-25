# Pin npm packages by running ./bin/importmap

pin "application"
pin "@hotwired/turbo-rails", to: "turbo.min.js"
pin "@hotwired/stimulus", to: "stimulus.min.js"
pin "@hotwired/stimulus-loading", to: "stimulus-loading.js"
pin_all_from "app/javascript/controllers", under: "controllers"
pin "@rails/actioncable", to: "actioncable.esm.js"
pin_all_from "app/javascript/channels", under: "channels"
pin "@rails/request.js", to: "@rails--request.js.js" # @0.0.13
pin "@rails/ujs", to: "@rails--ujs.js" # @7.1.3
pin "emoji-picker-element", to: "https://cdn.jsdelivr.net/npm/emoji-picker-element@1.29.1/+esm" # @1.29.1
