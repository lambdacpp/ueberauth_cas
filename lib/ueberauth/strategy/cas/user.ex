defmodule Ueberauth.Strategy.CAS.User do
  @moduledoc """
  Representation of a CAS user with their roles.
  """

  defstruct  name: nil, teaching_number: nil, jwgh: nil, department: nil, usertype: nil, national: nil, role: nil, alias: nil, genders: nil, post: nil, cardid: nil, phone: nil

  alias Ueberauth.Strategy.CAS.User

  def from_xml(body) do
    %User{}
    |> set_name(body)
    |> set_teaching_number(body)
    |> set_jwgh(body)
    |> set_department(body)
    |> set_usertype(body)
    |> set_national(body)
    |> set_role(body)
    |> set_alias(body)
    |> set_genders(body)
    |> set_post(body)
    |> set_cardid(body)
    |> set_phone(body)
  end

  defp set_name(user, body), do: %User{user | name: comsys_attrib(body, :name)}
  defp set_teaching_number(user, body), do: %User{user | teaching_number: comsys_attrib(body, :teaching_number)}
  defp set_jwgh(user, body), do: %User{user | jwgh: comsys_attrib(body, :jwgh)}
  defp set_department(user, body), do: %User{user | department: comsys_attrib(body, :department)}
  defp set_usertype(user, body), do: %User{user | usertype: comsys_attrib(body, :usertype)} 
  defp set_national(user, body), do: %User{user | national: comsys_attrib(body, :national)}
  defp set_role(user, body), do: %User{user | role: comsys_attrib(body, :role)}
  defp set_alias(user, body), do: %User{user | alias: comsys_attrib(body, :alias)}
  defp set_genders(user, body), do: %User{user | genders: comsys_attrib(body, :genders)}
  defp set_post(user, body), do: %User{user | post: comsys_attrib(body, :post)}
  defp set_cardid(user, body), do: %User{user | cardid: comsys_attrib(body, :cardid)}
  defp set_phone(user, body)  , do: %User{user | phone: comsys_attrib(body, :phone)}
  
  defp comsys_attrib(body, key) do
    case Floki.find(body, "cas:comsys_#{key}")
    |> List.first
    |> Tuple.to_list
    |> List.last
    |> List.first do
      nil -> ""
      value -> value |> URI.decode
    end
  end
end
