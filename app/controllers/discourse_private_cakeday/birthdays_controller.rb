# frozen_string_literal: true

module DiscoursePrivateCakeday
  class BirthdaysController < CakedayController
    before_action :ensure_birthday_enabled
    before_action :restrict_to_celebrated_for_non_staff

    def index
      users, total, more_params = cakedays_by("date_of_birth")

      render_json_dump(
        birthdays: serialize_data(users, CakedayUserSerializer),
        total_rows_birthdays: total,
        load_more_birthdays: birthdays_path(more_params),
      )
    end

    private

    # Non-staff users may only see members who opted in to having their
    # birthday celebrated. This must narrow the set *before* cakedays_by
    # counts and paginates, otherwise total_rows_birthdays disagrees with
    # the rows actually returned and the client LoadMore loops forever.
    def restrict_to_celebrated_for_non_staff
      return if current_user.staff?

      celebrated_user_ids =
        UserCustomField.where(name: "show_birthday_to_be_celebrated", value: "true").select(
          :user_id,
        )

      @users = @users.where(id: celebrated_user_ids)
    end

    def ensure_birthday_enabled
      raise Discourse::NotFound if !SiteSetting.private_cakeday_birthday_enabled
    end
  end
end
