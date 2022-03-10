using Inprotech.Tests.Integration.PageObjects;
using OpenQA.Selenium;
using OpenQA.Selenium.Support.UI;
using Protractor;

namespace Inprotech.Tests.Integration.EndToEnd.Picklists.Events
{
    public class EventPicklistModal : DetailPage
    {
        public EventPicklistModal(NgWebDriver driver) : base(driver)
        {
        }

        public NgWebElement EventDescription => Modal.FindElement(By.CssSelector("[name=description] input"));

        public Checkbox UnlimitedCycles => new Checkbox(Driver).ByLabel("picklist.event.maintenance.unlimited");
        public SelectElement InternalImportance => new SelectElement(Driver.FindElement(By.Name("internalImportance")));
        public SelectElement ClientImportance => new SelectElement(Driver.FindElement(By.Name("clientImportance")));
        public Checkbox RecalcEventDate => new Checkbox(Driver).ByLabel("picklist.event.maintenance.allowDateRecalc");
        public Checkbox SuppressDueDateCalc => new Checkbox(Driver).ByLabel("picklist.event.maintenance.suppressDueDateCalc");
        public NgWebElement EventNotes => Driver.FindElement(By.Name("notes")).FindElement(By.TagName("textarea"));
        public NgWebElement EventNumber => Driver.FindElement(By.Name("eventNumber"));
        public NgWebElement EventCode => Driver.FindElement(By.Name("code")).FindElement(By.TagName("input"));
        public PickList DraftEventPicklist => new PickList(Driver).ByName(string.Empty, "draftCaseEvent");
        public PickList EventGroup => new PickList(Driver).ByName("ip-picklist-modal-maintenance", "eventGroup");
        public PickList EventNoteGroup => new PickList(Driver).ByName("ip-picklist-modal-maintenance", "notesGroup");
    }
}
