# Be sure to restart your server when you modify this file.

Newsly::Application.config.session_store :redis_session_store, :expire_after => 1.hour, :key => "newsly_session"

# Use the database for sessions instead of the cookie-based default,
# which shouldn't be used to store highly confidential information
# (create the session table with "rails generate session_migration")
# Newsly::Application.config.session_store :active_record_store
