using Inprotech.Tests.Integration.PageObjects;
using Inprotech.Tests.Integration.Utils;
using OpenQA.Selenium;
using Protractor;

namespace Inprotech.Tests.Integration.EndToEnd.Configuration.General.Events.EventNoteTypes
{
    class EventNoteTypesDetailPage : DetailPage
    {
        DefaultsTopic _defaultsTopic;
        public EventNoteTypesDetailPage(NgWebDriver driver) : base(driver)
        {
        }

        public DefaultsTopic DefaultsTopic => _defaultsTopic ?? (_defaultsTopic = new DefaultsTopic(Driver));

        public string EventNoteTypes()
        {
            return Driver.FindElement(By.CssSelector(".title-header h2")).Text;
        }
    }

    public class DefaultsTopic : Topic
    {
        const string TopicKey = "defaults";

        public DefaultsTopic(NgWebDriver driver) : base(driver, TopicKey)
        {
        }

        public NgWebElement SearchEventNoteBox(NgWebDriver driver)
        {
            return driver.FindElement(By.CssSelector("ip-search-field input"));
        }

        public NgWebElement ClearButton(NgWebDriver driver)
        {
            return driver.FindElement(By.CssSelector("span.cpa-icon.cpa-icon-eraser"));
        }

        public NgWebElement SearchButton(NgWebDriver driver)
        {
            return driver.FindElement(By.CssSelector("ip-search-field span.cpa-icon.cpa-icon-search"));
        }

        public int GetSearchResultCount(NgWebDriver driver)
        {
            return driver.FindElements(By.CssSelector("#searchResults .k-master-row")).Count;
        }

        public NgWebElement AddButton(NgWebDriver driver)
        {
            return driver.FindElement(By.Id("add"));
        }

        public NgWebElement Description(NgWebDriver driver)
        {
            return driver.FindElement(By.Name("description")).FindElement(By.TagName("input"));
        }

        public NgWebElement SharingAllowedCheckbox(NgWebDriver driver)
        {
            return driver.FindElement(By.Name("sharingAllowed")).FindElement(By.TagName("input"));
        }

        public NgWebElement IsExternalCheckbox(NgWebDriver driver)
        {
            return driver.FindElement(By.Name("isExternal")).FindElement(By.TagName("input"));
        }

        public void ClickOnBulkActionMenu(NgWebDriver driver)
        {
            ActionMenu.OpenOrClose();
        }

        public void ClickOnDuplicate(NgWebDriver driver)
        {
            driver.FindElement(By.Id("bulkaction_eventnotetypes_duplicate")).WithJs().Click();
        }

        public void ClickOnSelectAll(NgWebDriver driver)
        {
            driver.FindElement(By.Name("selectall")).WithJs().Click();
        }

        public void ClickOnEdit(NgWebDriver driver)
        {
            driver.FindElement(By.Id("bulkaction_eventnotetypes_edit")).WithJs().Click();
        }

        public void ClickOnDelete(NgWebDriver driver)
        {
            driver.FindElement(By.Id("bulkaction_eventnotetypes_delete")).WithJs().Click();
        }

        ActionMenu _actionMenu;
        public ActionMenu ActionMenu => _actionMenu ?? (_actionMenu = new ActionMenu(Driver, "eventnotetypes"));
    }
}
