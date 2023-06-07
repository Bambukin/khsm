require 'rails_helper'

RSpec.describe 'users/show', type: :view do
  let!(:u) { create(:user, name: 'Жора') }
  before do
    assign(:user, u)
    assign(:games, [build_stubbed(:game)])
    stub_template 'users/_game.html.erb' => 'User games goes here'
  end

  context 'when user signed in' do
    context 'and he is not owner account' do
      let!(:not_owner) { create(:user, name: 'Вадим') }
      before { sign_in not_owner }
      before { render }

      it 'renders player names' do
        expect(rendered).to match 'Жора'
      end

      it 'does not renders link to edit account' do
        expect(rendered).not_to match 'Сменить имя и пароль'
      end

      it 'renders game' do
        expect(rendered).to have_content 'User games goes here'
      end

    end

    context 'and he is owner account' do
      before { sign_in u }
      before { render }
      it 'renders player names' do
        expect(rendered).to match 'Жора'
      end

      it 'renders link to edit account' do
        expect(rendered).to match 'Сменить имя и пароль'
      end

      it 'renders game' do
        expect(rendered).to have_content 'User games goes here'
      end
    end
  end

  context 'when user did not sign in' do
    before { render }

    it 'renders player names' do
      expect(rendered).to match 'Жора'
    end

    it 'does not renders link to edit account' do
      expect(rendered).not_to match 'Сменить имя и пароль'
    end

    it 'render game' do
      expect(rendered).to have_content 'User games goes here'
    end
  end
end
