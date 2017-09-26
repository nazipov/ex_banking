defmodule ExBankingTest do
  use ExUnit.Case

  describe "ExBanking.create_user/1" do
    test "creates new user" do
      assert :ok == ExBanking.create_user("DEMO")
    end
    test "returns :user_already_exists error if user exists" do
      ExBanking.create_user("DEMO")
      assert {:error, :user_already_exists} == ExBanking.create_user("DEMO")
    end
  end
end
