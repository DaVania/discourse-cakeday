import Group from "discourse/models/group";
import {
  userAge,
  userBirthdateText,
} from "discourse/plugins/discourse-cakeday/discourse/lib/cakeday";

export default {
  setupComponent({ model }, component) {
    const { birthdate } = model;

    const defyear = 1904;

    const months = moment.months().map((month, index) => {
      return { name: month, value: index + 1 };
    });

    const days = [...Array(31).keys()].map((d) => (d + 1).toString());

    const year = birthdate
      ? (moment(birthdate, "YYYY-MM-DD").year() !== defyear ? moment(birthdate, "YYYY-MM-DD").year() : null)
      : null;

    const month = birthdate
      ? moment(birthdate, "YYYY-MM-DD").month() + 1
      : null;

    const day = birthdate
      ? moment(birthdate, "YYYY-MM-DD").date().toString()
      : null;
    
    const isStaff = this.currentUser.staff;
    const showYear = model.siteSettings.cakeday_birthday_show_year;

    let hasBirthdate = false;
    if (year && showYear)
      hasBirthdate = birthdate !== null && year !== null && year > defyear;
    else
      hasBirthdate = birthdate !== null;
    model.set("hasBirthdate", hasBirthdate);

    let hasAge = year !== null;

    if (model.custom_fields.show_birthday_to_be_celebrated === undefined)
    {
      model.set('custom_fields.show_birthday_to_be_celebrated', model.siteSettings.cakeday_birthday_celebrate);
    }

    const allowUserChangeBirthdate = isStaff || model.siteSettings.cakeday_birthday_allowchange;
    let canChangeBirthdate = allowUserChangeBirthdate || (day === null || month === null || (year === null && showYear));
    const ageControlVisibility = model.siteSettings.cakeday_min_age_controlvisibility;
    let canControlVisibility = ageControlVisibility && userAge(birthdate) >= ageControlVisibility || isStaff;
    
    let showGroups = hasAge && showYear && canControlVisibility;

    component.setProperties({
      year,
      months, month,
      days, day,
      canChangeBirthdate,
      canControlVisibility,
      showGroups,
      allowUserChangeBirthdate,
      hasAge,
      hasBirthdate,
    });
    component.setProperties('hasBirthdateSaved', hasBirthdate);

    const updateBirthdate = () => {
      let date = "";

      if (component.year && component.month && component.day && showYear) {
        date = `${component.year}-${component.month}-${component.day}`;
        hasBirthdate = component.year > 1904;
      }

      else if (component.month && component.day && !showYear) {
        date = `1904-${component.month}-${component.day}`;
        hasBirthdate = true;
      }

      else {
        hasBirthdate = false;
      }

      // The property that is being serialized when sending the update
      // request to the server is called `date_of_birth`
      model.set("date_of_birth", date);
      component.set("hasAge", component.year !== null && component.year > 1904);
      model.set("hasBirthdate", hasBirthdate);
      component.set("hasBirthdate", hasBirthdate);
      component.set("canControlVisibility", ageControlVisibility && userAge(date) >= ageControlVisibility || isStaff);;
    };

    Group.findAll().then((groups) => {
      this.set("TLandCustomGroups", groups.filter(function (g) {
    return g.id > 10}))});
    
    //needs an if siteSettings year required/available....
    //cakeday_birthday_show_year
    if (showYear) component.addObserver("year", updateBirthdate);
    component.addObserver("month", updateBirthdate);
    component.addObserver("day", updateBirthdate);
    component.set("userBirthdateText", userBirthdateText(this.currentUser, showYear));
  },
};
