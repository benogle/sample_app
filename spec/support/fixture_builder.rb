FixtureBuilder.configure do |fbuilder|
  fbuilder.files_to_check += Dir['spec/factories/*.rb', 'spec/factories.rb', 'spec/support/fixture_builder.rb']

  fbuilder.factory do
    a = fbuilder.name(:admin, FactoryGirl.create(:admin))[0]
    u = fbuilder.name(:user, FactoryGirl.create(:user))[0]

    fbuilder.name(:post, FactoryGirl.create(:micropost, :user => u))
  end
end

# Have factory girl generate non-colliding sequences starting at 1000 for data created after the fixtures
FactoryGirl.sequences.each do |name, seq|
  seq.instance_variable_set(:@value, 1000)
end
