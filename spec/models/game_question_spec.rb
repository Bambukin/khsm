# (c) goodprogrammer.ru

require 'rails_helper'

# Тестовый сценарий для модели игрового вопроса,
# в идеале весь наш функционал (все методы) должны быть протестированы.
RSpec.describe GameQuestion, type: :model do

  # задаем локальную переменную game_question, доступную во всех тестах этого сценария
  # она будет создана на фабрике заново для каждого блока it, где она вызывается
  let(:game_question) { create(:game_question, a: 2, b: 1, c: 4, d: 3) }

  # группа тестов на игровое состояние объекта вопроса
  # тест на правильную генерацию хэша с вариантами
  describe '#variants' do
    it 'returns the correct variants' do
      expect(game_question.variants).to eq({ 'a' => game_question.question.answer2,
                                             'b' => game_question.question.answer1,
                                             'c' => game_question.question.answer4,
                                             'd' => game_question.question.answer3 })
    end
  end

  describe '#answer_correct?' do
    it 'correct .answer_correct?' do
      # именно под буквой b в тесте мы спрятали указатель на верный ответ
      expect(game_question.answer_correct?('b')).to be true
    end
  end

  # help_hash у нас имеет такой формат:
  # {
  #   fifty_fifty: ['a', 'b'], # При использовании подсказски остались варианты a и b
  #   audience_help: {'a' => 42, 'c' => 37 ...}, # Распределение голосов по вариантам a, b, c, d
  #   friend_call: 'Василий Петрович считает, что правильный ответ A'
  # }
  #

  describe '#add_audience_help' do
    context 'when help is not used' do
      it 'does not add audience_help in help_hash' do
        expect(game_question.help_hash).not_to include(:audience_help)
      end

      it 'does not add fifty_fifty in help_hash' do
        expect(game_question.help_hash).not_to include(:fifty_fifty)
      end

      it 'does not add friend_call in help_hash' do
        expect(game_question.help_hash).not_to include(:friend_call)
      end
    end

    context 'when add_audience_help is used' do
      before(:each) { game_question.add_audience_help }

      it 'adds audience_help in help_hash' do
        expect(game_question.help_hash).to include(:audience_help)
      end

      it 'returns all keys' do
        ah = game_question.help_hash[:audience_help]
        expect(ah.keys).to contain_exactly('a', 'b', 'c', 'd')
      end
    end

    context 'when fifty_fifty is used' do
      before(:each) { game_question.add_fifty_fifty }
      let!(:ff) { game_question.help_hash[:fifty_fifty] }

      it 'adds fifty_fifty in help_hash' do
        expect(game_question.help_hash).to include(:fifty_fifty)
      end

      it 'returns array with 2 elements' do
        expect(ff.size).to eq(2)
      end

      it 'includes correct_answer_key' do
        expect(ff).to include(game_question.correct_answer_key)
      end
    end

    context 'when friend_call is used' do
      before(:each) { game_question.add_friend_call }
      let!(:fc) { game_question.help_hash[:friend_call] }

      it 'adds friend_call in help_hash' do
        expect(game_question.help_hash).to include(:friend_call)
      end

      it 'returns string' do
        expect(fc).to be_instance_of(String)
      end
    end
  end

  describe '#text' do
    it 'delegates to question' do
      expect(game_question.text).to eq(game_question.question.text)
    end
  end

  describe '#level' do
    it 'delegates to question' do
      expect(game_question.level).to eq(game_question.question.level)
    end
  end

  describe '#correct_answer_key' do
    it 'returns first answer from db' do
      expect(game_question.variants[game_question.correct_answer_key]).to eq(game_question.question.answer1)
    end
  end

  describe '#correct_answer' do
    it 'returns correct answer' do
      expect(game_question.correct_answer).to eq(game_question.question.answer1)
    end
  end

  describe '#help_hash' do
    context 'when help_hash did not use' do
      it 'sets help_hash empty' do
        expect(game_question.help_hash).to eq({})
      end
    end

    context 'when help_hash used' do
      before { game_question.help_hash[:test_key] = 'test value' }

      it 'saves model' do
        expect(game_question.save).to be true
      end

      it 'adds key to hash' do
        game_question.save
        gq = GameQuestion.find(game_question.id)
        expect(gq.help_hash).to have_key(:test_key)
      end

      it 'adds value to hash' do
        game_question.save
        gq = GameQuestion.find(game_question.id)
        expect(gq.help_hash[:test_key]).to eq('test value')
      end
    end
  end
end
