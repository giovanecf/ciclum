namespace :ciclum do
  desc "Remove expired visitor accounts and their study data"
  task purge_expired_guests: :environment do
    User.purge_expired_guests!
  end
end
