require_relative 'acceptance_helper'

describe 'should open page' do
  context 'the / URL' do
    it "see logo" do
      visit '/'
      page.has_content?('Deployerb')
    end
  end
end
