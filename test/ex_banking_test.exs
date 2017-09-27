defmodule ExBankingTest do
  use ExUnit.Case

  @user_name "MAN-X"
  @user_name_2 "MAN-Y"
  @currency_1 "USD"
  @currency_2 "EUR"

  setup do
    Application.stop(:ex_banking)
    Application.start(:ex_banking)
    %{}
  end

  describe "ExBanking.create_user/1" do
    test "creates new user" do
      assert :ok == ExBanking.create_user(@user_name)
    end
    test "returns :user_already_exists error if user exists" do
      assert :ok == ExBanking.create_user(@user_name)
      assert {:error, :user_already_exists} == ExBanking.create_user(@user_name)
    end
  end

  describe "ExBanking.deposit/3" do
    test "increments user currency balance" do
      assert :ok == ExBanking.create_user(@user_name)
      assert {:ok, 100.99} == ExBanking.deposit(@user_name, 100.99, @currency_1)
      assert {:ok, 111.01} == ExBanking.deposit(@user_name, 10.02, @currency_1)
      assert {:ok, 111.01} == ExBanking.get_balance(@user_name, @currency_1)
    end
    test "returns {:error, :user_does_not_exist} when user does not exist" do
      assert {:error, :user_does_not_exist} == ExBanking.deposit(@user_name, 1_000.99, @currency_1)
    end
  end

  describe "ExBanking.withdraw/3" do
    test "decrements user currency balance" do
      assert :ok == ExBanking.create_user(@user_name)
      assert {:ok, 100.00} == ExBanking.deposit(@user_name, 100.00, @currency_1)
      assert {:ok, 49.45} == ExBanking.withdraw(@user_name, 50.55, @currency_1)
    end
    test "returns {:error, :not_enough_money} when user have not enough money" do
      assert :ok == ExBanking.create_user(@user_name)
      assert {:ok, 100.00} == ExBanking.deposit(@user_name, 100.00, @currency_1)
      assert {:error, :not_enough_money} == ExBanking.withdraw(@user_name, 100.01, @currency_1)
    end
    test "returns {:error, :user_does_not_exist} when user does not exist" do
      assert {:error, :user_does_not_exist} == ExBanking.withdraw(@user_name, 1_000.99, @currency_1)
    end
  end

  describe "ExBanking.get_balance/2" do
    test "default balance is 0" do
      assert :ok == ExBanking.create_user(@user_name)
      assert {:ok, 0} == ExBanking.get_balance(@user_name, @currency_1)
      assert {:ok, 0} == ExBanking.get_balance(@user_name, @currency_2)
    end
    test "returns {:error, :user_does_not_exist} when user does not exist" do
      assert {:error, :user_does_not_exist} == ExBanking.get_balance(@user_name, @currency_1)
    end
  end

  describe "ExBanking.send/4" do
    test "sends money from one user to another" do
      assert :ok == ExBanking.create_user(@user_name)
      assert :ok == ExBanking.create_user(@user_name_2)

      assert {:ok, 100.00} == ExBanking.deposit(@user_name, 100.00, @currency_1)
      assert {:ok, 49.45, 50.55} == ExBanking.send(@user_name, @user_name_2, 50.55, @currency_1)

      assert {:ok, 49.45} == ExBanking.get_balance(@user_name, @currency_1)
      assert {:ok, 50.55} == ExBanking.get_balance(@user_name_2, @currency_1)
    end
  end
end
