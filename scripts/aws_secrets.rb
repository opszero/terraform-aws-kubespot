def secrets
  `aws secretsmanager get-secret-value --secret-id #{ENV["AWS_SECRETS"]} | jq -r '.SecretString'`.
    split("\n").map{|s|
    s.split("=")
  }.each do |k, v|
    puts %{#{k}=${#{k}:-"#{v}"}}
  end
end

if ENV["AWS_SECRETS"]
  secrets
end
