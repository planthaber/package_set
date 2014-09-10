# Set to true if this is a frozen release branch
ROCK_FROZEN = false
# The name of the "current" release
ROCK_CURRENT_RELEASE = "rock1408_rc1"

#
# Orocos Specific ignore rules
#
# Ignore log files generated from the orocos/orogen components
ignore(/\.log$/, /\.ior$/, /\.idx$/)
# Ignore all text files except CMakeLists.txt
ignore(/(^|\/)(?!CMakeLists)[^\/]+\.txt$/)
# We don't care about the manifest being changed, as autoproj *will* take
# dependency changes into account
ignore(/manifest\.xml$/)
# Ignore vim swap files
ignore(/\.sw?$/)
# Ignore the numerous backup files
ignore(/~$/)

# Verify that Ruby is NOT 1.8. 1.8 is unsupported
if defined?(RUBY_VERSION) && (RUBY_VERSION =~ /^1\.8\./)
    Autoproj.error "Ruby 1.8 is not supported by Rock anymore"
    Autoproj.error ""
    Autoproj.error "Use Rock's bootstrap.sh script to install Rock"
    Autoproj.error "See http://rock-robotics.org/documentation/installation.html for more information"
    exit 1
end

require 'autoproj/gitorious'
if !Autoproj.has_source_handler? 'gitorious'
    Autoproj.gitorious_server_configuration('GITORIOUS', 'gitorious.org')
end
if !Autoproj.has_source_handler? 'github'
    Autoproj.gitorious_server_configuration('GITHUB', 'github.com', :http_url => 'https://github.com')
end

require File.join(File.dirname(__FILE__), 'rock/flavor_definition')
require File.join(File.dirname(__FILE__), 'rock/flavor_manager')
require File.join(File.dirname(__FILE__), 'rock/in_flavor_context')

Rock.flavors.define 'stable', :branch => ROCK_CURRENT_RELEASE
Rock.flavors.alias 'stable', 'next'
Rock.flavors.define ROCK_CURRENT_RELEASE
Rock.flavors.define 'master', :implicit => true

configuration_option('ROCK_SELECTED_FLAVOR', 'string',
    :default => ROCK_CURRENT_RELEASE,
    :possible_values => ['stable', 'master', ROCK_CURRENT_RELEASE],
    :doc => [
        "Which flavor of Rock do you want to use ?",
        "Use either the release name #{ROCK_CURRENT_RELEASE} to use this released, known-to work",
        "version of Rock that is guaranteed to not change. Or use the keywords 'stable' to",
        "always track the latest release and 'master' for the development branch"])

# Migrate the value in ROCK_FLAVOR to ROCK_SELECTED_FLAVOR
if Autoproj.has_config_key?('ROCK_FLAVOR')
    Autoproj.change_option('ROCK_SELECTED_FLAVOR', Autoproj.user_config('ROCK_FLAVOR'), true)
end


if ROCK_FROZEN
    Rock.flavors.select_current_flavor_by_name(
        ENV['ROCK_FORCE_FLAVOR'] || ROCK_CURRENT_RELEASE)
else
    Rock.flavors.select_current_flavor_by_name(
        ENV['ROCK_FORCE_FLAVOR'] || Autoproj.user_config('ROCK_SELECTED_FLAVOR'))
end

current_flavor = Rock.flavors.current_flavor
Autoproj.change_option('ROCK_SELECTED_FLAVOR', current_flavor.name, true)
Autoproj.change_option('ROCK_FLAVOR', current_flavor.branch, true)
Autoproj.change_option('ROCK_BRANCH', current_flavor.branch, true)
Autoproj::PackageSet.add_source_file \
    "source-#{if current_flavor.name == "master" then 'master' else 'stable' end}.yml"

def enabled_flavor_system
    Rock.flavors.register_flavored_package_set(Autoproj.current_package_set)
end

def in_flavor(*flavors, &block)
    Rock.flavors.in_flavor(*flavors, &block)
end

def only_in_flavor(*flavors, &block)
    Rock.flavors.only_in_flavor(*flavors, &block)
end

def flavor_defined?(flavor_name)
    Rock.flavors.has_flavor?(flavor_name)
end

def package_in_flavor?(pkg, flavor_name)
    Rock.flavors.package_in_flavor?(pkg, flavor_name)
end

def add_packages_to_flavors(mappings)
    Rock.flavors.add_packages_to_flavors(Autoproj.current_package_set, mappings)
end

def remove_packages_from_flavors(mappings)
    Rock.flavors.remove_packages_from_flavors(Autoproj.current_package_set, mappings)
end

# Defines a bundle package in the installation
#
# So far, bundles are mostly Ruby packages
def bundle_package(*args, &block)
    ruby_package(*args) do |pkg|
        Autoproj.env_add_path 'ROCK_BUNDLE_PATH', pkg.srcdir
        if block_given?
            pkg.instance_eval(&block)
        end
    end
end

