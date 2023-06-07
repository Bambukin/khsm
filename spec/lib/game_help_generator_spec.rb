require 'rails_helper'

RSpec.describe GameHelpGenerator do
  describe ".friend_call" do
    before { allow(I18n.t('game_help.friends')).to receive(:sample).and_return('Default Friend') }
    let!(:keys) { %w[key1 key2 key3 key4] }
    let!(:correct_key) { 'key1' }

    context 'when key is wrong' do
      it 'returns correct message' do
        allow(GameHelpGenerator).to receive(:random_of_hundred).and_return(90)

        result = GameHelpGenerator.friend_call(keys, correct_key)
        expect(result).to match(/\ADefault Friend считает, что это вариант KEY[2-4]\z/)
      end
    end

    context 'when key is correct' do
      it 'returns correct message' do
        allow(GameHelpGenerator).to receive(:random_of_hundred).and_return(70)

        result = GameHelpGenerator.friend_call(keys, correct_key)
        expect(result).to eq('Default Friend считает, что это вариант KEY1')
      end
    end
  end
end
