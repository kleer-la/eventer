# frozen_string_literal: true

# Pin npm packages by running ./bin/importmap

pin 'im_application'
# pin 'trix'
# pin '@rails/actiontext', to: 'actiontext.esm.js'

# pin 'application', preload: true
# pin_all_from 'app/javascript/controllers', under: 'controllers'
pin '@rails/actiontext', to: 'https://cdn.skypack.dev/@rails/actiontext', preload: true
pin 'trix', to: 'https://cdn.skypack.dev/trix', preload: true
