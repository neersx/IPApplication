using Inprotech.Tests.Integration.PageObjects;
using OpenQA.Selenium;
using Protractor;

namespace Inprotech.Tests.Integration.EndToEnd.Picklists.Action
{
    class ValidActionDetailPage : DetailPage
    {
        ValidActionDefaultsTopic _defaultsTopic;

        public ValidActionDetailPage(NgWebDriver driver) : base(driver)
        {
        }

        public ValidActionDefaultsTopic DefaultsTopic => _defaultsTopic ?? (_defaultsTopic = new ValidActionDefaultsTopic(Driver));

        public string ActionName()
        {
            return Driver.FindElement(By.CssSelector(".title-header h2")).Text;
        }
    }

    public class ValidActionDefaultsTopic : Topic
    {
        const string TopicKey = "defaults";

        public ValidActionDefaultsTopic(NgWebDriver driver) : base(driver, TopicKey)
        {
        }

        public NgWebElement ValidDescription(NgWebDriver driver)
        {
            return driver.FindElement(By.Name("validDescription")).FindElement(By.TagName("input"));
        }

        public NgWebElement ActionOrderWindow(NgWebDriver driver)
        {
            return driver.FindElement(By.Name("actionOrder"));
        }
    }
}