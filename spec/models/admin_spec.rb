# == Schema Information
#
# Table name: admins
#
#  id              :uuid             not null, primary key
#  email           :string           not null
#  password_digest :string           not null
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#
# Indexes
#
#  index_admins_on_email  (email) UNIQUE
#
require 'rails_helper'

RSpec.describe Admin, type: :model do
  describe 'validations' do
    subject { build(:admin) }

    it { is_expected.to be_valid }

    it 'requires an email' do
      subject.email = nil
      expect(subject).not_to be_valid
      expect(subject.errors[:email]).to include("can't be blank")
    end

    it 'requires a unique email' do
      create(:admin, email: 'admin@example.com')
      subject.email = 'admin@example.com'
      expect(subject).not_to be_valid
      expect(subject.errors[:email]).to include('has already been taken')
    end

    it 'requires a password' do
      admin = Admin.new(email: 'test@example.com')
      expect(admin).not_to be_valid
      expect(admin.errors[:password]).to include("can't be blank")
    end
  end

  describe 'authentication' do
    let(:admin) { create(:admin, email: 'admin@example.com', password: 'securepassword') }

    it 'authenticates with correct password' do
      expect(admin.authenticate('securepassword')).to eq(admin)
    end

    it 'does not authenticate with incorrect password' do
      expect(admin.authenticate('wrongpassword')).to be false
    end
  end
end
