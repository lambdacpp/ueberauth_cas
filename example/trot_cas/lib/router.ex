defmodule TrotCas.Router do
  alias Ueberauth.Strategy.CAS
  use Trot.Router

  get "/" do
    result = conn |> CAS.add_conn_params! |> CAS.handle_callback!
    
    if Map.has_key?(result.assigns, :ueberauth_failure) do
      case result |> CAS.error_key do
        "missing_ticket" ->
          conn |> CAS.handle_request!
        _ ->
          "Fail login"
      end
    else
        "#{result.private.cas_user.name} #{result.private.cas_user.teaching_number} #{result.private.cas_user.jwgh} #{result.private.cas_user.department} #{result.private.cas_user.usertype} #{result.private.cas_user.national} #{result.private.cas_user.role} #{result.private.cas_user.alias} #{result.private.cas_user.genders} #{result.private.cas_user.post} #{result.private.cas_user.cardid} #{result.private.cas_user.phone}"
    end
  end

  import_routes Trot.NotFound
end

