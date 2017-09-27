defmodule ExBankingTest do
  use ExUnit.Case

  @user_name "Rick"
  @user_name_2 "Morty"
  @currency "CURR"

  setup do
    Application.stop(:ex_banking)
    Application.start(:ex_banking)
    %{}
  end

  setup [:setup_users]

  describe "ExBanking.create_user/1" do
    test "creates new user" do
      assert :ok == ExBanking.create_user(@user_name)
    end

    @tag users: [{@user_name, 100, @currency}]
    test "returns :user_already_exists error if user exists" do
      assert {:error, :user_already_exists} == ExBanking.create_user(@user_name)
    end
  end

  describe "ExBanking.deposit/3" do
    @tag users: [{@user_name, 100, @currency}]
    test "increments user currency balance and returns new balance" do
      assert {:ok, 200.99} == ExBanking.deposit(@user_name, 100.99, @currency)
      assert {:ok, 200.99} == ExBanking.get_balance(@user_name, @currency)
    end

    test "returns :user_does_not_exist error when user does not exist" do
      assert {:error, :user_does_not_exist} == ExBanking.deposit(@user_name, 100, @currency)
    end
  end

  describe "ExBanking.withdraw/3" do
    @tag users: [{@user_name, 100, @currency}]
    test "decrements user currency balance and return new balance" do
      assert {:ok, 49.45} == ExBanking.withdraw(@user_name, 50.55, @currency)
      assert {:ok, 49.45} == ExBanking.get_balance(@user_name, @currency)
    end

    @tag users: [{@user_name, 100, @currency}]
    test "returns :not_enough_money error when user have not enough money" do
      assert {:error, :not_enough_money} == ExBanking.withdraw(@user_name, 100.01, @currency)
    end

    test "returns :user_does_not_exist error when user does not exist" do
      assert {:error, :user_does_not_exist} == ExBanking.withdraw(@user_name, 100, @currency)
    end
  end

  describe "ExBanking.get_balance/2" do
    @tag users: [{@user_name, 100, @currency}]
    test "returns user balance" do
      assert {:ok, 100} == ExBanking.get_balance(@user_name, @currency)
    end

    test "returns :user_does_not_exist when user does not exist" do
      assert {:error, :user_does_not_exist} == ExBanking.get_balance(@user_name, @currency)
    end
  end

  describe "ExBanking.send/4" do
    @tag users: [{@user_name, 100, @currency}, {@user_name_2, 10, @currency}]
    test "sends money from one user to another and returns sender and receiver new balance" do
      assert {:ok, 49.45, 60.55} == ExBanking.send(@user_name, @user_name_2, 50.55, @currency)

      assert {:ok, 49.45} == ExBanking.get_balance(@user_name, @currency)
      assert {:ok, 60.55} == ExBanking.get_balance(@user_name_2, @currency)
    end

    @tag users: [{@user_name, 100, @currency}, {@user_name_2, 10, @currency}]
    test "returns :not_enough_money error when sender does not have enough money" do
      assert {:error, :not_enough_money} == ExBanking.send(@user_name, @user_name_2, 100.01, @currency)
      assert {:ok, 100} == ExBanking.get_balance(@user_name, @currency)
    end

    test "returns :sender_does_not_exist error when sender does not exist" do
      assert {:error, :sender_does_not_exist} == ExBanking.send(@user_name, @user_name_2, 100.00, @currency)
    end

    @tag users: [{@user_name, 100, @currency}]
    test "returns :receiver_does_not_exist error when receiver does not exist" do
      assert {:error, :receiver_does_not_exist} == ExBanking.send(@user_name, @user_name_2, 100.00, @currency)
      assert {:ok, 100} == ExBanking.get_balance(@user_name, @currency)
    end
  end

  defp setup_users(%{users: users}) do
    Enum.each(users, fn({user_name, balance, currency}) ->
      ExBanking.create_user(user_name)
      ExBanking.deposit(user_name, balance, currency)
    end)

    :ok
  end
  defp setup_users(_), do: :ok
end
