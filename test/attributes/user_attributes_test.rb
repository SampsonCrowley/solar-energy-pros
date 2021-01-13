require "test_helper"

class UserAttributesTest < ActiveSupport::TestCase
  def valid_attributes
    {
      first_names: "John Jacob",
      last_names: "Jingleheimer-Smith",
      data: {}
    }
  end

  def assert_single_use_digest(user, mthd = :password_reset)
    key_was = key = ""
    digest_was = nil

    10.times do
      key = user.__send__ mthd

      refute_nil user.single_use_digest
      assert user.authenticate_single_use(key)

      refute_equal key_was, key
      refute_equal digest_was, user.single_use_digest
      refute user.authenticate_single_use(key_was)

      key_was    = key
      digest_was = user.single_use_digest
    end

    [ key, user.single_use_digest ]
  end

  test "valid person" do
    user = User.new(valid_attributes)
    assert user.valid?

    # optional columns
    [
      :title,
      :middle_names,
      :suffix,
      :email,
      :password,
      :single_use,
      :single_use_expires_at,
    ].each do |attr|
      assert user.respond_to?(attr)
      assert user.respond_to?(:"#{attr}=")

      user.__send__ :"#{attr}=", "#{rand}.#{Time.zone.now}"

      if %i[ password email ].include? attr
        refute user.valid?
        user.email = "#{rand}@email.com"
      end


      assert user.valid?, "user #{attr} invalid (#{user.errors.full_messages.join(", ")})"

      user.__send__ :"#{attr}=", nil

      assert user.valid?

      if attr == :password
        user.email = nil
        assert user.valid?
      end
    end
  end

  test "invalid user with invalid email" do
    [
      ".asdf@email.com",
      "asdf.@email.com",
      ";asdf@email.com",
      "asdf;@email.com",
      "asdf;asdf@email.com",
      "asdf@;email.com",
      "asdf@email;com",
      "asdf@emailcom",
      "asdf@.emailcom",
    ].each do |bad|
      user = User.new(valid_attributes.merge(email: bad))
      refute user.valid?, "user is invalid when email is invalid"
      refute_nil user.errors[:email]
      assert_equal [ "is not a valid address" ], user.errors[:email]
    end
  end

  test "invalid user with invalid password_confirmation" do
    user = User.new(valid_attributes.merge(password: rand.to_s, password_confirmation: rand.to_s))
    refute user.valid?, "user is invalid when password_confirmation does not match"
    refute_nil user.errors[:password_confirmation]
    assert_equal [ "doesn't match Password" ], user.errors[:password_confirmation]
  end

  test "#password_reset generates a new single_use_digest and returns the associated key" do
    user = User.new valid_attributes

    assert user.save

    assert_nil user.single_use_digest

    key, digest = assert_single_use_digest user

    assert user.authenticate_single_use(key)
    assert_equal digest, user.single_use_digest

    user.reload

    refute user.authenticate_single_use(key)
    refute_equal digest, user.single_use_digest
  end

  test "#password_reset! generates a new single_use_digest saves the record, and returns the associated key" do
    user = User.new valid_attributes

    assert user.save

    assert_nil user.single_use_digest

    key, digest = assert_single_use_digest user, :password_reset!

    assert user.authenticate_single_use(key)
    assert_equal digest, user.single_use_digest

    user.reload

    assert user.authenticate_single_use(key)
    assert_equal digest, user.single_use_digest
  end
end
