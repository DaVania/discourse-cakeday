# frozen_string_literal: true

# name: discourse-cakeday
# about: Show a birthday cake beside the user's name on their birthday and/or on the date they joined Discourse.
# version: 0.4
# authors: Alan Tan
# url: https://github.com/discourse/discourse-cakeday
# transpile_js: true

enabled_site_setting :cakeday_enabled

register_asset "stylesheets/cakeday.scss"
register_asset "stylesheets/emoji-images.scss"
register_asset "stylesheets/user-date-of-birth-input.scss"
register_asset "stylesheets/mobile/user-date-of-birth-input.scss"

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
    get "birthdays/:filter" => "birthdays#index"
    get "anniversaries" => "anniversaries#index"
    get "anniversaries/:filter" => "anniversaries#index"
  end

  Discourse::Application.routes.append { mount ::DiscourseCakeday::Engine, at: "/cakeday" }

  %w[
    ../app/jobs/onceoff/fix_invalid_date_of_birth.rb
    ../app/jobs/onceoff/migrate_date_of_birth_to_users_table.rb
    ../app/serializers/discourse_cakeday/cakeday_user_serializer.rb
    ../app/controllers/discourse_cakeday/cakeday_controller.rb
    ../app/controllers/discourse_cakeday/anniversaries_controller.rb
    ../app/controllers/discourse_cakeday/birthdays_controller.rb
  ].each { |path| load File.expand_path(path, __FILE__) }

  # overwrite the user and user_card serializers to show
  # the cakes on the user card and on the user profile pages
  %i[user user_card].each do |serializer|
    add_to_serializer(serializer, :cakedate, include_condition: -> { scope.user.present? }) do
      timezone = scope.user.user_option&.timezone.presence || "UTC"
      object.created_at.in_time_zone(timezone).strftime("%Y-%m-%d")
    end

    add_to_serializer(
      serializer,
      :birthdate,
      include_condition: -> { SiteSetting.cakeday_birthday_enabled && scope.user.present? },
    ) {
        if SiteSetting.cakeday_birthday_enabled && object.date_of_birth.present?
          allowed_groups = []

          if object.custom_fields['groups_fullbirthday_visible']
            allowed_groups.concat(SiteSetting.cakeday_show_age_to_groups && object.custom_fields['groups_fullbirthday_visible'].to_s.split('|'))
          end

          allowedByGroup = allowed_groups.present? && scope.user.groups.where(id: allowed_groups).exists?

          if object.date_of_birth.to_s == "1903-04-05"
            nil
          elsif (scope.is_me?(object) || scope.is_staff? || allowedByGroup)
            object.date_of_birth
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
      }

    add_to_serializer(serializer, :include_cakedate?) do
      SiteSetting.cakeday_enabled && scope.user.present?
    end

    add_to_serializer(serializer, :include_birthdate?) do
      SiteSetting.cakeday_birthday_enabled && scope.user.present?
    end
  end

  # overwrite the post serializer to show the cakes next to the
  # username in the posts stream

  add_to_serializer(
    :post,
    :user_cakedate,
    include_condition: -> { scope.user.present? && object.user&.created_at.present? },
  ) do
    timezone = scope.user.user_option&.timezone.presence || "UTC"
    object.user.created_at.in_time_zone(timezone).strftime("%Y-%m-%d")
  end

  add_to_serializer(
    :post,
    :user_birthdate,
    include_condition: -> { SiteSetting.cakeday_birthday_enabled && object.user.date_of_birth.present? }
  ) do
      if SiteSetting.cakeday_birthday_enabled && object.user.date_of_birth.present?
        allowed_groups = []

        if object.custom_fields['groups_fullbirthday_visible']
          allowed_groups.concat(SiteSetting.cakeday_show_age_to_groups && object.custom_fields['groups_fullbirthday_visible'].to_s.split('|'))
        end

        allowedByGroup = allowed_groups.present? && scope.user.groups.where(id: allowed_groups).exists?

        if object.user.date_of_birth.to_s == "1903-04-05"
          nil
        elsif (scope.is_me?(object) || scope.is_staff? || allowedByGroup)
          object.user.date_of_birth
        else
          if (object.show_birthday_to_be_celebrated)
            Date.new(1904, object.user.date_of_birth.month, object.user.date_of_birth.day)
          else
            nil
          end
        end
      else
        nil
      end
  end

  add_to_serializer(:post, :include_user_cakedate?) do
    SiteSetting.cakeday_enabled && scope.user.present? && object.user&.created_at.present?
  end

  add_to_serializer(:post, :include_user_birthdate?) do
    SiteSetting.cakeday_birthday_enabled && scope.user.present? &&
      object.user&.date_of_birth.present?
  end

  validate(:user, :cakeday_user_validator) do |force = nil|
    if SiteSetting.cakeday_birthday_required && (date_of_birth.blank? || (SiteSetting.cakeday_birthday_show_year && date_of_birth.year == 1904))
      errors.add(:date_of_birth, :blank, message: I18n.t('errors.messages.blank'))
    end

    if date_of_birth.present? && date_of_birth.to_s == "1903-04-05"
      date_of_birth = nil
    end
  end

  %w[
    show_birthday_to_be_celebrated
    limit_age_visibility_to_groups
  ].each do |field|
    User.register_custom_field_type(field, :boolean)
    DiscoursePluginRegistry.serialized_current_user_fields << field
    register_editable_user_custom_field field.to_sym

    %i[user post].each do |serializer|

      add_to_class(serializer, field.to_sym) do
        if custom_fields[field] != nil
          custom_fields[field]
        else
          true
        end
      end
      add_to_serializer(serializer, field.to_sym)  {object.send(field)}

    end
  end

  add_to_serializer(:admin_user, :birthdate?) do
    object&.date_of_birth
  end

end
