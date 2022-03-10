using Inprotech.Tests.Integration.PageObjects;
using OpenQA.Selenium;
using Protractor;

namespace Inprotech.Tests.Integration.EndToEnd.Picklists.PropertyType
{
    class ValidPropertyTypeDetailPage : DetailPage
    {
        ValidPropertyTypeDefaultsTopic _defaultsTopic;

        public ValidPropertyTypeDetailPage(NgWebDriver driver) : base(driver)
        {
        }

        public ValidPropertyTypeDefaultsTopic DefaultsTopic => _defaultsTopic ?? (_defaultsTopic = new ValidPropertyTypeDefaultsTopic(Driver));

        public string ActionName()
        {
            return Driver.FindElement(By.CssSelector(".title-header h2")).Text;
        }
    }

    public class ValidPropertyTypeDefaultsTopic : Topic
    {
        const string TopicKey = "defaults";

        public ValidPropertyTypeDefaultsTopic(NgWebDriver driver) : base(driver, TopicKey)
        {
        }

        public NgWebElement ValidDescription(NgWebDriver driver)
        {
            return driver.FindElement(By.Name("validDescription")).FindElement(By.TagName("input"));
        }

        public NgWebElement AnnuityOffset(NgWebDriver driver)
        {
            return driver.FindElement(By.Name("annuityOffset")).FindElement(By.TagName("input"));
        }

        public NgWebElement AnnuityCycleOffset(NgWebDriver driver)
        {
            return driver.FindElement(By.Name("annuityCycleOffset")).FindElement(By.TagName("input"));
        }

        public NgWebElement AnnuityCycleOffsetRadioButton(NgWebDriver driver)
        {
            return driver.FindElement(By.Name("rbAnnuityCycleOffset")).FindElement(By.TagName("label"));
        }
    }
}