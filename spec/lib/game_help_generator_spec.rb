require 'rails_helper'
require_relative '../../lib/game_help_generator'

RSpec.describe GameHelpGenerator do
  describe ".friend_call" do
    before { allow(I18n.t('game_help.friends')).to receive(:sample).and_return('Default Friend') }
    let!(:keys) { %w[key1 key3 key4] }
    let!(:correct_key) { 'key2' }

    context 'when key is wrong' do
      it 'returns correct message' do
        allow(keys).to receive(:sample).and_return('KEY3')
        allow(GameHelpGenerator).to receive(:rand).with(10).and_return(2)

        result = GameHelpGenerator.friend_call(keys, correct_key)
        expect(result).to eq('Default Friend считает, что это вариант KEY3')
      end
    end

    context 'when key is correct' do
      it 'returns correct message' do
        allow(GameHelpGenerator).to receive(:rand).with(10).and_return(3)

        result = GameHelpGenerator.friend_call(keys, correct_key)
        expect(result).to eq('Default Friend считает, что это вариант KEY2')
      end
    end
  end
end
