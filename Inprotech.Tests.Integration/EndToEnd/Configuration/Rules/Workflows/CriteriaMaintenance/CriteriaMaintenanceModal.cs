using Inprotech.Tests.Integration.PageObjects;
using Inprotech.Tests.Integration.Utils;
using OpenQA.Selenium;
using Protractor;

namespace Inprotech.Tests.Integration.EndToEnd.Configuration.Rules.Workflows.CriteriaMaintenance
{
    internal class CriteriaMaintenanceModal : WorkflowCharacteristicsPage
    {
        const string PickListConatiner = "div.modal-dialog";

        public CriteriaMaintenanceModal(NgWebDriver driver) : base(driver, PickListConatiner)
        {
        }

        public NgWebElement Modal => Driver.Wait().ForVisible(By.CssSelector(".modal-dialog"));

        public TextInput CriteriaName => new TextInput(Driver).ById("workflow-criteria-name");
        
        public ButtonInput Save => new ButtonInput(Driver).ById("Save");
        
        public RadioButtonOrCheckbox ProtectCriteriaYes => new RadioButtonOrCheckbox(Driver, "protect-yes");

        public RadioButtonOrCheckbox ProtectCriteriaNo => new RadioButtonOrCheckbox(Driver, "protect-no");

        public RadioButtonOrCheckbox InUseYes => new RadioButtonOrCheckbox(Driver, "inUse-yes");

        public RadioButtonOrCheckbox InUseNo => new RadioButtonOrCheckbox(Driver, "inUse-no");
    }
}