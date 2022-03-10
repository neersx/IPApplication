using Inprotech.Tests.Integration.Extensions;
using Inprotech.Tests.Integration.PageObjects;
using Inprotech.Tests.Integration.PageObjects.Modals;
using Inprotech.Tests.Integration.Utils;
using OpenQA.Selenium;
using Protractor;

namespace Inprotech.Tests.Integration.EndToEnd.Configuration.General.Ede
{
   internal class EdeMappingDetailPage : DetailPage
    {
        DefaultsTopic _defaultsTopic;
        EventsTopic _eventsTopic;

        public DefaultsTopic DefaultsTopic => _defaultsTopic ?? (_defaultsTopic = new DefaultsTopic(Driver));

        public EdeMappingMaintenanceModalDialog GroupMaintenanceDialog { get; set; }

        public EdeMappingDetailPage(NgWebDriver driver) : base(driver)
        {
            GroupMaintenanceDialog = new EdeMappingMaintenanceModalDialog(driver);
        }

        public EventsTopic DocumentsTopic => _eventsTopic ?? (_eventsTopic = new EventsTopic(Driver));

        public class EdeMappingMaintenanceModalDialog : MaintenanceModal
        {
            public EdeMappingMaintenanceModalDialog(NgWebDriver driver) : base(driver)
            {
            }
        }
    }

   public class EventsTopic : Topic
    {
        const string TopicKey = "Events";

        public EventsTopic(NgWebDriver driver) : base(driver, TopicKey)
        {
        }

        public KendoGrid DocumentGrid(NgWebDriver driver)
        {
            return new KendoGrid(driver, "structureSearchResults");
        }
    }
   public class DefaultsTopic : Topic
    {
        const string TopicKey = "defaults";

        public Checkbox IgnoreCheckbox { get; set; }

        public DefaultsTopic(NgWebDriver driver) : base(driver, TopicKey)
        {
            EventPickList = new PickList(driver).ByName(string.Empty, "event");
            IgnoreCheckbox = new Checkbox(driver).ByLabel(".ignore");

        }

        public NgWebElement AddButton(NgWebDriver driver)
        {
            return driver.FindElement(By.CssSelector("[ng-click='vm.add()']"));
        }

        public NgWebElement DescriptionTextBox(NgWebDriver driver)
        {
            return driver.FindElement(By.Name("description")).FindElement(By.TagName("textarea"));
        }

        public PickList EventPickList { get; set; }

        public void SelectPageOnly(NgWebDriver driver)
        {
            driver.FindElement(By.Id("Events_selectpage")).WithJs().Click();
        }

        public void ClickOnBulkActionMenu(NgWebDriver driver)
        {
            ActionMenu.OpenOrClose();
        }

        ActionMenu _actionMenu;
        public ActionMenu ActionMenu => _actionMenu ?? (_actionMenu = new ActionMenu(Driver, "Events"));

        public void ClickOnSelectAll(NgWebDriver driver)
        {
            driver.FindElement(By.Name("selectall")).ClickWithTimeout();
        }

        public void ClickOnDuplicate(NgWebDriver driver)
        {
            driver.FindElement(By.Id("bulkaction_Events_duplicate")).WithJs().Click();
        }

        public void ClickOnEdit(NgWebDriver driver)
        {
            driver.FindElement(By.Id("bulkaction_Events_edit")).WithJs().Click();
        }

        public void ClickOnDelete(NgWebDriver driver)
        {
            driver.FindElement(By.Id("bulkaction_Events_delete")).WithJs().Click();
        }

        public NgWebElement SaveButton(NgWebDriver driver)
        {
            return driver.FindElement(By.Name("floppy-o"));
        }
    }
}
