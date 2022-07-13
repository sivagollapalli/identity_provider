class SamlController < ApplicationController
    include SamlIdp::Controller

    before_action :validate_saml_request, only: [:auth]

    def metadata
        render xml: SamlIdp.metadata.signed
    end

    def auth
        user = User.find_by_email(params[:email])

        if user
            @saml_response = encode_response(user)
        else
            return head(:bad_request)
        end
    end
end
