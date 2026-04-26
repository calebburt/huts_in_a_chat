# Be sure to restart your server when you modify this file.

# Inline <script> blocks in views must be opted in with nonce: true (e.g.
# `<%= javascript_tag nonce: true do %>`) so Rails injects the per-request
# nonce that satisfies script-src.
#
# Inline style="…" attributes are still in use throughout the app, so style-src
# allows 'unsafe-inline' for now. Tighten by moving inline styles to classes if
# you want a stricter policy.
Rails.application.configure do
  config.content_security_policy do |policy|
    policy.default_src :self
    policy.font_src    :self, :https, :data
    policy.img_src     :self, :https, :data, :blob
    policy.object_src  :none
    policy.script_src  :self, "https://cdn.jsdelivr.net"
    policy.style_src   :self, :unsafe_inline
    policy.connect_src :self, "wss:", "https:"
    policy.frame_ancestors :none
    policy.base_uri    :self
    policy.form_action :self
  end

  # Per-request nonce; use `nonce: true` on javascript_tag to attach it.
  config.content_security_policy_nonce_generator = ->(request) { SecureRandom.base64(16) }
  config.content_security_policy_nonce_directives = %w[script-src]
end
