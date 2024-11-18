require 'rails_helper'

RSpec.describe ContactValidator do
  describe '#valid?' do
    let(:valid_base_params) do
      {
        secret: 'ok',
        email: 'test@example.com',
        name: 'joe',
        context: '/',
        message: 'hello'
      }
    end
    context 'name validation' do
      valid_names = ['hola', 'Peter', 'Bruce Lee', 'PEter']
      invalid_names = [
        ['', 'empty'],
        ['skyreveryLiz', 'uppercase not first char'],
        ['FjqDTZHrLzJWQ ', 'internal uppercase'],
        ["HeyaMr...: ) the passive income it's 999eu a day C'mon -", 'too long']
      ]

      valid_names.each do |name|
        it "accepts valid name: #{name}" do
          params = valid_base_params.merge(name:)
          validator = ContactValidator.new(params, 'ok', '')

          expect(validator.valid?).to be true
          # expect(validator.error).not_to eq('bad name')
        end
      end

      invalid_names.each do |name, reason|
        it "rejects invalid name: #{name} (#{reason})" do
          params = valid_base_params.merge(name:)
          validator = ContactValidator.new(params, 'ok', '')
          expect(validator.valid?).to be false
          expect(validator.error).to eq('bad name')
        end
      end
    end

    context 'message validation' do
      valid_messages = ['please help me']
      invalid_messages = [
        ['', '', 'empty'],
        ['go to http://phising.com', 'http://', 'url w/ http']
      ]

      valid_messages.each do |message|
        it "accepts valid message: #{message}" do
          params = valid_base_params.merge(message:)

          validator = ContactValidator.new(params, 'ok', '')
          validator.valid?
          expect(validator.error).not_to eq('bad message')
        end
      end

      invalid_messages.each do |message, filter, reason|
        it "rejects invalid message: #{message} (#{reason})" do
          params = valid_base_params.merge(message:)
          validator = ContactValidator.new(params, 'ok', filter)
          validator.valid?
          expect(validator.error).to eq('bad message')
        end
      end
    end

    context 'complete contact validation' do
      it 'accepts valid contact' do
        validator = ContactValidator.new(valid_base_params, 'ok')
        expect(validator.valid?).to be true
        expect(validator.error).to be_nil
      end

      invalid_cases = [
        [{ name: 'aPPa' }, 'bad name'],
        [{ message: '' }, 'bad message'],
        [{ email: '' }, 'empty email'],
        [{ context: '' }, 'empty context'],
        [{ email: "e@ma.il\n" }, 'invalid email'],
        [{ message: 'http://spam.com', filter: 'http://' }, 'bad message'],
        [{ subject: 'oops' }, 'subject honeypot']
      ]

      invalid_cases.each do |modifications, expected_error|
        it "rejects invalid contact with #{expected_error}" do
          params = valid_base_params.merge(modifications)
          validator = ContactValidator.new(params, 'ok', modifications[:filter])

          expect(validator.valid?).to be false
          expect(validator.error).to eq(expected_error)
        end
      end
    end

    context 'secret validation' do
      it 'accepts matching secret' do
        params = { name: 'Papa',
                   email: 'e@ma.il',
                   context: '/',
                   message: 'hi there',
                   secret: 'secret123' }
        validator = ContactValidator.new(params, 'secret123', '')

        expect(validator.valid?).to be true
      end

      it 'rejects non-matching secret' do
        params = { name: 'Papa',
                   email: 'e@ma.il',
                   context: '/',
                   message: 'hi there',
                   secret: 'wrong secret' }
        validator = ContactValidator.new(params, 'secret123', '')

        expect(validator.valid?).to be false
        expect(validator.error).to eq('bad secret')
      end
    end
  end
end
