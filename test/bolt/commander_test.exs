defmodule BoltTest.Commander do
  use ExUnit.Case, async: true

  describe "Commander.try_split/1" do
    alias Bolt.Commander

    test "returns space-separated words without quotes" do
      assert Commander.try_split("good test") == ["good", "test"]
      assert Commander.try_split("hello") == ["hello"]
      assert Commander.try_split("hello there test") == ["hello", "there", "test"]
    end

    test "regards space-surrounded arguments as single words" do
      assert Commander.try_split("\"good test\"") == ["good test"]
      assert Commander.try_split("hello \"to this test\"") == ["hello", "to this test"]
    end

    test "defaults to `String.split/1` with unclosed quotes" do
      assert Commander.try_split("\"hello world") == ["\"hello", "world"]
      assert Commander.try_split("hello world\"") == ["hello", "world\""]
    end
  end

  describe "Commander.find_failing_predicate/2" do
    alias Bolt.Commander

    setup do
      alias Nostrum.Struct.Message
      alias Nostrum.Struct.User

      message = %Message{
        activity: nil,
        application: nil,
        attachments: [],
        author: %User{
          avatar: nil,
          bot: nil,
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

      %{
        message: message,
        always_pass: fn msg -> {:ok, msg} end,
        always_fail: fn msg -> {:error, "boom"} end
      }
    end

    test "finds no failing predicates with empty predicates", %{message: msg} do
      assert Commander.find_failing_predicate(msg, []) == nil
    end

    test "passes with 'always pass' predicate", %{always_pass: always_pass, message: msg} do
      assert Commander.find_failing_predicate(msg, [always_pass]) == nil
    end

    test "fails with 'always fail' predicate", %{always_fail: always_fail, message: msg} do
      assert Commander.find_failing_predicate(msg, [always_fail]) == {:error, "boom"}
    end

    test "passes with multiple 'always pass' predicates", %{
      always_pass: always_pass,
      message: msg
    } do
      assert Commander.find_failing_predicate(msg, [
               always_pass,
               always_pass,
               always_pass,
               always_pass
             ]) == nil
    end

    test "fails with multiple 'always fail' predicates", %{always_fail: always_fail, message: msg} do
      assert Commander.find_failing_predicate(msg, [
               always_fail,
               always_fail,
               always_fail,
               always_fail
             ]) == {:error, "boom"}
    end

    test "fails with failing predicate among passing predicates", %{
      always_fail: always_fail,
      always_pass: always_pass,
      message: msg
    } do
      assert Commander.find_failing_predicate(msg, [always_fail, always_pass]) == {:error, "boom"}
      assert Commander.find_failing_predicate(msg, [always_pass, always_fail]) == {:error, "boom"}

      assert Commander.find_failing_predicate(msg, [always_pass, always_fail, always_pass]) ==
               {:error, "boom"}
    end
  end
end
