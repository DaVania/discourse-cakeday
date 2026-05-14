# frozen_string_literal: true

module DiscoursePrivateCakeday
  class CakedayUserSerializer < BasicUserSerializer
    attributes :title, :cakedate
  end
end
