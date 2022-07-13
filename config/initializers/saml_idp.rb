SamlIdp.configure do |config|
    base = "http://localhost:3000"
  
    cert = File.read("#{Rails.root}/cert.pem")
    config.x509_certificate = cert
    config.secret_key = File.read("#{Rails.root}/private-key.pem")
    config.algorithm = :sha256                                    # Default: sha1 only for development.
    config.organization_name = "WAL"
    config.organization_url = base
    config.base_saml_location = "#{base}/saml"
    config.reference_id_generator                                 # Default: -> { SecureRandom.uuid }
    config.single_logout_service_post_location = "#{base}/saml/logout"
    config.single_logout_service_redirect_location = "#{base}/saml/logout"
    config.attribute_service_location = "#{base}/saml/attributes"
    config.single_service_post_location = "#{base}/saml/auth"
    config.session_expiry = 86400                                 # Default: 0 which means never
  
    config.name_id.formats =
      {                         
        email_address: -> (principal) { principal.email },
        transient: -> (principal) { principal.id },
        persistent: -> (p) { p.id },
      }
    service_providers = {
      "http://localhost:4000" => {
        fingerprint: "16:80:dc:0d:23:ef:a6:91:21:5e:ec:fc:fe:43:d7:80:b1:cf:7a:63:35:ba:42:c1:c5:f0:3b:2f:b8:07:a6:4c",
        metadata_url: "http://localhost:3000/saml/metadata",
        cert: Base64.encode64(cert),
  
        # We now validate AssertionConsumerServiceURL will match the MetadataURL set above.
        # *If* it's not going to match your Metadata URL's Host, then set this so we can validate the host using this list
        response_hosts: ["localhost:4000"]
      },
    }
  
    # `identifier` is the entity_id or issuer of the Service Provider,
    # settings is an IncomingMetadata object which has a to_h method that needs to be persisted
    config.service_provider.metadata_persister = ->(identifier, settings) {
      fname = identifier.to_s.gsub(/\/|:/,"_")
      FileUtils.mkdir_p(Rails.root.join('cache', 'saml', 'metadata').to_s)
      File.open Rails.root.join("cache/saml/metadata/#{fname}"), "r+b" do |f|
        Marshal.dump settings.to_h, f
      end
    }
  
    # `identifier` is the entity_id or issuer of the Service Provider,
    # `service_provider` is a ServiceProvider object. Based on the `identifier` or the
    # `service_provider` you should return the settings.to_h from above
    config.service_provider.persisted_metadata_getter = ->(identifier, service_provider){
      fname = identifier.to_s.gsub(/\/|:/,"_")
      FileUtils.mkdir_p(Rails.root.join('cache', 'saml', 'metadata').to_s)
      full_filename = Rails.root.join("cache/saml/metadata/#{fname}")
      if File.file?(full_filename)
        File.open full_filename, "rb" do |f|
          Marshal.load f
        end
      end
    }
  
    # Find ServiceProvider metadata_url and fingerprint based on our settings
    config.service_provider.finder = ->(issuer_or_entity_id) do
      service_providers[issuer_or_entity_id]
    end
  end
