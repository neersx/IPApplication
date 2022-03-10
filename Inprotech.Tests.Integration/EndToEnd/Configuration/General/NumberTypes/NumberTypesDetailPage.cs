using Inprotech.Tests.Integration.PageObjects;
using Inprotech.Tests.Integration.Utils;
using OpenQA.Selenium;
using Protractor;

namespace Inprotech.Tests.Integration.EndToEnd.Configuration.General.NumberTypes
{
    class NumberTypesDetailPage : DetailPage
    {
        DefaultsTopic _defaultsTopic;
        public NumberTypesDetailPage(NgWebDriver driver) : base(driver)
        {
        }

        public DefaultsTopic DefaultsTopic => _defaultsTopic ?? (_defaultsTopic = new DefaultsTopic(Driver));

        public string NumberTypes()
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

        public NgWebElement SearchTextBox(NgWebDriver driver)
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

        public NgWebElement Code(NgWebDriver driver)
        {
            return driver.FindElement(By.Name("numberTypeCode")).FindElement(By.TagName("input"));
        }

        public NgWebElement Description(NgWebDriver driver)
        {
            return driver.FindElement(By.Name("name")).FindElement(By.TagName("input"));
        }

        public NgWebElement IssuedByIpOfficeCheckbox(NgWebDriver driver)
        {
            return driver.FindElement(By.Name("issuedByIpOffice")).FindElement(By.TagName("input"));
        }

        public NgWebElement RelatedEventPicklist(NgWebDriver driver)
        {
            return driver.FindElement(By.Name("relatedEvent")).FindElement(By.TagName("input"));
        }

        public NgWebElement DataItemPicklist(NgWebDriver driver)
        {
            return driver.FindElement(By.Name("dataItem")).FindElement(By.TagName("input"));
        }

        public void ClickOnBulkActionMenu(NgWebDriver driver)
        {
            ActionMenu.OpenOrClose();
        }

        public void ClickOnSelectAll(NgWebDriver driver)
        {
            driver.FindElement(By.Name("selectall")).WithJs().Click();
        }

        public void ClickOnDelete(NgWebDriver driver)
        {
            driver.FindElement(By.Id("bulkaction_numbertypes_delete")).WithJs().Click();
        }

        public void ClickOnEdit(NgWebDriver driver)
        {
            driver.FindElement(By.Id("bulkaction_numbertypes_edit")).WithJs().Click();
        }

        public void ClickOnDuplicate(NgWebDriver driver)
        {
            driver.FindElement(By.Id("bulkaction_numbertypes_duplicate")).WithJs().Click();
        }

        public NgWebElement ChangeNumberTypeCode(NgWebDriver driver)
        {
            return driver.FindElement(By.Id("bulkaction_numbertypes_changeNumberTypeCode"));
        }

        public NgWebElement NavigationBar(NgWebDriver driver)
        {
            return driver.FindElement(By.TagName("ip-nav-modal"));
        }

        public NgWebElement SetNumberTypePriorityLink(NgWebDriver driver)
        {
            return driver.FindElement(By.Id("numbertype-priority-link"));
        }

        public NgWebElement SetNumberTypePriorityButtonUp(NgWebDriver driver)
        {
            return driver.FindElement(By.Id("btnUp"));
        }

        public NgWebElement SetNumberTypePriorityButtonDown(NgWebDriver driver)
        {
            return driver.FindElement(By.Id("btnDown"));
        }

        public NgWebElement NewNumberTypeCode(NgWebDriver driver)
        {
            return driver.FindElement(By.Name("newNumberTypeCode")).FindElement(By.TagName("input"));
        }

        ActionMenu _actionMenu;
        public ActionMenu ActionMenu => _actionMenu ?? (_actionMenu = new ActionMenu(Driver, "numbertypes"));
    }
}
