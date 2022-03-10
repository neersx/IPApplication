using Inprotech.Tests.Integration.PageObjects;
using Inprotech.Tests.Integration.Utils;
using OpenQA.Selenium;
using Protractor;

namespace Inprotech.Tests.Integration.EndToEnd.Picklists.Action
{
    class ActionDetailPage : DetailPage
    {
        DefaultsTopic _defaultsTopic;

        public ActionDetailPage(NgWebDriver driver) : base(driver)
        {
        }

        public DefaultsTopic DefaultsTopic => _defaultsTopic ?? (_defaultsTopic = new DefaultsTopic(Driver));

        public string ActionName()
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

        public NgWebElement Code(NgWebDriver driver)
        {
            return driver.FindElement(By.Name("code")).FindElement(By.TagName("input"));
        }

        public NgWebElement Description(NgWebDriver driver)
        {
            return driver.FindElement(By.Name("value")).FindElement(By.TagName("input"));
        }

        public NgWebElement Cycles(NgWebDriver driver)
        {
            return driver.FindElement(By.Name("cycles"));
        }
        
        public DropDown ImportanceLevel => new DropDown(Driver, "ip-DropDown").ByName("importanceLevel");

        public NgWebElement UnlimitedCycles(NgWebDriver driver)
        {
            return driver.FindElement(By.Name("unlimitedCycles")).FindElement(By.TagName("input"));
        }

        public NgWebElement Renewal(NgWebDriver driver)
        {
            return driver.FindElement(By.Name("Renewal")).FindElement(By.TagName("input"));
        }

        public NgWebElement Examination(NgWebDriver driver)
        {
            return driver.FindElement(By.Name("Examination")).FindElement(By.TagName("input"));
        }

        public NgWebElement Other(NgWebDriver driver)
        {
            return driver.FindElement(By.Name("Other")).FindElement(By.TagName("input"));
        }
    }
}