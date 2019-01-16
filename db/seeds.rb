# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rails db:seed command (or created alongside the database with db:setup).
#
# Examples:
#
#   movies = Movie.create([{ name: 'Star Wars' }, { name: 'Lord of the Rings' }])
#   Character.create(name: 'Luke', movie: movies.first)

if (User.count==0)

    userAdmin = User.new
    userAdmin.username = 'admin'
    userAdmin.password_digest = BCrypt::Password.create(Digest::MD5.hexdigest('admin'))
    userAdmin.level = 999
    # userAdmin.regenerate_auth_token
    userAdmin.save

    userStd = User.new
    userStd.username = 'user'
    userStd.password_digest = BCrypt::Password.create(Digest::MD5.hexdigest('user'))
    userStd.level = 1
    userStd.save
    
end