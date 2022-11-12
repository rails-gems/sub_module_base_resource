require_relative('instance_methods')
require_relative('pagination')
require_relative('search')
module SubModuleBaseResource
  module Actions
    include InstanceMethods
    include Pagination
    include Search

    def br_index(resources: nil, distinct: true, var_name: nil)
      resources = get_params_resources(distinct: distinct, resources: resources).order(id: :desc)
      if block_given?
        resources = yield(resources)
      end
      var_name ||= "@#{resources_name(resources: resources)}"
      instance_variable_set(var_name, paginate(resources: resources))
    end
    # or in ruby > 2.2, child can call parent method use below method
    # method(:index).super_method.call

    def br_show(resources: nil, var_name: nil)
      resource = get_params_resource(resources: resources)
      var_name ||= "@#{resource_name(resource: resource)}"
      instance_variable_set(var_name, resource)
      if block_given?
        yield(resource)
      end
    end
    # alias_method :br_show, :show

    # form_class默认根据controller路径规则寻找
    # model_class默认根据controller命令来 eg: UsersController -> User
    def br_create(auto_save: true, form_class: nil, model_class: nil, var_name: nil, auto_render_success: true)
      model_class ||= resource_klass
      form_class ||= resource_form_const(model_class: model_class)
      form = form_class.new(model_class.new)
      var_name ||= "@#{resource_name(resource: form.model)}"
      instance_variable_set(var_name, form.model)
      begin
        if form.validate(params)
          if auto_save
            if form.save
              yield true if block_given?
              render json: { message: :successfully_create }, status: 200 and return if auto_render_success
            else
              yield false if block_given?
              render json: { message: format_error(form.model) }, status: 422 and return
            end
          else
            form.sync
            form.save do |hash|
              yield hash, form.model
            end if block_given?
          end
        else
          # yield false if block_given?
          render json: { message: format_error(form) }, status: 422 and return
        end
      rescue Exception => e
        render json: { message: e.message }, status: 422 and return
      end
    end
    # alias_method :br_create, :create

    def br_update(auto_save: true, form_class: nil, model: nil, var_name: nil, auto_render_success: false)
      resource = model || get_params_resource
      if resource.blank?
        render json: { message: :not_found }, status: 422 and return
      end
      form_class ||= resource_form_const(model_class: resource.class)
      form = form_class.new(resource)
      var_name ||= "@#{resource_name(resource: resource)}"
      instance_variable_set(var_name, resource)
      if form.validate(params)
        if auto_save
          begin
            if form.save
              yield true if block_given?
              render json: { message: :successfully_update }, status: 200 and return if auto_render_success
            else
              yield false if block_given?
              render json: { message: format_error(form.model) }, status: 422 and return
            end
          rescue Exception => e
            render json: { message: e.message }, status: 422 and return
          end
        else
          form.sync
          form.save do |hash|
            yield hash, form.model
          end if block_given?
        end
      else
        render json: { message: format_error(form) }, status: 422 and return
      end
    end
    # alias_method :br_update, :update

    def br_destroy(resources: nil, model: nil, var_name: nil)
      resource = model || get_params_resource(resources: resources)
      if resource.blank?
        render json: { message: :not_found }, status: 422 and return
      end
      var_name ||= "@#{resource_name(resource: resource)}"
      instance_variable_set(var_name, resource)
      if block_given?
        yield resource
      else
        render json: { message: :successfully_destroy }, status: 200
      end
    end
    # alias_method :br_destroy, :destroy

    protected

    def format_error(instance)
      instance.errors.full_messages.join(',')
    end

    private

    def get_params_resources(resources: nil, distinct: true)
      search = (resources || resource_klass).ransack(prepare_search_condition)
      search.sorts = prepare_search_sorts if search.sorts.empty? && prepare_search_sorts.present?
      search.result(distinct: distinct)
    end

    def get_params_resource(resources: nil, field: :id)
      field_value = respond_to?(:params) && params.is_a?(ActionController::Parameters) && params[field]
      (resources || resource_klass).find_by(field => field_value)
    end

    def resource_form_const(model_class:)
      klass_name = model_class.to_s || resource_klass_name
      namespaces = self.class.to_s.split("::")
      const = while namespaces.present?
                const = "#{namespaces.join('::')}::#{klass_name}Form::#{action_name.classify}".safe_constantize
                # p "#{namespaces.join('::')}::#{klass_name}Form::#{action_name.classify}"
                break const if const
                namespaces.pop
              end
      const || "#{klass_name}Form::#{action_name.classify}".try(:constantize)
    end
  end
end