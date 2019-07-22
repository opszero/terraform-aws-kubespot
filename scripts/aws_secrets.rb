def secrets
  `aws secretsmanager get-secret-value --secret-id #{ENV["AWS_SECRETS"]} | jq -r '.SecretString'`.
    scan(/^(\w+)=(.+)/).each do |k, v|
    puts %Q{export #{k}=${#{k}:-#{v}}}
  end
end

if ENV["AWS_SECRETS"]
  secrets
end
