defmodule Ueberauth.Strategy.CAS.API do
  @moduledoc """
  CAS server API implementation.
  """
  use Bitwise
  use Ueberauth.Strategy
  alias Ueberauth.Strategy.CAS
  
  @doc "Returns the URL to this CAS server's login page."
  def login_url(is_inner) do
    settings(:base_url,is_inner) <> "/login"
  end

  @doc "Returns the URL to this CAS server's logout page."
  def logout_url(is_inner) do
    settings(:base_url,is_inner) <> "/logout"
  end

  def inner_client?(conn) do
    client_ip = get_client_ip(conn)
    inner_nets = Application.get_env(:ueberauth, Ueberauth)[:providers][:inner_net]
    Enum.any?(inner_nets, fn(net) -> range?(client_ip, net) end )
  end

  defp get_client_ip(conn) do
    header_map = Map.new(conn.req_headers)
    if Map.has_key?(header_map, "x-real-ip" ) do
      header_map["x-real-ip"] 
    else
      conn.remote_ip |> Tuple.to_list |> Enum.join( ".")
    end
  end  
  
  @doc "Validate a CAS Service Ticket with the CAS server."
  def validate_ticket(ticket, conn) do
    HTTPoison.get(validate_url, [], params: %{ticket: ticket, service: callback_url(conn)})
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

  defp validate_url do
    settings(:base_url,false) <> "/serviceValidate"
  end

  defp settings(key,is_inner) do
    inner_lable =  if is_inner, do: :inner_cas, else: :cas
    {_, settings} = Application.get_env(:ueberauth, Ueberauth)[:providers][inner_lable]
    settings[key]
  end

  defp ip2int(ipaddr) do
    {:ok,{ip1,ip2,ip3,ip4}} = ipaddr |> to_charlist |> :inet.parse_address
    (ip1 <<< 24) ||| (ip2 <<< 16) ||| (ip3 <<< 8) ||| ip4   
  end

  defp mask2int(mask) do
    mask =  if mask in (0..32), do: mask, else: 32
    (0xffffffff <<< (32-mask)) &&& 0xffffffff
  end
  
  defp parse_net(netstr) do
    case netstr |>  String.split("/") |> List.to_tuple do
      {ip, mask} ->
        {ip2int(ip),mask2int (mask)} 
     {ip} ->
        {ip2int(ip),mask2int (32)} 
    end
  end

  defp range?(ip,net) do
    {netaddr, mask} = parse_net(net)
    (ip2int(ip) &&& mask) == netaddr
  end
end
