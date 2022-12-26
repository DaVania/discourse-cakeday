import Group from "discourse/models/group";
import {
  userAge,
  userBirthdateText,
} from "discourse/plugins/discourse-cakeday/discourse/lib/cakeday";

export default {
  setupComponent(args, component) {
    const year = 1904;
    const months = moment.months().map((month, index) => {
      return { name: month, value: index + 1 };
    });

    const days = Array.from(Array(31).keys()).map((x) => (x + 1).toString());

    const dateOfBirth = args.model.get("date_of_birth");
    const userBirthdayYear = dateOfBirth
      ? (moment(dateOfBirth, "YYYY-MM-DD").year() !== year ? moment(dateOfBirth, "YYYY-MM-DD").year() : null)
      : null;
    const userBirthdayMonth = dateOfBirth
      ? moment(dateOfBirth, "YYYY-MM-DD").month() + 1
      : null;
    const userBirthdayDay = dateOfBirth
      ? moment(dateOfBirth, "YYYY-MM-DD").date().toString()
      : null;

    const isAdmin = this.currentUser.admin;
    const isModerator = this.currentUser.moderator;
    const isStaff = this.currentUser.staff;
    const showYear = args.model.siteSettings.cakeday_birthday_show_year;

    let saved = false;

    let hasBirthdate = false;
    if (showYear)
      hasBirthdate = dateOfBirth !== null && userBirthdayYear !== null;
    else
      hasBirthdate = dateOfBirth !== null;
    args.model.set("hasBirthdate", hasBirthdate);
    
    let hasAge = userBirthdayYear !== null;
    args.model.set("hasAge", hasAge);

    args.model.set("saved", saved);
    args.model.set("isStaff", isStaff);

    const allowUserChangeBirthdate = isAdmin || isModerator || isStaff || args.model.siteSettings.cakeday_birthday_allowchange;

    let canChangeBirthdate = allowUserChangeBirthdate || args.model.custom_fields.admin_unlock_birthday || args.model.siteSettings.cakeday_birthday_allowchange || (userBirthdayDay === null || userBirthdayMonth === null || (userBirthdayYear === null && showYear));
    
    const ageControlVisibility = args.model.siteSettings.cakeday_min_age_controlvisibility;
    let canControlVisibility = ageControlVisibility && userAge(dateOfBirth) >= ageControlVisibility || args.model.staff;
    
    let showGroups = hasAge && showYear && canControlVisibility;

    args.model.set("ageControlVisibility", ageControlVisibility);
    args.model.set("canControlVisibility", canControlVisibility);

    component.setProperties({
      year,
      months,
      days,
      userBirthdayYear,
      userBirthdayMonth,
      userBirthdayDay,
      canChangeBirthdate,
      canControlVisibility,
      showGroups,
      allowUserChangeBirthdate,
      hasBirthdate,
      saved,
    });

    let groups_fullbirthday_visible

    const updateBirthday = function () {
      let date = "";

      if (component.userBirthdayYear && component.userBirthdayMonth && component.userBirthdayDay) {
        date = `${component.userBirthdayYear}-${component.userBirthdayMonth}-${component.userBirthdayDay}`;
        hasBirthdate = component.userBirthdayYear > 1904;
      }
      
      else if (component.userBirthdayMonth && component.userBirthdayDay && !showYear) {
        date = `1904-${component.userBirthdayMonth}-${component.userBirthdayDay}`;
        hasBirthdate = true;
      }
      else {
        hasBirthdate = false;
      }

      args.model.set("date_of_birth", date);
      hasAge = component.userBirthdayYear !== null;

      args.model.set("hasAge", hasAge);
      args.model.set("hasBirthdate", hasBirthdate);
      
      args.model.set("custom_fields.admin_unlock_birthday", false);
      
      canControlVisibility = hasBirthdate && (ageControlVisibility && userAge(date) >= ageControlVisibility || isStaff);
      
      args.model.set("canControlVisibility", canControlVisibility);
      saved = true;
      
      showGroups = hasAge && showYear && canControlVisibility;
      args.model.set("showGroups", showGroups);
    };

    Group.findAll().then((groups) => {
      this.set("TLandCustomGroups", groups.filter(function (g) {
    return g.id > 10}))});

    component.addObserver("userBirthdayYear", updateBirthday);
    component.addObserver("userBirthdayMonth", updateBirthday);
    component.addObserver("userBirthdayDay", updateBirthday);

    component.set("userBirthdateText", userBirthdateText(this.currentUser, showYear));
  },
};
