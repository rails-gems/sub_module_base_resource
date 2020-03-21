module SubModuleBaseResource
  module InstanceMethods
    # name of the singular resource eg: 'user'
    def resource_name(resource = nil)
      resource ? resource.class.to_s.singularize.underscore.gsub('/', '_') : controller_name.singularize.underscore.gsub('/', '_')
    end

    # name of the resource collection eg: 'users'
    def resources_name(resources = nil)
      resources ? resources.model.to_s.pluralize.underscore.gsub('/', '_') : controller_name.pluralize.underscore.gsub('/', '_')
    end

    # eg: return 'User' string
    def resource_klass_name
      resource_name.classify
    end

    #  eg: return User klass
    def resource_klass
      resource_klass_name.constantize
    end
  end
end