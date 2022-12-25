# frozen_string_literal: true

# name: discourse-cakeday
# about: Show a birthday cake beside the user's name on their birthday or on the date they joined Discourse.
# version: 0.2
# authors: Alan Tan
# url: https://github.com/discourse/discourse-cakeday
# transpile_js: true

register_asset 'stylesheets/cakeday.scss'
register_asset 'stylesheets/emoji-images.scss'
register_asset 'stylesheets/user-date-of-birth-input.scss'
register_asset 'stylesheets/mobile/user-date-of-birth-input.scss'

register_svg_icon "birthday-cake" if respond_to?(:register_svg_icon)

after_initialize do
  module ::DiscourseCakeday
    PLUGIN_NAME = "discourse-cakeday"

    class Engine < ::Rails::Engine
      engine_name PLUGIN_NAME
      isolate_namespace DiscourseCakeday
    end
  end

  ::DiscourseCakeday::Engine.routes.draw do
    get "birthdays" => "birthdays#index"
    get "birthdays/(:filter)" => "birthdays#index"
    get "anniversaries" => "anniversaries#index"
    get "anniversaries/(:filter)" => "anniversaries#index"
  end

  Discourse::Application.routes.append do
    mount ::DiscourseCakeday::Engine, at: "/cakeday"
  end

  load File.expand_path("../app/jobs/onceoff/fix_invalid_date_of_birth.rb", __FILE__)
  load File.expand_path("../app/jobs/onceoff/migrate_date_of_birth_to_users_table.rb", __FILE__)
  load File.expand_path("../app/serializers/discourse_cakeday/anniversary_user_serializer.rb", __FILE__)
  load File.expand_path("../app/serializers/discourse_cakeday/birthday_user_serializer.rb", __FILE__)
  load File.expand_path("../app/controllers/discourse_cakeday/cakeday_controller.rb", __FILE__)
  load File.expand_path("../app/controllers/discourse_cakeday/anniversaries_controller.rb", __FILE__)
  load File.expand_path("../app/controllers/discourse_cakeday/birthdays_controller.rb", __FILE__)

  require_dependency 'user'
  class ::User
    scope :valid, ->() {
      if ActiveRecord::Base.connection.column_exists?(:users, :silenced_till) ||
        ActiveRecord::Base.connection.column_exists?(:users, :silenced)
        activated.not_silenced.not_suspended.real
      else
        activated.not_blocked.not_suspended.real
      end
    }

    scope :order_by_likes_received, ->() {
      joins(:user_stat)
        .order("user_stats.likes_received DESC")
    }
  end

  validate User, :discourse_cakeday_validation do
    errors.add(:base, I18n.t('cakeday.cakeday_birthday_required')) if date_of_birth == nil && SiteSetting.cakeday_birthday_required && !staff?
  end


  User.register_custom_field_type('groups_fullbirthday_visible', [:integer])
  DiscoursePluginRegistry.serialized_current_user_fields << "groups_fullbirthday_visible"
  
  add_to_class(:user, :groups_fullbirthday_visible) do
    self.custom_fields['groups_fullbirthday_visible'] || []
  end

  add_to_serializer(:user, :groups_fullbirthday_visible) do
    object.custom_fields && object.custom_fields['groups_fullbirthday_visible'].to_a
  end

  register_editable_user_custom_field [:groups_fullbirthday_visible]
  register_editable_user_custom_field groups_fullbirthday_visible: []

  %w[
    show_birthday_to_be_celebrated
  ].each do |field|
    User.register_custom_field_type(field, :boolean)
    DiscoursePluginRegistry.serialized_current_user_fields << field
    # default options to true if not set by user
    add_to_class(:user, field.to_sym) do
      if custom_fields[field] != nil
        custom_fields[field]
      else
        true
      end
    end
    add_to_serializer(:user, field.to_sym)  {object.send(field)}
    register_editable_user_custom_field field.to_sym
  end

  %w[
    limit_age_visibility_to_groups
  ].each do |field|
    User.register_custom_field_type(field, :boolean)
    DiscoursePluginRegistry.serialized_current_user_fields << field
    # default options to false if not set by user
    add_to_class(:user, field.to_sym) do
      if custom_fields[field] != nil
        custom_fields[field]
      else
        false
      end
    end
    add_to_serializer(:user, field.to_sym)  {object.send(field)}
    register_editable_user_custom_field field.to_sym
  end

  add_to_serializer(:user_card, :date_of_birth, false) do
    if object.date_of_birth != nil
      allowed_groups = []
      #allowed_groups.concat(object.custom_fields['groups_fullbirthday_visible'])
      allowed_groups.concat(object.custom_fields && object.custom_fields['groups_fullbirthday_visible'].to_a)
      allowedByGroup = allowed_groups.present? && scope.user.groups.where(id: allowed_groups).exists?

      if (scope.is_me?(object) || scope.is_staff? || allowedByGroup)
        object.date_of_birth
      #if (allowedByGroup)
      #  Date.new(1911, object.date_of_birth.month, object.date_of_birth.day)
      else
        if (object.show_birthday_to_be_celebrated)
          Date.new(1904, object.date_of_birth.month, object.date_of_birth.day)
        else
          nil
        end
      end
    else
      nil
    end
  end

  add_to_serializer(:user_card, :include_date_of_birth?) do
    SiteSetting.cakeday_birthday_enabled && scope.user.present?
  end

  require_dependency 'post_serializer'

  class ::PostSerializer
    attributes :user_created_at, :user_date_of_birth

    def include_user_created_at?
      SiteSetting.cakeday_enabled && scope.user.present?
    end

    def user_created_at
      object.user&.created_at
    end

    def include_user_date_of_birth?
      SiteSetting.cakeday_birthday_enabled && scope.user.present?
    end

    def user_date_of_birth
      object.user&.date_of_birth
    end
  end
end
