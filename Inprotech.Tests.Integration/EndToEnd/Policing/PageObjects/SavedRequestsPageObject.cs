using System;
using System.Linq;
using Inprotech.Tests.Integration.PageObjects;
using Inprotech.Tests.Integration.PageObjects.Modals;
using Inprotech.Tests.Integration.Utils;
using OpenQA.Selenium;
using OpenQA.Selenium.Support.Extensions;
using Protractor;

namespace Inprotech.Tests.Integration.EndToEnd.Policing.PageObjects
{
    internal class SavedRequestsPageObject : PageObject
    {
        public SavedRequestsPageObject(NgWebDriver driver) : base(driver)
        {
        }

        public NgWebElement LevelUpButton => Driver.FindElements(By.CssSelector("span[class*='cpa-icon-arrow-circle-nw'")).Last();

        public KendoGrid SavedRequestGrid => new KendoGrid(Driver, "savedRequestsGrid");

        public NgWebElement FirstTitleLink => SavedRequestGrid.RowElement(0, By.CssSelector("a"));

        public RequestMaintainanceModal MaintenanceModal => new RequestMaintainanceModal(Driver);

        public SavedRequestActionMenu ActionMenu => new SavedRequestActionMenu(Driver);

        public RunNowConfirmationModal RunNowConfirmationModal => new RunNowConfirmationModal(Driver);

        public NgWebElement Add()
        {
            return Driver.FindElement(By.Id("add"));
        }
    }

    public class SavedRequestActionMenu : ActionMenu
    {
        public SavedRequestActionMenu(NgWebDriver driver) : base(driver, "policingRequest")
        {
        }

        public NgWebElement DeleteOption()
        {
            return Option("delete");
        }

        public NgWebElement EditOption()
        {
            return Option("edit");
        }

        public NgWebElement RunNowOption()
        {
            return Option("runNow");
        }

        public NgWebElement DuplicateOption()
        {
            return Option("duplicate");
        }
    }

    internal class RequestMaintainanceModal : PageObject
    {
        public RequestMaintainanceModal(NgWebDriver driver) : base(driver)
        {
        }

        public bool IsSaveDisabled()
        {
            try
            {
                Driver.Wait().ForTrue(() => !Save.Enabled, sleepInterval: 12000);
                return true;
            }
            catch (Exception)
            {
                return false;
            }
        }

        NgWebElement Modal => Driver.Wait().ForVisible(By.CssSelector(".modal-dialog"));

        public ButtonInput RunNow => new ButtonInput(Driver).ById("affectedCases");

        public OptionFlags Options => new OptionFlags(Driver);

        public CaseAttributes Attributes => new CaseAttributes(Driver);

        public NgWebElement Save => Modal.FindElement(By.CssSelector(".btn-save"));

        public NgWebElement Discard => Modal.FindElement(By.CssSelector(".btn-discard"));

        public string AffectedCasesMessage => Modal.FindElement(By.CssSelector("span[translate='policing.request.maintenance.runRequest.affectedCases']")).Text;

        public NgWebElement Title()
        {
            return Modal.FindElement(By.Name("requestTitle"));
        }

        public NgWebElement Notes()
        {
            return Modal.FindElement(By.Name("requestNote"));
        }

        public DatePicker StartDate()
        {
            return new DatePicker(Driver, "startDate");
        }

        public DatePicker EndDate()
        {
            return new DatePicker(Driver, "endDate");
        }

        public DatePicker DateLetters()
        {
            return new DatePicker(Driver, "dateLetters");
        }

        public NgWebElement ForDays()
        {
            return Modal.FindElement(By.Name("forDays"));
        }

        public NgWebElement DueDateOnly()
        {
            return Modal.FindElement(By.Id("dueDateOnly"));
        }

        public string GetVisibleValidationTooltip()
        {
            return Driver.WrappedDriver.ExecuteJavaScript<string>("return $('.input-action.tooltip-error:visible').attr('uib-tooltip');");
        }

        public class OptionFlags
        {
            readonly NgWebDriver _driver;

            public OptionFlags(NgWebDriver driver)
            {
                _driver = driver;
            }

            public RadioButtonOrCheckbox Reminders => new RadioButtonOrCheckbox(_driver, "reminders");

            public RadioButtonOrCheckbox EmailReminders => new RadioButtonOrCheckbox(_driver, "emailReminders");

            public RadioButtonOrCheckbox Documents => new RadioButtonOrCheckbox(_driver, "optDocuments");

            public RadioButtonOrCheckbox Update => new RadioButtonOrCheckbox(_driver, "update");

            public RadioButtonOrCheckbox AdhocReminders => new RadioButtonOrCheckbox(_driver, "adhocReminders");

            public RadioButtonOrCheckbox RecalculateCriteria => new RadioButtonOrCheckbox(_driver, "recalculateCriteria");

            public RadioButtonOrCheckbox RecalculateDueDates => new RadioButtonOrCheckbox(_driver, "recalculateDueDates");

            public RadioButtonOrCheckbox RecalculateReminderDates => new RadioButtonOrCheckbox(_driver, "recalculateReminderDates");

            public RadioButtonOrCheckbox RecalculateEventDates => new RadioButtonOrCheckbox(_driver, "recalculateEventDates");
        }

        public class CaseAttributes
        {
            readonly NgWebDriver _driver;

            public CaseAttributes(NgWebDriver driver)
            {
                _driver = driver;
            }

            public PickList CaseReference => new PickList(_driver).ByName(string.Empty, "case");

            public PickList Jurisdiction => new PickList(_driver).ByName(string.Empty, "jurisdiction");

            public NgWebElement ExcludeJurisdiction => _driver.FindElements(By.Id("excludeJurisdiction")).FirstOrDefault();

            public PickList PropertyType => new PickList(_driver).ByName(string.Empty, "propertyType");

            public NgWebElement ExcludeProperty => _driver.FindElements(By.Id("excludeProperty")).FirstOrDefault();

            public PickList CaseType => new PickList(_driver).ByName(string.Empty, "caseType");

            public PickList CaseCategory => new PickList(_driver).ByName(string.Empty, "caseCategory");

            public PickList SubType => new PickList(_driver).ByName(string.Empty, "subType");

            public PickList Office => new PickList(_driver).ByName(string.Empty, "office");

            public PickList Action => new PickList(_driver).ByName(string.Empty, "action");

            public NgWebElement ExcludeAction => _driver.FindElements(By.Id("excludeAction")).FirstOrDefault();

            public PickList Event => new PickList(_driver).ByName(string.Empty, "event");

            public PickList Law => new PickList(_driver).ByName(string.Empty, "dateOfLaw");

            public PickList NameType => new PickList(_driver).ByName(string.Empty, "nameType");

            public PickList Name => new PickList(_driver).ByName(string.Empty, "name");
        }
    }

    internal class RunNowConfirmationModal : ModalBase
    {
        const string Id = "requestRunNowModal";

        public RunNowConfirmationModal(NgWebDriver driver) : base(driver, Id)
        {
        }

        public RadioButtonOrCheckbox RunTypeOneRequest => new RadioButtonOrCheckbox(Driver, "runType-oneRequest");

        public RadioButtonOrCheckbox RunTypeSeperateCases => new RadioButtonOrCheckbox(Driver, "runType-seperateCases");

        public NgWebElement Proceed()
        {
            return Modal.FindElement(By.CssSelector("button[translate='Proceed']"));
        }

        public NgWebElement Cancel()
        {
            return Modal.FindElement(By.CssSelector("button[translate='Cancel']"));
        }

        public NgWebElement StartDate()
        {
            return Driver.FindElement(By.Id("startDate"));
        }

        public NgWebElement UntilDate()
        {
            return Driver.FindElement(By.Id("endDate"));
        }

        public NgWebElement ForDays()
        {
            return Driver.FindElement(By.Id("forDays"));
        }

        public NgWebElement DateLetters()
        {
            return Driver.FindElement(By.Id("dateLetters"));
        }

        public void WaitForCasesToLoad()
        {
            Driver.Wait().ForVisible(By.CssSelector("div[translate='.affectedCases']"));
        }

        public bool RequestRunTypeVisible()
        {
            return Driver.FindElement(By.Id("runType-oneRequest")).Displayed;
        }
    }

    internal class AffectedCasesModal : ModalBase
    {
        const string Id = "affectedCasesModal";

        public AffectedCasesModal(NgWebDriver driver) : base(driver, Id)
        {
        }

        public ButtonInput Ok => new ButtonInput(Driver).ByCssSelector("button[translate='button.ok']");

        public string Message => Driver.FindElement(By.CssSelector("p[translate='policing.request.maintenance.affectedCases.message']")).Text;
    }
}