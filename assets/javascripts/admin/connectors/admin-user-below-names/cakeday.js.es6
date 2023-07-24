import DiscourseURL, { userPath } from "discourse/lib/url";
import { ajax } from "discourse/lib/ajax";
import { popupAjaxError } from "discourse/lib/ajax-error";

export default {
  setupComponent(args, component) {
    console.log('admin args');
    console.log(args);
    console.log('admin component');
    console.log(component);
    
    if (this.get("user.birthdate") === "1903-04-05") {
      this.set("dateIsMagical", true);
    }
  },
  actions: {
    saveBirthdate(newDate) {
      console.log('admin saveBirthdate this');
      console.log(this);
      const oldDate = this.get("user.birthdate");
      this.set("user.birthdate", newDate);
      console.log(newDate)
      this.set("dateIsMagical", (newDate === "1903-04-05"));

      const path = userPath(`${this.get("user.username").toLowerCase()}.json`);

      return ajax(path, { data: { date_of_birth: newDate }, type: "PUT" })
        .catch((e) => {
          this.set("user.birthdate", oldDate);
          popupAjaxError(e);
        })
        .finally(() => this.toggleProperty("editingBirthdate"));
    },
    unlockBirthdate() {
      console.log('admin unlockBirthdate this');
      console.log(this);
      const oldDate = this.get("user.birthdate");
      const newDate = '1903-04-05';
      this.set("user.birthdate", newDate);
      this.set("dateIsMagical", true);

      const path = userPath(`${this.get("user.username").toLowerCase()}.json`);

      return ajax(path, { data: { date_of_birth: newDate }, type: "PUT" })
        .catch((e) => {
          this.set("user.birthdate", oldDate);
          popupAjaxError(e);
        });
    },
    setUnlockedBirthdate() {
      console.log('admin setUnlockedBirthdate this');
      console.log(this);
      document.getElementById('userBirthdate').getElementsByTagName('input').placeholder='yyyy-mm-dd';
      console.log(document.getElementById('userBirthdate').getElementsByTagName('input'));
      const oldDate = this.get("user.birthdate");
      const newDate = '';
      this.set("user.birthdate", newDate);
      this.set("dateIsMagical", false);
      this.toggleProperty("editingBirthdate");
    },
  },
};
