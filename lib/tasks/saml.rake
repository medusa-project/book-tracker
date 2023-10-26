namespace :saml do

  desc "Generate a new public certificate"
  task :generate_sp_cert, [:environment] => :environment do |task, args|
    config_path = File.join(Rails.root, "config", "credentials", "#{args[:environment]}.yml.enc")
    key_path    = File.join(Rails.root, "config", "credentials", "#{args[:environment]}.key")
    config      = ActiveSupport::EncryptedConfiguration.new(config_path: config_path,
                                                            key_path:    key_path,
                                                            env_key:     "RAILS_MASTER_KEY",
                                                            raise_if_missing_key: true)
    config.read

    private_key = config.dig(:saml, :sp_private_key)
    if private_key.blank?
      raise "saml.sp_private_key is not set in the application configuration"
    end

    rel_dest_path = File.join("config", "certs", "sp-cert-#{args[:environment]}.pem")
    abs_dest_path = File.join(Rails.root, rel_dest_path)

    # N.B.: iTrust requires the CN to match the hostname
    cert = CryptUtils.generate_cert(key:          private_key,
                                    organization: "University of Illinois at Urbana-Champaign Library",
                                    common_name:  config.dig(:hostname),
                                    not_after:    Time.now + 20.years)

    File.write(abs_dest_path, cert.to_pem)
    puts "Done. Be sure to commit the new certificate to version control, "\
         "and update the application's iTrust record."
  end

end
