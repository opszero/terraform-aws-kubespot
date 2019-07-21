def secrets
  `aws secretsmanager get-secret-value --secret-id #{ENV["AWS_SECRETS"]} | jq -r '.SecretString'`.
    split("\n").map{|s|
    s.split("=")
  }.each do |k, v|
    next unless k
    puts %Q{export #{k}=${#{k}:-#{v.inspect}}}
  end
end

if ENV["AWS_SECRETS"]
  secrets
end
