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
class ApplicationController < ActionController::Base
  include SubModuleBaseResource
end
```
