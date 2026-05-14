import I18n from "I18n";
import DiscourseRoute from "discourse/routes/discourse";

export default DiscourseRoute.extend({
  beforeModel() {
    if (!this.siteSettings.private_cakeday_enabled) {
      this.transitionTo("unknown", window.location.pathname.replace(/^\//, ""));
    }
  },

  titleToken() {
    return I18n.t("anniversaries.title");
  },
});
