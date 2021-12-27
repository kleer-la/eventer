# frozen_string_literal: true

class User < ApplicationRecord
  has_and_belongs_to_many :roles

  # Include default devise modules. Others available are:
  # :registerable, :token_authenticatable, :encryptable, :confirmable, :lockable, :timeoutable and :omniauthable
  devise :database_authenticatable,
         :recoverable, :rememberable, :trackable, :validatable

  def role?(role)
    !!roles.find_by_name(role.to_s)
  end
end
