import Controller from "@ember/controller";
import { alias } from "@ember/object/computed";

export default Controller.extend({
  cakedayEnabled: alias("siteSettings.private_cakeday_enabled"),
  birthdayEnabled: alias("siteSettings.private_cakeday_birthday_enabled"),
});
