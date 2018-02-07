#!/usr/bin/env ruby
# -*- coding : utf-8 -*-

require 'cocoapods-core'
require 'json'

module PodspecHelper
	class Convert
		def initialize(origin,convert)
      		@origin_spec_path, @convert_spec_path = origin, convert
      		@has_framework = false
      		@new_version = '1.0.0'
   		end

   		def has_framework=(new_has_framework)
    		@has_framework = new_has_framework
  		end

  		def new_version=(new_new_version)
    		@new_version = new_new_version
  		end

		def load
			ENV['source'] = 'all'
			spec = Pod::Specification.from_file(@origin_spec_path)
			@spec = spec
		end

		def convert
			deployment_target = '8.0'
			@spec.version = @new_version
			spec_content = "Pod::Spec.new do |s|\n"
			spec_content += "s.name = \'"+@spec.module_name+"\'\n"
			spec_content += "s.version = \'"+@spec.version.to_s+"\'\n"
			spec_content += "s.cocoapods_version = \'"+@spec.cocoapods_version.to_s[2...@spec.cocoapods_version.to_s.length]+"\'\n"
			spec_content += "s.summary = \'"+@spec.summary+"\'\n"
			if @spec.respond_to? 'description' and @spec.description
				spec_content += "s.description = \'"+@spec.description+"\'\n"
			end
			if @spec.respond_to? 'homepage' and @spec.homepage
				spec_content += "s.homepage = \'"+@spec.homepage+"\'\n"
			end
			if @spec.respond_to? 'license' and @spec.license
				spec_content += "s.license = "+@spec.license.to_hash.to_s+"\n"
			end
			if @spec.respond_to? 'authors' and @spec.authors
				spec_content += "s.author = "+@spec.authors.to_hash.to_s+"\n"
			end
			if @spec.respond_to? 'source' and @spec.source
				git = @spec.source.to_hash[@spec.source.to_hash.keys[0]]
				source = {}
				source['git'] = git
				source['tag'] = 'v'+@new_version
				spec_content += "s.source = "+source.to_hash.to_s+"\n"
			end
			spec_content += "s.ios.deployment_target = '"+deployment_target+"'\n"
			#has framework
			if @has_framework
				spec_content +="env_value = ENV['source']\n"
  				spec_content +="if env_value && (env_value.split(',').include?(s.name) || (env_value == 'all'))\n"
			end
			#source
			if @spec.attributes_hash.has_key?('source_files')
				source_files = @spec.attributes_hash['source_files']
				if source_files.class == Array
					source_files = source_files.join("',\n'")
				end
				spec_content +="s.source_files = \'"+source_files+"\'\n"
			end
			#resources
			if @spec.attributes_hash.has_key?('resources')
				resources = @spec.attributes_hash['resources']
				if resources.class == Array
					resources = resources.join("',\n'")
				end
				spec_content +="s.resources = '"+resources+"'\n"
			end
			#resource
			if @spec.attributes_hash.has_key?('resource')
				spec_content +="s.resource = '"+@spec.attributes_hash['resource']+"'\n"
			end
			#public_header_files
			if @spec.attributes_hash.has_key?('public_header_files')
				public_header_files = @spec.attributes_hash['public_header_files']
				if public_header_files.class == Array
					public_header_files = public_header_files.join("',\n'")
				end
				spec_content +="s.public_header_files = '"+public_header_files+"'\n"
			end
			#private_header_files
			if @spec.attributes_hash.has_key?('private_header_files')
				private_header_files = @spec.attributes_hash['private_header_files']
				if private_header_files.class == Array
					private_header_files = private_header_files.join("',\n'")
				end
				spec_content +="s.private_header_files = '"+private_header_files+"'\n"
			end
			#frameworks
			if @spec.attributes_hash.has_key?('frameworks')
				frameworks = @spec.attributes_hash['frameworks']
				if frameworks.class == Array
					frameworks = frameworks.join("',\n'")
				end
				spec_content += "s.frameworks = '"+frameworks+"'\n"
			end
			#dependency
			@spec.dependencies.each { |item|
				spec_content += "s.dependency \'"+item.to_s+"\'\n"
			}
  			#vendored_libraries
  			if @spec.attributes_hash.has_key?('vendored_libraries')
				vendored_libraries = @spec.attributes_hash['vendored_libraries']
				if vendored_libraries.class == Array
					vendored_libraries = vendored_libraries.join("',\n'")
				end
				spec_content += "s.vendored_libraries = '"+vendored_libraries+"'\n"
			end
			#vendored_frameworks
			if @spec.attributes_hash.has_key?('vendored_frameworks')
				vendored_frameworks = @spec.attributes_hash['vendored_frameworks']
				if vendored_frameworks.class == Array
					vendored_frameworks = vendored_frameworks.join("',\n'")
				end
				spec_content += "s.vendored_frameworks = '"+vendored_frameworks+"'\n"
			end
			#has framework
			if @has_framework
				spec_content +="else\n"
				spec_content +="s.source_files = ''\n"
    			spec_content +="s.preserve_paths = 'FrameworkLocation'\n"
    			spec_content +="s.vendored_frameworks = 'FrameworkLocation/' + s.name + '.framework'\n"
    			spec_content += "end\n"
  			end
  			consumer = @spec.consumer(Pod::Platform.ios)
  			if consumer.respond_to? 'pod_target_xcconfig' and consumer.pod_target_xcconfig
				spec_content += "s.pod_target_xcconfig = "+consumer.pod_target_xcconfig.to_s+"\n"
			end
			#library
			if consumer.respond_to? 'libraries' and consumer.libraries.length > 0
				libraries = consumer.libraries
				if libraries.class == Array
					libraries = libraries.join("',\n'")
				end
				spec_content += "s.libraries = '"+libraries+"'\n"
			end
			#subspec
			@spec.subspecs.each { |sub|
				spec_content += return_subspec('s',sub)
			}
			spec_content += "end"
			puts @spec.to_pretty_json
			puts spec_content
			File.open(@convert_spec_path, 'w') { |f| f.write(spec_content) }
		end

		def return_subspec(symbol,subspec)
			cur_symbol = symbol+'_sub'
			content = symbol+".subspec \'"+subspec.module_name+"\' do |"+cur_symbol+"|\n"
			#arc
			if subspec.respond_to? 'requires_arc' and subspec.requires_arc
				content += cur_symbol+".requires_arc = "+subspec.requires_arc.to_s+"\n"
			end
			#source_file
			if subspec.attributes_hash.has_key?('source_files')
				source_files = subspec.attributes_hash['source_files']
				if source_files.class == Array
					source_files = source_files.join("',\n'")
				end
				content += cur_symbol+".source_files = '"+source_files+"'\n"
			end
			#frameworks
			if subspec.attributes_hash.has_key?('frameworks')
				frameworks = subspec.attributes_hash['frameworks']
				if frameworks.class == Array
					frameworks = frameworks.join("',\n'")
				end
				content += cur_symbol+".frameworks = '"+frameworks+"'\n"
			end
			#resources
			if subspec.attributes_hash.has_key?('resources')
				resources = subspec.attributes_hash['resources']
				if resources.class == Array
					resources = resources.join("',\n'")
				end
				content += cur_symbol+".resources = '"+resources+"'\n"
			end
			if subspec.attributes_hash.has_key?('resource')
				content += cur_symbol+".resource = '"+subspec.attributes_hash['resource']+"'\n"
			end
			#private_header_files
			if subspec.attributes_hash.has_key?('private_header_files')
				private_header_files = subspec.attributes_hash['private_header_files']
				if private_header_files.class == Array
					private_header_files = private_header_files.join("','")
				end
				content += cur_symbol+".private_header_files = '"+private_header_files+"'\n"
			end
			#public_header_files
			if subspec.attributes_hash.has_key?('public_header_files')
				public_header_files = subspec.attributes_hash['public_header_files']
				if public_header_files.class == Array
					public_header_files = public_header_files.join("',\n'")
				end
				content += cur_symbol+".public_header_files = '"+public_header_files+"'\n"
			end
			#compiler_flags
			if subspec.attributes_hash.has_key?('compiler_flags')
				compiler_flags = subspec.attributes_hash['compiler_flags']
				if compiler_flags.class == Array
					compiler_flags = compiler_flags.join("',\n'")
				end
				content += cur_symbol+".compiler_flags = '"+compiler_flags+"'\n"
			end
			#header_mappings_dir
			if subspec.attributes_hash.has_key?('header_mappings_dir')
				content += cur_symbol+".header_mappings_dir = '"+subspec.attributes_hash['header_mappings_dir']+"'\n"
			end
			#dependency
			subspec.dependencies.each { |dependency|
				content += cur_symbol+".dependency \'"+dependency.to_s+"\'\n"
			}
			#vendored_frameworks
			if subspec.attributes_hash.has_key?('vendored_frameworks')
				vendored_frameworks = subspec.attributes_hash['vendored_frameworks']
				if vendored_frameworks.class == Array
					vendored_frameworks = vendored_frameworks.join("',\n'")
				end
				content += cur_symbol+".vendored_frameworks = '"+vendored_frameworks+"'\n"
			end
			#library
			consumer = subspec.consumer(Pod::Platform.ios)
			if consumer.respond_to? 'libraries' and consumer.libraries.length > 0
				libraries = consumer.libraries
				if libraries.class == Array
					libraries = libraries.join("',\n'")
				end
				content += cur_symbol+".libraries = '"+libraries+"'\n"
			end
			#subsepc
			subspec.subspecs.each { |sub|
				content += return_subspec(cur_symbol,sub)
			}
			content += "end\n"
			return content
		end
	end
end

#main
if ARGV.length < 2
	puts '缺少目录，以及podspec名字'
	exit 1
end
folder_path = ARGV[0]
podspec = ARGV[1]

origin_path = File.join(folder_path,podspec)
convert_path = origin_path
convert = PodspecHelper::Convert.new(origin_path,convert_path)
convert.new_version = "8.0.2"
convert.has_framework = false
convert.load
convert.convert
yml_content = """
# HashSyntax:
#   EnforcedStyle: hash_rockets
Style/AsciiComments:
  Description: 'Use only ascii symbols in comments.'
  StyleGuide: '#english-comments'
  Enabled: false

Metrics/LineLength:
  Enabled: false

Metrics/BlockLength:
  Enabled: false
"""
cmd_yml = "cd "+folder_path+" && touch .rubocop.yml && echo \""+yml_content+"\" > .rubocop.yml"
system cmd_yml
cmd_rubocop = 'cd '+folder_path+' && rubocop -a -d '+podspec
system cmd_rubocop
