defmodule Ueberauth.Strategy.CAS.API do
  @moduledoc """
  CAS server API implementation.
  """

  use Ueberauth.Strategy
  alias Ueberauth.Strategy.CAS
  alias Ueberauth.Strategy.CAS.IPAddr
  
  @doc "Returns the URL to this CAS server's login page."
  def login_url(is_inner) do
    settings(:base_url,is_inner) <> "/login"
  end

  @doc "Returns the URL to this CAS server's logout page."
  def logout_url(is_inner) do
    settings(:logout_url,is_inner)
  end

  def inner_client?(conn) do
    client_ip = get_client_ip(conn)
    inner_nets =
      Application.get_env(:ueberauth, Ueberauth)[:providers][:inner_net]
      |> Enum.map(&(IPAddr.new(&1)))
    Enum.any?(inner_nets, fn(net) -> IPAddr.include?(net, client_ip) end )
  end

  defp get_client_ip(conn) do
    header_map = Map.new(conn.req_headers)
    if Map.has_key?(header_map, "x-real-ip" ) do
      {:ok, client_ip} = header_map["x-real-ip"] 
      client_ip
    else
      conn.remote_ip |> Tuple.to_list |> Enum.join( ".")
    end
  end  
  
  @doc "Validate a CAS Service Ticket with the CAS server."
  def validate_ticket(ticket, conn) do
    HTTPoison.get(validate_url(inner_client?(conn)), [], params: %{ticket: ticket, service: callback_url(conn)})
    |> handle_validate_ticket_response
  end

  defp handle_validate_ticket_response({:ok, %HTTPoison.Response{status_code: 200, body: body}}) do
    case String.match?(body, ~r/cas:authenticationFailure/) do
      true -> {:error, error_from_body(body)}
      _    -> {:ok, CAS.User.from_xml(body)}
    end
  end

  defp handle_validate_ticket_response({:error, %HTTPoison.Error{reason: reason}}) do
    {:error, reason}
  end

  defp error_from_body(body) do
    case Regex.named_captures(~r/code="(?<code>\w+)"/, body) do
      %{"code" => code} -> code
      _                 -> "UNKNOWN_ERROR"
    end
  end

  defp validate_url(is_inner) do
    settings(:base_url,is_inner) <> "/serviceValidate"
  end

  defp settings(key,is_inner) do
    inner_lable =  if is_inner, do: :inner_cas, else: :cas
    {_, settings} = Application.get_env(:ueberauth, Ueberauth)[:providers][inner_lable]
    settings[key]
  end
end
