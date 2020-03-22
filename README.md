# sub_module_base_resource

base resource

### install

```bash
$ git submodule add https://github.com/rails-gems/sub_module_base_resource lib/submodules/sub_module_base_resource
```

### add dependences

```ruby
# gem 'jbuilder', '~> 2.5'
# 表单
gem 'reform'
gem 'reform-rails'
# 分页
gem 'kaminari'
# 搜索
gem 'ransack'
```

### 引入

```ruby
# config/application.rb
config.eager_load_paths << Rails.root.join('lib/submodules/sub_module_base_resource')
# autoload_paths在生产环境可能无法加载， 不推荐 -> https://www.jianshu.com/p/e4446432e9cb
#config.autoload_paths << Rails.root.join('lib/submodules/sub_module_base_resource') 
```

```ruby
class ApplicationController < ActionController::Base
  include SubModuleBaseResource
end
```
