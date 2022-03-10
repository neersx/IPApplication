using Inprotech.Tests.Integration.PageObjects;
using OpenQA.Selenium;
using Protractor;

namespace Inprotech.Tests.Integration.EndToEnd.Picklists.Basis
{
    class ValidBasisDetailPage : DetailPage
    {
        ValidBasisDefaultsTopic _defaultsTopic;

        public ValidBasisDetailPage(NgWebDriver driver) : base(driver)
        {
        }

        public ValidBasisDefaultsTopic DefaultsTopic => _defaultsTopic ?? (_defaultsTopic = new ValidBasisDefaultsTopic(Driver));

        public string ActionName()
        {
            return Driver.FindElement(By.CssSelector(".title-header h2")).Text;
        }
    }

    public class ValidBasisDefaultsTopic : Topic
    {
        const string TopicKey = "defaults";

        public ValidBasisDefaultsTopic(NgWebDriver driver) : base(driver, TopicKey)
        {
        }

        public NgWebElement ValidDescription(NgWebDriver driver)
        {
            return driver.FindElement(By.Name("validDescription")).FindElement(By.TagName("input"));
        }
    }
}