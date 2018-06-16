defmodule BoltTest.Cogs.Clean do
  use ExUnit.Case, async: true

  @spec make_message(boolean() | nil) :: User.t()
  defp make_message(is_bot) do
    alias Nostrum.Struct.Message
    alias Nostrum.Struct.User

    %Message{
      activity: nil,
      application: nil,
      attachments: [],
      author: %User{
        avatar: nil,
        bot: is_bot,
        discriminator: "0000",
        email: nil,
        id: 1_010_101_010,
        mfa_enabled: nil,
        username: "test user",
        verified: nil
      },
      channel_id: 1234,
      content: "I am a test message",
      edited_timestamp: nil,
      embeds: [],
      guild_id: nil,
      id: 4321,
      mention_everyone: false,
      mention_roles: [],
      mentions: [],
      nonce: nil,
      pinned: false,
      reactions: [],
      timestamp: "definitely a valid timestamp",
      tts: false,
      type: 0,
      webhook_id: nil
    }
  end

  describe "bot_filter/2" do
    alias Bolt.Cogs.Clean

    setup do
      %{nonbot_msg: make_message(false), nilbot_msg: make_message(nil), bot_msg: make_message(true)}
    end

    test "allows bots and humans without any explicit setting", fixture do
      assert Clean.bot_filter(fixture.nonbot_msg, []) == true
      assert Clean.bot_filter(fixture.nilbot_msg, []) == true
      assert Clean.bot_filter(fixture.bot_msg, []) == true
    end

    test "allows bots, rejects humans with `bots: true` setting", fixture do
      assert Clean.bot_filter(fixture.nonbot_msg, bots: true) == false
      assert Clean.bot_filter(fixture.nilbot_msg, bots: true) == false
      assert Clean.bot_filter(fixture.bot_msg, bots: true) == true
    end

    test "rejects bots, allows humans with `bots: false` setting", fixture do
      assert Clean.bot_filter(fixture.nonbot_msg, bots: false) == true
      assert Clean.bot_filter(fixture.nilbot_msg, bots: false) == true
      assert Clean.bot_filter(fixture.bot_msg, bots: false) == false
    end
  end
end
