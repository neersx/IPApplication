using Inprotech.Tests.Integration.PageObjects;
using Inprotech.Tests.Integration.Utils;
using OpenQA.Selenium;
using Protractor;

namespace Inprotech.Tests.Integration.EndToEnd.Configuration.General.TextType
{
    class TextTypesDetailPage : DetailPage
    {
        DefaultsTopic _defaultsTopic;
        public TextTypesDetailPage(NgWebDriver driver) : base(driver)
        {
        }

        public DefaultsTopic DefaultsTopic => _defaultsTopic ?? (_defaultsTopic = new DefaultsTopic(Driver));

        public string TextTypes()
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
        public void ClickOnSelectAll(NgWebDriver driver)
        {
            driver.FindElement(By.Name("selectall")).WithJs().Click();
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
            return driver.FindElement(By.Name("textTypeCode")).FindElement(By.TagName("input"));
        }

        public NgWebElement Description(NgWebDriver driver)
        {
            return driver.FindElement(By.Name("description")).FindElement(By.TagName("input"));
        }

        public NgWebElement CasesRadioButton(NgWebDriver driver)
        {
            return driver.FindElement(By.Name("usedByCases")).FindElement(By.TagName("input"));
        }

        public NgWebElement NamesRadioButton(NgWebDriver driver)
        {
            return driver.FindElement(By.Name("usedByNames")).FindElement(By.TagName("input"));
        }

        public NgWebElement EmployeeCheckbox(NgWebDriver driver)
        {
            return driver.FindElement(By.Name("usedByEmployee")).FindElement(By.TagName("input"));
        }

        public NgWebElement IndividualCheckbox(NgWebDriver driver)
        {
            return driver.FindElement(By.Name("usedByIndividual")).FindElement(By.TagName("input"));
        }

        public NgWebElement OrganisationCheckbox(NgWebDriver driver)
        {
            return driver.FindElement(By.Name("usedByOrganisation")).FindElement(By.TagName("input"));
        }

        public void ClickOnBulkActionMenu(NgWebDriver driver)
        {
            ActionMenu.OpenOrClose();
        }

        public void ClickOnDuplicate(NgWebDriver driver)
        {
            driver.FindElement(By.Id("bulkaction_texttypes_duplicate")).WithJs().Click();
        }

        public void ClickOnEdit(NgWebDriver driver)
        {
            driver.FindElement(By.Id("bulkaction_texttypes_edit")).WithJs().Click();
        }

        public void ClickOnDelete(NgWebDriver driver)
        {
            driver.FindElement(By.Id("bulkaction_texttypes_delete")).WithJs().Click();
        }
        public NgWebElement ChangeTextTypeCode(NgWebDriver driver)
        {
            return driver.FindElement(By.Id("bulkaction_texttypes_changeTextTypeCode"));
        }
        public NgWebElement NewTextTypeCode(NgWebDriver driver)
        {
            return driver.FindElement(By.Name("newTextTypeCode")).FindElement(By.TagName("input"));
        }

        ActionMenu _actionMenu;
        public ActionMenu ActionMenu => _actionMenu ?? (_actionMenu = new ActionMenu(Driver, "texttypes"));
    }
}
