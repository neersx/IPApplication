using Inprotech.Tests.Integration.PageObjects;
using OpenQA.Selenium;
using Protractor;

namespace Inprotech.Tests.Integration.EndToEnd.Configuration.General.ImportanceLevel
{
    class ImportanceLevelDetailPage : DetailPage
    {
        DefaultsTopic _defaultsTopic;
        public ImportanceLevelDetailPage(NgWebDriver driver) : base(driver)
        {
        }

        public DefaultsTopic DefaultsTopic => _defaultsTopic ?? (_defaultsTopic = new DefaultsTopic(Driver));

        public string ImportanceLevel()
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

        public NgWebElement AddNewImportanceLevelButton(NgWebDriver driver)
        {
            return driver.FindElement(By.Name("plus-circle"));
        }

        public NgWebElement Level(NgWebDriver driver)
        {
            return driver.FindElement(By.Name("level")).FindElement(By.TagName("input"));
        }

        public NgWebElement Description(NgWebDriver driver, string level)
        {
            return driver.FindElement(By.Id(level)).FindElement(By.TagName("input"));
        }

        public NgWebElement SaveButton(NgWebDriver driver)
        {
            return driver.FindElement(By.CssSelector(".btn-save"));
        }

        public NgWebElement RevertButton(NgWebDriver driver)
        {
            return driver.FindElement(By.CssSelector(".btn-warning"));
        }

        public NgWebElement DeleteButton(NgWebDriver driver, string level)
        {
            return driver.FindElement(By.XPath("//ip-text-field[@id='" + level + "']/parent::*/parent::*//ip-kendo-toggle-delete-button//button"));
        }
    }
}
