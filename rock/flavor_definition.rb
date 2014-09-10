module Rock
    class FlavorDefinition
        attr_reader :name
        attr_reader :branch
        attr_predicate :implicit?, true
        attr_accessor :default_packages
        attr_accessor :removed_packages

        def initialize(name, branch = name)
            @name = name
            @branch = branch
            @implicit = false
            @default_packages = Hash.new { |h, k| h[k] = Set.new }
            @removed_packages = Set.new
        end

        def include?(package_name)
            package_name = package_name.to_str
            return false if removed?(package_name)
            @default_packages.any? do |pkg_set, packages|
                packages.include?(package_name)
            end
        end

        def removed?(package_name)
            removed_packages.include?(package_name.to_str)
        end
    end
end

