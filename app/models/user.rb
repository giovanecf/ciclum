class User < ApplicationRecord
  has_secure_password

  has_many :study_cycles, dependent: :destroy
  has_many :cycle_subjects, through: :study_cycles
  has_many :study_sessions, through: :study_cycles

  before_validation :normalize_email

  validates :email, presence: true, uniqueness: { case_sensitive: false }
  validates :password, length: { minimum: 8, maximum: 72 }, if: -> { password.present? }
  validates :password, confirmation: true, if: -> { password.present? }
  validates :password_confirmation, presence: true, if: -> { password.present? }

  private

  def normalize_email
    self.email = email.to_s.strip.downcase
  end
end
