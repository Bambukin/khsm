# (c) goodprogrammer.ru

require 'rails_helper'
require 'support/my_spec_helper' # наш собственный класс с вспомогательными методами

# Тестовый сценарий для игрового контроллера
# Самые важные здесь тесты:
#   1. на авторизацию (чтобы к чужим юзерам не утекли не их данные)
#   2. на четкое выполнение самых важных сценариев (требований) приложения
#   3. на передачу граничных/неправильных данных в попытке сломать контроллер
#
RSpec.describe GamesController, type: :controller do
  # обычный пользователь
  let(:user) { create(:user) }
  # админ
  let(:admin) { create(:user, is_admin: true) }
  # игра с прописанными игровыми вопросами
  let(:game_w_questions) { create(:game_with_questions, user: user) }

  describe '#show' do
    context 'when user is not signed in' do
      before { get :show, id: game_w_questions.id }

      it 'redirects to login' do
        expect(response).to redirect_to(new_user_session_path)
      end

      it 'sets response status not 200' do
        expect(response.status).not_to eq(200)
      end

      it 'sets flash' do
        expect(flash[:alert]).to be
      end
    end

    context 'when user signed in' do
      before { sign_in user }

      context 'and user is the owner of the game' do
        before { get :show, id: game_w_questions.id }
        let!(:game) { assigns(:game) }

        it 'sets game not finished' do
          expect(game.finished?).to be false
        end

        it 'sets response status 200' do
          expect(response.status).to eq(200)
        end

        it 'renders show' do
          expect(response).to render_template('show')
        end

        it 'not set flash' do
          expect(flash.empty?).to be true
        end
      end

      context 'and user is not the owner of the game' do
        before { get :show, id: alien_game.id }
        let!(:alien_game) { create(:game_with_questions) }

        it 'redirects from show' do
          expect(response).to redirect_to(root_path)
        end

        it 'sets response status not 200' do
          expect(response.status).not_to eq(200)
        end

        it 'sets flash' do
          expect(flash[:alert]).to be
        end
      end
    end
  end

  describe '#create' do
    before { generate_questions(15) }

    context 'when user is not signed in' do
      before { post :create }
      subject(:create_game) { post :create }
      let!(:game) { assigns(:game) }

      it 'does not create new game' do
        expect { create_game }.to change(Game, :count).by(0)
      end

      it 'sets game nil' do
        expect(game).to be_nil
      end

      it 'redirects to login' do
        expect(response).to redirect_to(new_user_session_path)
      end

      it 'sets flash' do
        expect(flash[:alert]).to be
      end

      it 'sets response status not 200' do
        expect(response.status).not_to eq(200)
      end
    end

    context 'when user signed in' do
      before { sign_in user }

      context 'when user has not active game' do
        before { post :create }
        let!(:game) { assigns(:game) }

        it 'sets status not finished' do
          expect(game.finished?).to be false
        end

        it 'redirects to game' do
          expect(response).to redirect_to(game_path(game))
        end

        it 'sets flash' do
          expect(flash[:notice]).to be
        end
      end

      context 'when user has active game' do
        before { game_w_questions }
        before { post :create }
        subject(:create_game) { post :create }
        let!(:game) { assigns(:game) }

        it 'checks that old game did not finish' do
          expect(game_w_questions.finished?).to be false
        end

        it 'does not create new game' do
          expect { create_game }.to change(Game, :count).by(0)
        end

        it 'sets game nil' do
          expect(game).to be_nil
        end

        it 'redirects to old game' do
          expect(response).to redirect_to(game_path(game_w_questions))
        end

        it 'sets flash' do
          expect(flash[:alert]).to be
        end
      end
    end
  end

  describe '#answer' do
    context 'when user is not signed in' do
      before { put :answer, id: game_w_questions.id, letter: game_w_questions.current_game_question.correct_answer_key }

      let!(:game) { assigns(:game) }

      it 'sets game nil' do
        expect(game).to be_nil
      end

      it 'redirects to login' do
        expect(response).to redirect_to(new_user_session_path)
      end

      it 'sets flash' do
        expect(flash[:alert]).to be
      end

      it 'sets response status not 200' do
        expect(response.status).not_to eq(200)
      end
    end

    context 'when user signed in' do
      before { sign_in user }

      context 'and answer is correct' do
        before { put :answer, id: game_w_questions.id, letter: game_w_questions.current_game_question.correct_answer_key }

        let!(:game) { assigns(:game) }

        it 'does not finish game' do
          expect(game.finished?).to be false
        end

        it 'sets next level' do
          expect(game.current_level).to eq(1)
        end

        it 'redirects to game' do
          expect(response).to redirect_to(game_path(game))
        end

        it 'does not set flash' do
          expect(flash.empty?).to be true
        end
      end

      context 'and answer is wrong' do
        let!(:game_w_questions) { create(:game_with_questions, user: user, current_level: Game::FIREPROOF_LEVELS[0] + 1) }
        before do
          put :answer,
              id: game_w_questions.id,
              letter: %w[a b c d].grep_v(game_w_questions.current_game_question.correct_answer_key).sample
        end

        let!(:game) { assigns(:game) }

        it 'finishes game' do
          expect(game.finished?).to be true
        end

        it 'redirects to user' do
          expect(response).to redirect_to(user_path(user))
        end

        it 'sets flash' do
          expect(flash[:alert]).to be
        end

        it 'sets prize' do
          expect(game.prize).to eq(Game::PRIZES[Game::FIREPROOF_LEVELS[0]])
        end

        it 'updates user balance' do
          user.reload
          expect(user.balance).to eq(Game::PRIZES[Game::FIREPROOF_LEVELS[0]])
        end
      end
    end
  end

  describe '#help' do
    context 'when user is not signed in' do
      context 'and use audience help' do
        before { put :help, id: game_w_questions.id, help_type: :audience_help }

        let!(:game) { assigns(:game) }

        it 'sets game nil' do
          expect(game).to be_nil
        end

        it 'redirects to login' do
          expect(response).to redirect_to(new_user_session_path)
        end

        it 'sets flash' do
          expect(flash[:alert]).to be
        end

        it 'sets response status not 200' do
          expect(response.status).not_to eq(200)
        end
      end
    end

    context 'when user signed in' do
      before { sign_in user }

      context 'and use audience help' do
        before { put :help, id: game_w_questions.id, help_type: :audience_help }

        let!(:game) { assigns(:game) }

        it 'does not finish game' do
          expect(game.finished?).to be false
        end

        it 'toggles audience_help_used' do
          expect(game.audience_help_used).to be true
        end

        it 'adds audience_help to help_hash' do
          expect(game.current_game_question.help_hash[:audience_help]).to be
        end

        it 'redirects to game' do
          expect(response).to redirect_to(game_path(game))
        end

        it 'returns all keys' do
          expect(game.current_game_question.help_hash[:audience_help].keys).to contain_exactly('a', 'b', 'c', 'd')
        end

        it 'sets flash' do
          expect(flash[:info]).to be
        end
      end
    end
  end

  describe '#take_money' do
    context 'when user is not signed in' do
      before { game_w_questions.update_attribute(:current_level, 2) }
      before { put :take_money, id: game_w_questions.id }

      let!(:game) { assigns(:game) }

      it 'sets game nil' do
        expect(game).to be_nil
      end

      it 'redirects to login' do
        expect(response).to redirect_to(new_user_session_path)
      end

      it 'sets flash' do
        expect(flash[:alert]).to be
      end

      it 'sets response status not 200' do
        expect(response.status).not_to eq(200)
      end
    end

    context 'when user signed in' do
      before { sign_in user }
      before { game_w_questions.update_attribute(:current_level, 2) }
      before { put :take_money, id: game_w_questions.id }

      let!(:game) { assigns(:game) }

      it 'sets flash' do
        expect(flash[:warning]).to be
      end

      it 'redirects to user' do
        expect(response).to redirect_to(user_path(user))
      end

      it 'finish game' do
        expect(game.finished?).to be true
      end

      it 'sets prize' do
        expect(game.prize).to eq(Game::PRIZES[1])
      end

      it 'updates user balance' do
        user.reload
        expect(user.balance).to eq(Game::PRIZES[1])
      end
    end
  end
end
