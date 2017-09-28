defmodule ExBankingTest do
  use ExUnit.Case

  import Mock

  @user_name "Rick"
  @user_name_2 "Morty"
  @currency "CURR"

  # Testing like black-box

  setup do
    Application.stop(:ex_banking)
    Application.start(:ex_banking)
    :ok
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

    test "returns :wrong_arguments error when user name is not string" do
      assert {:error, :wrong_arguments} == ExBanking.create_user(@user_name |> String.to_atom)
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

    test "returns :wrong_arguments error when user/amount/currency has invalid type" do
      assert {:error, :wrong_arguments} == ExBanking.deposit(@user_name |> String.to_atom, 100, @currency)
      assert {:error, :wrong_arguments} == ExBanking.deposit(@user_name, "100", @currency)
      assert {:error, :wrong_arguments} == ExBanking.deposit(@user_name, "100", @currency |> String.to_atom)
    end

    test "returns :wrong_arguments error when amount is equal or less than zero" do
      assert {:error, :wrong_arguments} == ExBanking.deposit(@user_name, 0, @currency)
      assert {:error, :wrong_arguments} == ExBanking.deposit(@user_name, -0.01, @currency)
    end

    @tag users: [{@user_name, 100, @currency}]
    test "returns :too_many_requests_to_user error if user has too many requests", %{pids: [pid]} do
      with_mock(ExBanking.Lib.RequestsLimit, [limit_reached?: fn(^pid) -> true end]) do
        assert {:error, :too_many_requests_to_user} == ExBanking.deposit(@user_name, 100, @currency)
      end
      with_mock(ExBanking.Lib.RequestsLimit, [limit_reached?: fn(^pid) -> false end]) do
        assert {:ok, _} = ExBanking.deposit(@user_name, 100, @currency)
      end
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

    test "returns :wrong_arguments error when user/amount/currency has invalid type" do
      assert {:error, :wrong_arguments} == ExBanking.withdraw(@user_name |> String.to_atom, 100, @currency)
      assert {:error, :wrong_arguments} == ExBanking.withdraw(@user_name, "100", @currency)
      assert {:error, :wrong_arguments} == ExBanking.withdraw(@user_name, "100", @currency |> String.to_atom)
    end

    test "returns :wrong_arguments error when amount is equal or less than zero" do
      assert {:error, :wrong_arguments} == ExBanking.withdraw(@user_name, 0, @currency)
      assert {:error, :wrong_arguments} == ExBanking.withdraw(@user_name, -0.01, @currency)
    end

    @tag users: [{@user_name, 100, @currency}]
    test "returns :too_many_requests_to_user error if user has too many requests", %{pids: [pid]} do
      with_mock(ExBanking.Lib.RequestsLimit, [limit_reached?: fn(^pid) -> true end]) do
        assert {:error, :too_many_requests_to_user} == ExBanking.withdraw(@user_name, 100, @currency)
      end
      with_mock(ExBanking.Lib.RequestsLimit, [limit_reached?: fn(^pid) -> false end]) do
        assert {:ok, _} = ExBanking.withdraw(@user_name, 100, @currency)
      end
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

    test "returns :wrong_arguments error when user/currency has invalid type" do
      assert {:error, :wrong_arguments} == ExBanking.get_balance(@user_name |> String.to_atom, @currency)
      assert {:error, :wrong_arguments} == ExBanking.get_balance(@user_name, @currency |> String.to_atom)
    end

    @tag users: [{@user_name, 100, @currency}]
    test "returns :too_many_requests_to_user error if user has too many requests", %{pids: [pid]} do
      with_mock(ExBanking.Lib.RequestsLimit, [limit_reached?: fn(^pid) -> true end]) do
        assert {:error, :too_many_requests_to_user} == ExBanking.get_balance(@user_name, @currency)
      end
      with_mock(ExBanking.Lib.RequestsLimit, [limit_reached?: fn(^pid) -> false end]) do
        assert {:ok, _} = ExBanking.get_balance(@user_name, @currency)
      end
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

    test "returns :wrong_arguments when from_user/to_user/amount/currency has invalid type" do
      assert {:error, :wrong_arguments} ==
        ExBanking.send(@user_name |> String.to_atom, @user_name_2, 100.00, @currency)
      assert {:error, :wrong_arguments} ==
        ExBanking.send(@user_name, @user_name_2 |> String.to_atom, 100.00, @currency)
      assert {:error, :wrong_arguments} ==
        ExBanking.send(@user_name, @user_name_2, "100.00", @currency)
      assert {:error, :wrong_arguments} ==
        ExBanking.send(@user_name, @user_name_2, 100.00, @currency |> String.to_atom)
    end

    test "returns :wrong_arguments when amount is equal or less than zero" do
      assert {:error, :wrong_arguments} == ExBanking.send(@user_name, @user_name_2, 0.0, @currency)
      assert {:error, :wrong_arguments} == ExBanking.send(@user_name, @user_name_2, -0.01, @currency)
    end

    @tag users: [{@user_name, 100, @currency}, {@user_name_2, 10, @currency}]
    test "returns :too_many_requests_to_sender error if from_user has too many requests",
      %{pids: [from_user_pid, to_user_pid]}
    do
      with_mock(ExBanking.Lib.RequestsLimit, [
        limit_reached?: fn
          ^from_user_pid -> true
          ^to_user_pid -> false
        end
      ]) do
        assert {:error, :too_many_requests_to_sender} ==
          ExBanking.send(@user_name, @user_name_2, 10, @currency)
      end
      with_mock(ExBanking.Lib.RequestsLimit, [
        limit_reached?: fn
          ^from_user_pid -> false
          ^to_user_pid -> false
        end
      ]) do
        assert {:ok, _, _} = ExBanking.send(@user_name, @user_name_2, 10, @currency)
      end
    end

    @tag users: [{@user_name, 100, @currency}, {@user_name_2, 10, @currency}]
    test "returns :too_many_requests_to_receiver error if to_user has too many requests",
      %{pids: [from_user_pid, to_user_pid]}
    do
      with_mock(ExBanking.Lib.RequestsLimit, [
        limit_reached?: fn
          ^from_user_pid -> false
          ^to_user_pid -> true
        end
      ]) do
        assert {:error, :too_many_requests_to_receiver} ==
          ExBanking.send(@user_name, @user_name_2, 10, @currency)
      end
      with_mock(ExBanking.Lib.RequestsLimit, [
        limit_reached?: fn
          ^from_user_pid -> false
          ^to_user_pid -> false
        end
      ]) do
        assert {:ok, _, _} = ExBanking.send(@user_name, @user_name_2, 10, @currency)
      end
    end
  end

  defp setup_users(%{users: users}) do
    Enum.each(users, fn({user_name, balance, currency}) ->
      ExBanking.create_user(user_name)
      ExBanking.deposit(user_name, balance, currency)
    end)

    user_pids =
      Enum.map(users, fn({user_name, _, _}) ->
        [{pid, nil}] = Registry.lookup(ExBanking.Registry, user_name)
        pid
      end)

    {:ok, %{pids: user_pids}}
  end
  defp setup_users(_), do: :ok
end
