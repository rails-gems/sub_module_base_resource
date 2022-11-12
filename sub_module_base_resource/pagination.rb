module SubModuleBaseResource
  module Pagination

    protected

    def paginate(resources:)
      resources = resources.page(params[:page] || 1)
      # default per_page is 25
      resources = resources.per(params[:per_page] || 20)
      resources
    end
  end
end