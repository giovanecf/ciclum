require "digest"
require "securerandom"

class User < ApplicationRecord
  GUEST_SESSION_TTL = 24.hours

  has_secure_password validations: false

  has_many :study_cycles, dependent: :destroy
  has_many :cycle_subjects, through: :study_cycles
  has_many :study_sessions, through: :study_cycles

  before_validation :normalize_email

  validates :full_name, length: { maximum: 150 }, allow_blank: true
  validates :email, presence: true, uniqueness: { case_sensitive: false }, unless: :guest?
  validates :password, presence: true, if: -> { !guest? && new_record? }
  validates :password, length: { minimum: 8, maximum: 72 }, if: -> { password.present? }
  validates :password, confirmation: true, if: -> { password.present? }
  validates :password_confirmation, presence: true, if: -> { !guest? && new_record? }

  scope :guests, -> { where.not(guest_token_digest: nil) }

  def self.create_guest!
    token = SecureRandom.urlsafe_base64(32)
    user = create!(guest_token_digest: digest_guest_token(token), guest_expires_at: GUEST_SESSION_TTL.from_now)
    [user, token]
  end

  def self.digest_guest_token(token)
    Digest::SHA256.hexdigest(token)
  end

  def self.purge_expired_guests!
    guests.where("guest_expires_at IS NULL OR guest_expires_at <= ?", Time.current).find_each(&:destroy!)
  end

  def self.find_active_guest(token)
    return if token.blank?

    guest = guests.find_by(guest_token_digest: digest_guest_token(token))
    return unless guest&.guest_expires_at&.future?

    guest.update_column(:guest_expires_at, GUEST_SESSION_TTL.from_now)
    guest
  end

  def guest? = guest_token_digest.present?

  private

  def normalize_email
    self.email = email.to_s.strip.downcase.presence unless guest?
  end
end
