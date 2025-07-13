# Be sure to restart your server when you modify this file.

# Define an application-wide content security policy.
# See the Securing Rails Applications Guide for more information:
# https://guides.rubyonrails.org/security.html#content-security-policy-header

Rails.application.configure do
  config.content_security_policy do |policy|
    policy.default_src :self, :https
    policy.font_src    :self, :https, :data
    policy.img_src     :self, :https, :data
    policy.object_src  :none
    
    # Allow inline scripts and scripts from Firebase CDN
    policy.script_src  :self, :https, :unsafe_inline, :unsafe_eval,
                       "https://www.gstatic.com",
                       "https://*.googleapis.com"
    
    # Allow inline styles
    policy.style_src   :self, :https, :unsafe_inline
    
    # Allow connections to Firebase services
    policy.connect_src :self, :https,
                       "https://*.googleapis.com",
                       "https://*.gstatic.com", 
                       "https://*.firebase.com",
                       "https://*.firebaseapp.com",
                       "https://securetoken.googleapis.com",
                       "https://identitytoolkit.googleapis.com"
    
    # Allow Firebase Auth popups and frames
    policy.frame_src   :self,
                       "https://*.firebaseapp.com",
                       "https://accounts.google.com",
                       "https://content.googleapis.com"
    
    # Allow child sources for Firebase Auth
    policy.child_src   :self,
                       "https://*.firebaseapp.com", 
                       "https://accounts.google.com"
    
    # Specify URI for violation reports
    # policy.report_uri "/csp-violation-report-endpoint"
  end

  # Generate session nonces for permitted importmap, inline scripts, and inline styles.
  config.content_security_policy_nonce_generator = ->(request) { request.session.id.to_s }
  config.content_security_policy_nonce_directives = %w(style-src)

  # Report violations without enforcing the policy.
  # config.content_security_policy_report_only = true
end
