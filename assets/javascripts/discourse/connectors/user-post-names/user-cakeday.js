import {
  birthday,
  birthdayTitle,
  cakeday,
  cakedayTitle,
  celebrate,
  secretTitle,
} from "discourse/plugins/discourse-cakeday/discourse/lib/cakeday";

export default {
  setupComponent({ model }, component) {
    component.set("isCakeday", cakeday(model.cakedate));
    component.set("isBirthday", birthday(model.birthdate));
    component.set("isSecret", !celebrate(model));
    component.set("cakedayTitle", cakedayTitle(model, this.currentUser));
    component.set("birthdayTitle", birthdayTitle(model, this.currentUser));
    component.set("secretTitle", secretTitle(model, this.currentUser));
  },
};
