# (c) goodprogrammer.ru

require 'rails_helper'
require 'support/my_spec_helper' # наш собственный класс с вспомогательными методами

# Тестовый сценарий для модели Игры
# В идеале - все методы должны быть покрыты тестами,
# в этом классе содержится ключевая логика игры и значит работы сайта.
RSpec.describe Game, type: :model do
  # пользователь для создания игр
  let(:user) { create(:user) }

  # игра с прописанными игровыми вопросами
  let(:game_w_questions) { create(:game_with_questions, user: user) }

  # Группа тестов на работу фабрики создания новых игр
  describe '.create_game_for_user!' do
    before { generate_questions(60) }

    subject(:create_game) { Game.create_game_for_user!(user) }

    it 'increases game counter' do
      expect { create_game }.to change(Game, :count).by(1)
    end

    it 'increases game_question counter' do
      expect { create_game }.to change(GameQuestion, :count).by(15)
    end

    it 'does not increase question counter' do
      expect { create_game }.to change(Question, :count).by(0)
    end

    it 'sets correct user' do
      expect(create_game.user).to eq(user)
    end

    it 'starts game' do
      expect(create_game.status).to eq(:in_progress)
    end

    it 'sets right number of game_questions' do
      expect(create_game.game_questions.size).to eq(Question::QUESTION_LEVELS.size)
    end

    it 'sets each level of questions' do
      expect(create_game.game_questions.map(&:level)).to eq Question::QUESTION_LEVELS.to_a
    end
  end

  describe '#answer_current_question!' do
    before { game_w_questions.answer_current_question!(answer_key) }

    context 'when answer is correct' do
      let!(:level) { 0 }
      let!(:answer_key) { game_w_questions.current_game_question.correct_answer_key }

      context 'and question is last' do
        let!(:level) { Question::QUESTION_LEVELS.max }
        let!(:game_w_questions) { FactoryBot.create(:game_with_questions, user: user, current_level: level) }

        it 'assigns final prize' do
          expect(game_w_questions.prize).to eq(Game::PRIZES.max)
        end

        it 'finishes the game' do
          expect(game_w_questions.finished?).to be true
        end

        it 'finishes with status won' do
          expect(game_w_questions.status).to eq(:won)
        end

        it 'makes game not failed' do
          expect(game_w_questions.is_failed).to eq(false)
        end
      end

      context 'and question is not last' do
        it 'moves to next level' do
          expect(game_w_questions.current_level).to eq(level + 1)
        end

        it 'continues game' do
          expect(game_w_questions.finished?).to be false
        end

        it 'does not change status' do
          expect(game_w_questions.status).to eq(:in_progress)
        end
      end

      context 'and time is over' do
        let!(:game_w_questions) do
          FactoryBot.create(:game_with_questions,
                             user: user,
                             current_level: level,
                             created_at: Game::TIME_LIMIT.minutes.ago)
        end

        it 'finishes the game' do
          expect(game_w_questions.finished?).to be true
        end

        it 'finishes with status timeout' do
          expect(game_w_questions.status).to eq(:timeout)
        end
      end
    end

    context 'when answer is wrong' do
      let!(:answer_key) { %w[a b c d].grep_v(game_w_questions.current_game_question.correct_answer_key).sample }

      it 'finishes the game' do
        expect(game_w_questions.finished?).to be true
      end

      it 'finishes with status fail' do
        expect(game_w_questions.status).to eq(:fail)
      end
    end
  end

  describe '#take_money' do
    before { game_w_questions.take_money! }
    let!(:game_w_questions) { FactoryBot.create(:game_with_questions, user: user, current_level: 5) }

    it 'makes prize bigger then 0' do
      expect(game_w_questions.prize).to be > 0
    end

    it 'finishes the game' do
      expect(game_w_questions.finished?).to be true
    end

    it 'finishes with status money' do
      expect(game_w_questions.status).to eq(:money)
    end

    it 'increases the user balance' do
      expect(user.balance).to eq(game_w_questions.prize)
    end
  end

  describe '#status' do
    context 'when game not finished' do
      it 'returns in_progress' do
        expect(game_w_questions.status).to eq :in_progress
        expect(game_w_questions.finished_at).to be nil
      end
    end

    context 'when game is finished' do
      before(:each) do
        game_w_questions.finished_at = Time.now
        expect(game_w_questions.finished?).to be true
      end

      context 'and game is failed' do
        it 'returns fail' do
          game_w_questions.is_failed = true
          expect(game_w_questions.status).to eq(:fail)
        end
      end

      context 'and level bigger then max' do
        it 'returns won' do
          game_w_questions.current_level = Question::QUESTION_LEVELS.max + 1
          expect(game_w_questions.status).to eq(:won)
        end
      end

      context 'and time has passed' do
        it 'returns timeout' do
          game_w_questions.created_at = Game::TIME_LIMIT.minutes.ago
          game_w_questions.is_failed = true
          expect(game_w_questions.status).to eq(:timeout)
        end
      end

      context 'and user took money' do
        it 'returns money' do
          game_w_questions.take_money!
          expect(game_w_questions.status).to eq(:money)
        end
      end
    end
  end

  describe '#current_game_question' do
    before(:each) { game_w_questions.current_level = 5 }

    it 'returns instance of GameQuestion' do
      expect(game_w_questions.current_game_question).to be_instance_of(GameQuestion)
    end

    it 'sets current level' do
      expect(game_w_questions.current_game_question.level).to eq(5)
    end
  end

  describe '#previous_level' do
    it 'sets previous level' do
      game_w_questions.current_level = 5
      expect(game_w_questions.previous_level).to eq 4
    end
  end
end
