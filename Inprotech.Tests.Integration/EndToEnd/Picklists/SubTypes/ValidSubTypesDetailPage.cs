using Inprotech.Tests.Integration.PageObjects;
using OpenQA.Selenium;
using Protractor;

namespace Inprotech.Tests.Integration.EndToEnd.Picklists.SubTypes
{
    class ValidSubTypesDetailPage : DetailPage
    {
        ValidSubTypesDefaultsTopic _defaultsTopic;

        public ValidSubTypesDetailPage(NgWebDriver driver) : base(driver)
        {
        }

        public ValidSubTypesDefaultsTopic DefaultsTopic => _defaultsTopic ?? (_defaultsTopic = new ValidSubTypesDefaultsTopic(Driver));

        public string ActionName()
        {
            return Driver.FindElement(By.CssSelector(".title-header h2")).Text;
        }
    }

    public class ValidSubTypesDefaultsTopic : Topic
    {
        const string TopicKey = "defaults";

        public ValidSubTypesDefaultsTopic(NgWebDriver driver) : base(driver, TopicKey)
        {
        }

        public NgWebElement ValidDescription(NgWebDriver driver)
        {
            return driver.FindElement(By.Name("validDescription")).FindElement(By.TagName("input"));
        }
    }
}
