#!/usr/bin/ruby

require "erb"
require "fileutils"
require "date"

class AWSConfig
  attr_accessor :cidr, :zones, :size, :vpc_id, :vpc_dest_name,
   :cluster_tld,
   :cluster_tld_route53_zone_id,
   :profile

  def initialize(profile)
    @profile = profile
  end
end

class KubernetesSetup
  def self.path
    ARGV[0]
  end

  def self.cluster_name
    return @name if @name
    puts "CLUSTER_NAME (staging, production):"; @name = STDIN.gets.chomp + Date.today.strftime("%m%d%Y")
  end

  def self.cluster_dir
    File.join(KubernetesSetup.path, "kubernetes", KubernetesSetup.cluster_name)
  end

  def initialize
    KubernetesTemplate.new.render
    FileUtils.mv File.join(KubernetesSetup.path, "kubernetes", "cluster_template"), KubernetesSetup.cluster_dir
  end
end

class KubernetesTemplate
  include ERB::Util
  def render
    Dir.glob("templates/**/*.erb").each do |f|
      basename = File.basename(f).gsub(/.erb$/, "")
      dirname = File.join(KubernetesSetup.path, File.dirname(f).gsub("templates/", ""))
      FileUtils.mkdir_p(dirname)
#      puts "reading from #{f}"
      File.open(f) do |template|
        fileout = File.join(dirname, basename)
#        puts "writing to #{fileout}"
        File.open(fileout, "w") do |out|
          out.write(ERB.new(template.read).result)
        end
      end
    end
  end
end
aws_config = AWSConfig.new(ARGV[1])
KubernetesSetup.new
File.open("cluster_dir", "w"){|f| f.write KubernetesSetup.cluster_dir}
