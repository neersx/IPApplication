using Inprotech.Tests.Integration.PageObjects;
using OpenQA.Selenium;
using OpenQA.Selenium.Support.UI;
using Protractor;

namespace Inprotech.Tests.Integration.EndToEnd.TaskPlanner
{
    public class TaskPlannerSearchBuilderPageObject : PageObject
    {
        public TaskPlannerSearchBuilderPageObject(NgWebDriver driver, NgWebElement container = null) : base(driver, container)
        {
        }

        public AngularCheckbox IncludeRemindersCheckbox => new AngularCheckbox(Driver).ByName("chkReminders");
        public AngularCheckbox IncludeDueDatesCheckbox => new AngularCheckbox(Driver).ByName("chkDueDates");        
        public AngularCheckbox IncludeAdHocDatesCheckbox => new AngularCheckbox(Driver).ByName("chkAdHocDates");
        public AngularCheckbox ActingAsReminderCheckbox => new AngularCheckbox(Driver).ByName("belongingToReminder");
        public AngularCheckbox ActingAsDueDateCheckbox => new AngularCheckbox(Driver).ByName("belongingToDueDate");
        public AngularDropdown BelongingToDropdown => new AngularDropdown(Driver).ByName("belongingTo");
        public AngularPicklist ActingAsNameTypePicklist => new AngularPicklist(Driver).ByName("nameKey");
        public AngularCheckbox SearchByReminderDateCheckbox => new AngularCheckbox(Driver).ByName("chkSearchByReminderDate");
        public AngularCheckbox SearchByDueDateCheckbox => new AngularCheckbox(Driver).ByName("chkSearchByDueDate");
        public NgWebElement DateRangeRadio => Driver.FindElement(By.CssSelector("ipx-radio-button[name='rdbRange'] input[type='radio']"));
        public NgWebElement DatePeriodRadio => Driver.FindElement(By.CssSelector("ipx-radio-button[name='rdbPeriod'] input[type='radio']"));
        public NgWebElement GetDateRangeStartDatePicker()
        {
            return DateRangeStartDatePicker.Element;
        }
        public NgWebElement GetDateRangeEndDatePicker()
        {
            return DateRangeEndDatePicker.Element;
        }
        public AngularDatePicker DateRangeStartDatePicker => new AngularDatePicker(Driver).ByName("dateRangeStart");
        public AngularDatePicker DateRangeEndDatePicker => new AngularDatePicker(Driver).ByName("dateRangeEnd");

        public DatePicker StartDate => new DatePicker(Driver, "dateRangeStart");
        public DatePicker EndDate => new DatePicker(Driver, "dateRangeEnd");

        public TextField DatePeriodFromTextbox => new TextField(Driver, "datePeriodFrom");
        public TextField DatePeriodToTextbox => new TextField(Driver, "datePeriodTo");
        public NgWebElement ClearButton => Driver.FindElement(By.CssSelector("ipx-clear-button button"));
        public NgWebElement SearchButton => Driver.FindElement(By.CssSelector("ipx-advanced-search-button button"));
        public NgWebElement RefreshButton => Driver.FindElement(By.Id("btnRefresh"));
        public NgWebElement BackButton => Driver.FindElement(By.CssSelector("ipx-level-up-button button"));
        public AngularDropdown CaseReferenceOperatorDropdown => new AngularDropdown(Driver,"ipx-dropdown-operator").ByName("caseReferenceOperator");
        public AngularDropdown OfficalNumberTypeDropdown => new AngularDropdown(Driver,"ipx-dropdown-operator").ByName("officalNumberType");
        public AngularDropdown OfficialNumberOperatorDropdown => new AngularDropdown(Driver,"ipx-dropdown-operator").ByName("officialNumberOperator");
        public AngularDropdown CaseFamilyOperatorDropdown => new AngularDropdown(Driver,"ipx-dropdown-operator").ByName("caseFamilyOperator");
        public AngularDropdown CaseListOperatorDropdown => new AngularDropdown(Driver,"ipx-dropdown-operator").ByName("caseListOperator");
        public AngularDropdown CaseOfficeOperatorDropdown => new AngularDropdown(Driver,"ipx-dropdown-operator").ByName("caseOfficeOperator");
        public AngularDropdown CaseTypeOperatorDropdown => new AngularDropdown(Driver,"ipx-dropdown-operator").ByName("caseTypeOperator");
        public AngularDropdown JurisdictionOperatorDropdown => new AngularDropdown(Driver,"ipx-dropdown-operator").ByName("jurisdictionOperator");
        public AngularDropdown PropertyTypeOperatorDropdown => new AngularDropdown(Driver,"ipx-dropdown-operator").ByName("propertyTypeOperator");
        public AngularDropdown CaseCategoryOperatorDropdown => new AngularDropdown(Driver,"ipx-dropdown-operator").ByName("caseCategoryOperator");
        public AngularDropdown SubTypeOperatorDropdown => new AngularDropdown(Driver,"ipx-dropdown-operator").ByName("subTypeOperator");
        public AngularDropdown BasisOperatorDropdown => new AngularDropdown(Driver,"ipx-dropdown-operator").ByName("basisOperator");
        public TextField CaseReferenceTextbox => new TextField(Driver, "caseReference");
        public AngularPicklist CaseRefCasesPicklist => new AngularPicklist(Driver).ByName("caseRefCases");
        public TextField OfficialNumberTextbox => new TextField(Driver, "OfficialNumber");
        public AngularPicklist CaseFamilyPicklist => new AngularPicklist(Driver).ByName("caseFamily");
        public AngularPicklist CaseListPicklist => new AngularPicklist(Driver).ByName("caseList");
        public AngularPicklist CaseOfficePicklist => new AngularPicklist(Driver).ByName("caseOffice");
        public AngularPicklist CaseTypePicklist => new AngularPicklist(Driver).ByName("caseType");
        public AngularPicklist CaseCategoryPicklist => new AngularPicklist(Driver).ByName("caseCategory");
        public AngularPicklist SubTypePicklist => new AngularPicklist(Driver).ByName("subType");
        public AngularDropdown InstructorOperatorDropdown => new AngularDropdown(Driver,"ipx-dropdown-operator").ByName("instructorOperator");
        public TextField InstructorTextbox => new TextField(Driver, "instructorText");
        public AngularPicklist InstructorNamesPicklist => new AngularPicklist(Driver).ByName("instructorNames");
        public AngularDropdown OwnerOperatorDropdown => new AngularDropdown(Driver,"ipx-dropdown-operator").ByName("ownerOperator");
        public TextField OwnerTextbox => new TextField(Driver, "ownerText");
        public AngularPicklist OwnerPicklist => new AngularPicklist(Driver).ByName("ownerNames");
        public AngularDropdown OtherNameTypeOperatorDropdown => new AngularDropdown(Driver,"ipx-dropdown-operator").ByName("otherNameTypesOperator");
        public TextField OtherNameTypesTextbox => new TextField(Driver, "otherNameTypesText");
        public AngularPicklist OtherNameTypesPicklist => new AngularPicklist(Driver).ByName("otherNameTypesNames");
        public AngularCheckbox PendingCheckbox => new AngularCheckbox(Driver).ByName("chkPending");
        public AngularCheckbox RegisteredCheckbox => new AngularCheckbox(Driver).ByName("chkRegistered");
        public AngularCheckbox DeadCheckbox => new AngularCheckbox(Driver).ByName("chkDead");
        public AngularDropdown CaseStatusOperatorDropdown => new AngularDropdown(Driver,"ipx-dropdown-operator").ByName("caseStatusOperator");
        public AngularPicklist CaseStatusPicklist => new AngularPicklist(Driver).ByName("caseStatus");
        public AngularDropdown RenewalStatusOperatorDropdown => new AngularDropdown(Driver,"ipx-dropdown-operator").ByName("renewalStatusOperator");
        public AngularPicklist RenewalStatusPicklist => new AngularPicklist(Driver).ByName("renewalStatus");
        public NgWebElement CaseReferencesSubHeading => Driver.FindElement(By.XPath("//h4[text()='References']"));
        public NgWebElement CaseDetailsSubHeading => Driver.FindElement(By.XPath("//h4[text()='Details']"));
        public NgWebElement CaseNamesSubHeading => Driver.FindElement(By.XPath("//h4[text()='Names']"));
        public NgWebElement CaseStatusSubHeading => Driver.FindElement(By.XPath("//h4[text()='Status']"));
        public AngularDropdown EventOperatorDropdown => new AngularDropdown(Driver,"ipx-dropdown-operator").ByName("eventOperator");
        public AngularPicklist EventPicklist => new AngularPicklist(Driver).ByName("event");
        public AngularDropdown EventCategoryOperatorDropdown => new AngularDropdown(Driver,"ipx-dropdown-operator").ByName("eventCategoryOperator");
        public AngularPicklist EventCategoryPicklist => new AngularPicklist(Driver).ByName("eventCategory");
        public AngularDropdown EventGroupOperatorDropdown => new AngularDropdown(Driver,"ipx-dropdown-operator").ByName("eventGroupOperator");
        public AngularPicklist EventGroupPicklist => new AngularPicklist(Driver).ByName("eventGroup");
        public AngularDropdown ActionOperatorDropdown => new AngularDropdown(Driver,"ipx-dropdown-operator").ByName("actionOperator");
        public AngularPicklist ActionPicklist => new AngularPicklist(Driver).ByName("action");
        public AngularDropdown EventNotesOperatorDropdown => new AngularDropdown(Driver,"ipx-dropdown-operator").ByName("eventNotesOperator");
        public TextField EventNotesTextbox => new TextField(Driver, "eventNotes");
        public AngularDropdown EventTypeOperatorDropdown => new AngularDropdown(Driver,"ipx-dropdown-operator").ByName("eventNoteTypeOperator");
        public AngularPicklist EventTypePicklist => new AngularPicklist(Driver).ByName("eventNoteType");
        public AngularCheckbox RenewalsCheckbox => new AngularCheckbox(Driver).ByName("chkRenewals");
        public AngularCheckbox NonRenewalsCheckbox => new AngularCheckbox(Driver).ByName("chkNonRenewals");
        public AngularCheckbox ClosedCheckbox => new AngularCheckbox(Driver).ByName("chkClosed");
        public AngularDropdown RemindersOperatorDropdown => new AngularDropdown(Driver,"ipx-dropdown-operator").ByName("reminderMessageOperator");
        public TextField ReminderMessageTextbox => new TextField(Driver, "reminderMessage");
        public AngularCheckbox OnHoldCheckbox => new AngularCheckbox(Driver).ByName("chkHold");
        public AngularCheckbox NotOnHoldCheckbox => new AngularCheckbox(Driver).ByName("chkNotOnHold");
        public AngularCheckbox ReadCheckbox => new AngularCheckbox(Driver).ByName("chkRead");
        public AngularCheckbox NotReadCheckbox => new AngularCheckbox(Driver).ByName("chkNotRead");
        public AngularDropdown AdhocDateNamesOperatorDropdown => new AngularDropdown(Driver,"ipx-dropdown-operator").ByName("adhocDateNamesOperator");
        public AngularPicklist AdhocDateNamesPicklist => new AngularPicklist(Driver).ByName("adhocDateNames");
        public AngularDropdown GeneralRefOperatorDropdown => new AngularDropdown(Driver,"ipx-dropdown-operator").ByName("adhocDateGeneralRefOperator");
        public TextField GeneralRefTextbox => new TextField(Driver, "adhocDateGeneralRef");
        public AngularDropdown AdhocDateMessageOperatorDropdown => new AngularDropdown(Driver,"ipx-dropdown-operator").ByName("adhocDateMessageOperator");
        public TextField AdhocDateMessageTextbox => new TextField(Driver, "adhocDateMessage");
        public AngularDropdown EmailSubjectOperatorDropdown => new AngularDropdown(Driver,"ipx-dropdown-operator").ByName("adhocDateEmailSubjectOperator");
        public TextField EmailSubjectTextbox => new TextField(Driver, "adhocDateEmailSubject");
        public AngularCheckbox AdhocDateIncludeCaseCheckbox => new AngularCheckbox(Driver).ByName("chkAdhocDateIncludeCase");
        public AngularCheckbox AdhocDateIncludeNameCheckbox => new AngularCheckbox(Driver).ByName("chkAdhocDateIncludeName");
        public AngularCheckbox AdhocDateIncludeGeneralCheckbox => new AngularCheckbox(Driver).ByName("chkAdhocDateIncludeGeneral");
        public AngularCheckbox AdhocDateIncludeFinalizedItemsCheckbox => new AngularCheckbox(Driver).ByName("chkIncludeFinalizedAdHocDates");

    }
}
