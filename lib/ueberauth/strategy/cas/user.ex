defmodule Ueberauth.Strategy.CAS.User do
  @moduledoc """
  Representation of a CAS user with their roles.
  """

  defstruct  user: nil, uid: nil
  
  alias Ueberauth.Strategy.CAS.User

  def from_xml(body) do
    %User{}
    |> set_user(body)
    |> set_uid(body)
  end

  defp set_user(user, body), do: %User{user | user: get_attrib(body, :user)}
  defp set_uid(user, body), do: %User{user | uid: get_attrib(body, :uid)}
  
  defp get_attrib(body, key) do
    case Floki.find(body, "cas:#{key}")
    |> List.first
    |> Tuple.to_list
    |> List.last
    |> List.first do
      nil -> ""
      value -> value |> URI.decode
    end
  end
end
