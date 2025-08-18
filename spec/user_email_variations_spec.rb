require_relative 'spec_helper'

RSpec.describe UserEmailVariations do
  it 'module is prepended to User' do
    ancestors = User.ancestors
    expect(ancestors).to include(UserEmailVariations)
    expect(ancestors.index(UserEmailVariations)).to be < ancestors.index(User)
  end

  describe '#plus_email_variations' do
    let(:user) { FactoryBot.create(:user, email: 'john@example.com') }

    context 'when user has variations' do
      before do
        # Create users with plus variations of the base email
        FactoryBot.create(:user, email: 'john+newsletter@example.com')
        FactoryBot.create(:user, email: 'john+spam@example.com')
        FactoryBot.create(:user, email: 'john+shopping@example.com')
      end

      it 'returns all plus variations of the user email' do
        variations = user.plus_email_variations
        expect(variations).to contain_exactly(
          'john@example.com',
          'john+newsletter@example.com',
          'john+spam@example.com',
          'john+shopping@example.com'
        )
      end
    end

    context 'when user already has a plus variation' do
      let(:user) { FactoryBot.create(:user, email: 'john+main@example.com') }

      before do
        # Create base user and other variations
        FactoryBot.create(:user, email: 'john@example.com')
        FactoryBot.create(:user, email: 'john+newsletter@example.com')
        FactoryBot.create(:user, email: 'john+spam@example.com')
      end

      it 'finds variations based on the base email part' do
        variations = user.plus_email_variations
        expect(variations).to contain_exactly(
          'john@example.com',
          'john+newsletter@example.com',
          'john+spam@example.com'
        )
      end

      it 'excludes its own email from results' do
        variations = user.plus_email_variations
        expect(variations).not_to include('john+main@example.com')
      end
    end

    context 'when no variations exist' do
      it 'returns array with only user email when no other users with variations' do
        variations = user.plus_email_variations
        expect(variations).to eq(['john@example.com'])
      end

      it 'ignores users with different base emails' do
        FactoryBot.create(:user, email: 'jane+test@example.com')
        FactoryBot.create(:user, email: 'bob@example.com')

        variations = user.plus_email_variations
        expect(variations).to eq(['john@example.com'])
      end

      it 'ignores users with different domains' do
        FactoryBot.create(:user, email: 'john+test@gmail.com')
        FactoryBot.create(:user, email: 'john+newsletter@different.com')

        variations = user.plus_email_variations
        expect(variations).to eq(['john@example.com'])
      end
    end

    context 'SQL injection protection' do
      let(:user) { FactoryBot.create(:user, email: 'test%user@example.com') }

      before do
        # Create users that would match if SQL injection wasn't prevented
        FactoryBot.create(:user, email: 'test1user+newsletter@example.com')
        FactoryBot.create(:user, email: 'test2user+spam@example.com')
        # Create actual variations
        FactoryBot.create(:user, email: 'test%user+newsletter@example.com')
      end

      it 'escapes SQL wildcards and only finds exact matches' do
        variations = user.plus_email_variations
        expect(variations).to contain_exactly(
          'test%user@example.com',
          'test%user+newsletter@example.com'
        )
        expect(variations).not_to include('test1user+newsletter@example.com')
        expect(variations).not_to include('test2user+spam@example.com')
      end
    end

    context 'with underscore in email' do
      let(:user) { FactoryBot.create(:user, email: 'test_user@example.com') }

      before do
        # Create users that would match if SQL injection wasn't prevented
        FactoryBot.create(:user, email: 'test1user+newsletter@example.com')
        FactoryBot.create(:user, email: 'test2user+spam@example.com')
        # Create actual variations
        FactoryBot.create(:user, email: 'test_user+newsletter@example.com')
      end

      it 'escapes SQL wildcards and only finds exact matches' do
        variations = user.plus_email_variations
        expect(variations).to contain_exactly(
          'test_user@example.com',
          'test_user+newsletter@example.com'
        )
        expect(variations).not_to include('test1user+newsletter@example.com')
        expect(variations).not_to include('test2user+spam@example.com')
      end
    end

    context 'case sensitivity' do
      let(:user) { FactoryBot.create(:user, email: 'User@Example.Com') }

      before do
        FactoryBot.create(:user, email: 'User+test1@Example.Com')
        FactoryBot.create(:user, email: 'user+test2@example.com')
      end

      it 'handles case sensitivity according to database collation' do
        variations = user.plus_email_variations
        expect(variations).to contain_exactly(
          'User@Example.Com',
          'User+test1@Example.Com',
          'user+test2@example.com'
        )
      end
    end

    context 'with plus signs in the plus part' do
      let(:user) { FactoryBot.create(:user, email: 'test@example.com') }

      before do
        # Create variations with plus signs in the plus part
        FactoryBot.create(:user, email: 'test+work+urgent@example.com')
        FactoryBot.create(:user, email: 'test+personal+family@example.com')
      end

      it 'finds variations with multiple plus signs' do
        variations = user.plus_email_variations
        expect(variations).to contain_exactly(
          'test@example.com',
          'test+work+urgent@example.com',
          'test+personal+family@example.com'
        )
      end
    end
  end
end
