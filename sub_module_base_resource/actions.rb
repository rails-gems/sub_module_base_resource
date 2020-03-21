require_relative('instance_methods')
require_relative('pagination')
require_relative('search')
module SubModuleBaseResource
  module Actions
    include InstanceMethods
    include Pagination
    include Search

    def index resources = nil
      resources = find_base_resources resources
      if block_given?
        resources = yield(resources)
      end
      instance_variable_set("@#{resources_name(resources)}", paginate(resources.order(id: :desc)))
    end
    alias_method :br_index, :index
    # or in ruby > 2.2, child can call parent method use below method
    # method(:index).super_method.call

    def show
      resource = find_base_resource
      instance_variable_set("@#{resource_name(resource)}", resource)
      if block_given?
        yield(resource)
      end
    end
    alias_method :br_show, :show

    def create options = {}
      options = {auto_render_success: true, auto_render_error: true, custom_save: false, model_class: nil}.merge!(options || {})
      form = form_const.new((options[:model_class] || resource_klass).new)
      instance_variable_set("@#{resource_name(form.model)}", form.model)
      if form.validate(params)
        if options[:custom_save]
          form.save do |hash|
            yield hash, form
          end if block_given?
        else
          if form.save
            yield true if block_given?
            render json: { message: :successfully_create }, status: 200  and return if options[:auto_render_success]
          else
            yield false if block_given?
            render json: { message: form.errors.full_messages.first || form.model.errors.full_messages.first }, status: 422 and return if options[:auto_render_error]
          end
        end
      else
        yield false if block_given? && !options[:custom_save]
        render json: { message: form.errors.full_messages.first }, status: 422  and return if options[:auto_render_error]
      end
    end
    alias_method :br_create, :create

    def update resource = nil
      form = form_const.new(resource || resource_klass.find(params[:id]))
      if form.validate(params) && form.save
        resource = form.model
        instance_variable_set("@#{resource_name(resource)}", resource)
        if block_given?
          yield resource
        else
          render json: { message: :successfully_update }, status: 200
        end
      else
        render json: { message: form.errors.full_messages.first || form.model.errors.full_messages.first }, status: 422
      end
    end
    alias_method :br_update, :update

    def destroy
      resource = destroy_resource
      instance_variable_set("@#{resource_name(resource)}", resource)
      if block_given?
        yield resource
      else
        render json: { message: :successfully_destroy }, status: 200
      end
    end
    alias_method :br_destroy, :destroy

    protected

    def find_base_resources resources = nil
      search = (resources || resource_klass).ransack(prepare_search_condition)
      search.sorts = prepare_search_sorts if search.sorts.empty? && prepare_search_sorts.present?
      search.result(distinct: true)
    end

    def find_base_resource(id = nil)
      id ||= respond_to?(:params) && params.is_a?(ActionController::Parameters) && params[:id]
      resource_klass.find id
    end

    def destroy_resource(id = nil)
      id ||= respond_to?(:params) && params.is_a?(ActionController::Parameters) && params[:id]
      resource_klass.destroy id
    end

    def form_const
      namespaces = self.class.to_s.split("::")
      const = while namespaces.present?
                const = "#{namespaces.join('::')}::#{resource_klass_name}Form::#{action_name.classify}".constantize rescue nil
                break const if const
                namespaces.pop
              end
      const || "#{resource_klass_name}Form::#{action_name.classify}".try(:constantize)
    end
  end
end