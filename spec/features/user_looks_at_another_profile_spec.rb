require 'rails_helper'

RSpec.feature 'USER looks at another profile', type: :feature do
  let!(:user) { create :user }
  let!(:another_user) { create :user }
  let!(:another_users_game) { create :game, user: another_user }

  before(:each) do
    login_as user
  end

  scenario 'successfully' do
    visit '/'

    click_link another_user.name

    expect(page).to have_current_path '/users/2'

    expect(page).not_to have_content 'Сменить имя и пароль'

    expect(page).to have_content another_user.name

    expect(page).to have_content 'Дата'
    expect(page).to have_content 'Вопрос'
    expect(page).to have_content 'Выигрыш'
    expect(page).to have_content 'Подсказки'
  end
end
