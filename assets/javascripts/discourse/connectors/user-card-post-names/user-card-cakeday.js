import {
  cakeday,
  cakedayBirthday,
  cakedayBirthdayTitle,
  cakedayTitle,
<<<<<<< HEAD
=======
  userAge,
>>>>>>> eb4b8a7a696c127871a8a345c83f12d1121ab1f0
  userAgeTitle,
} from "discourse/plugins/discourse-cakeday/discourse/lib/cakeday";

export default {
  setupComponent(args, component) {
    component.set("isCakeday", cakeday(args.user.get("created_at")));
    component.set(
      "isUserBirthday",
      cakedayBirthday(args.user.get("date_of_birth"))
    );
    component.set("cakedayTitle", cakedayTitle(args.user, this.currentUser));
    component.set(
      "cakedayBirthdayTitle",
      cakedayBirthdayTitle(args.user, this.currentUser)
    );
    const isStaff = this.currentUser && this.currentUser.staff;
    const isAdmin = this.currentUser && this.currentUser.admin;
<<<<<<< HEAD
    if (isAdmin || isStaff) {
      component.set("userAgeTitle", userAgeTitle(args.user, this.currentUser));
	}
=======
    if (isAdmin || isStaff)
      component.set("userAgeTitle", userAgeTitle(args.user, this.currentUser));
>>>>>>> eb4b8a7a696c127871a8a345c83f12d1121ab1f0
  },
};
