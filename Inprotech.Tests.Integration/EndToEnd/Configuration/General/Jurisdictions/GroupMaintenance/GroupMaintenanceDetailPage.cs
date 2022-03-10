using Inprotech.Tests.Integration.PageObjects;
using Inprotech.Tests.Integration.PageObjects.Modals;
using Inprotech.Tests.Integration.Utils;
using OpenQA.Selenium;
using Protractor;

namespace Inprotech.Tests.Integration.EndToEnd.Configuration.General.Jurisdictions.GroupMaintenance
{
    internal class GroupMaintenanceDetailPage : DetailPage
    {
        GroupMembershipsTopic _groupMembershipsTopic;
        public GroupMaintenanceModalDialog GroupMaintenanceDialog { get; set; }

        public GroupMaintenanceDetailPage(NgWebDriver driver) : base(driver)
        {
            GroupMaintenanceDialog = new GroupMaintenanceModalDialog(driver);
        }

        public GroupMembershipsTopic GroupMembershipsTopic => _groupMembershipsTopic ?? (_groupMembershipsTopic = new GroupMembershipsTopic(Driver));

        public string GroupMaintenance()
        {
            return Driver.FindElement(By.CssSelector(".title-header h2")).Text;
        }

        public class GroupMaintenanceModalDialog : MaintenanceModal
        {
            public GroupMaintenanceModalDialog(NgWebDriver driver) : base(driver)
            {
            }
        }
    }

    public class GroupMembershipsTopic : Topic
    {
        const string TopicKey = "groups";

        public GroupMembershipsTopic(NgWebDriver driver) : base(driver, TopicKey)
        {
            Grid = new KendoGrid(Driver, "groupMembers");
        }

        public KendoGrid Grid { get; }

        public NgWebElement SearchTextBox(NgWebDriver driver)
        {
            return driver.FindElement(By.Id("search-options-criteria"));
        }

        public NgWebElement SearchButton(NgWebDriver driver)
        {
            return driver.FindElement(By.Id("search-options-search-btn"));
        }
        
        public void LevelUp()
        {
            Driver.FindElement(By.CssSelector("ip-sticky-header div.page-title ip-level-up-button span")).Click();
        }

        public NgWebElement DateJoinedGroupTextBox(NgWebDriver driver)
        {
            return driver.FindElement(By.Name("datejoinedgroup")).FindElement(By.TagName("input"));
        }

        public NgWebElement DateLeftGroupTextBox(NgWebDriver driver)
        {
            return driver.FindElement(By.Name("dateleftgroup")).FindElement(By.TagName("input"));
        }

        public NgWebElement DateBecameFullMemberTextBox(NgWebDriver driver)
        {
            return driver.FindElement(By.Name("datefullmember")).FindElement(By.TagName("input"));
        }

        public NgWebElement DateBecameAssociateMemberTextBox(NgWebDriver driver)
        {
            return driver.FindElement(By.Name("dateassociatemember")).FindElement(By.TagName("input"));
        }

        public NgWebElement DefaultSelectionCheckBox(NgWebDriver driver)
        {
            return driver.FindElement(By.Name("defaultSelection")).FindElement(By.TagName("input"));
        }

        public NgWebElement PreventEntryCheckBox(NgWebDriver driver)
        {
            return driver.FindElement(By.Name("preventEntry")).FindElement(By.TagName("input"));
        }

        public NgWebElement AllMembersIncludeCheckBox(NgWebDriver driver)
        {
            return driver.FindElement(By.Name("allMembersFlag")).FindElement(By.TagName("input"));
        }

        public NgWebElement AssociateMemberCheckBox(NgWebDriver driver)
        {
            return driver.FindElement(By.Name("associateMember")).FindElement(By.TagName("input"));
        }

        public NgWebElement AddAnotherCheckBox(NgWebDriver driver)
        {
            return driver.FindElement(By.CssSelector("[ng-model='vm.isAddAnother']")).FindElement(By.TagName("input"));
        }

        public NgWebElement ApplyButton(NgWebDriver driver)
        {
            return driver.FindElement(By.Name("check"));
        }

        public void BulkMenu(NgWebDriver driver)
        {
            driver.FindElement(By.Name("list-ul")).Click();
        }

        public void SelectPageOnly(NgWebDriver driver)
        {
            driver.FindElement(By.Id("jurisdictionMenu_selectpage")).WithJs().Click();
        }

        public void EditButton(NgWebDriver driver)
        {
            driver.FindElement(By.Id("bulkaction_jurisdictionMenu_edit")).WithJs().Click();
        }
        public NgWebElement SaveButton(NgWebDriver driver)
        {
            return driver.FindElement(By.Name("floppy-o"));
        }

        public void BackToSearch(NgWebDriver driver)
        {
            driver.FindElement(By.CssSelector("ip-sticky-header div.page-title ip-level-up-button span")).Click();
        }
    }
    
}

