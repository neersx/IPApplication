using System.Linq;
using Inprotech.Tests.Integration.Extensions;
using Inprotech.Tests.Integration.PageObjects;
using OpenQA.Selenium;
using Protractor;

namespace Inprotech.Tests.Integration.EndToEnd.Configuration.General.PtoSettings.Epo
{
    public class EpoSettingsPageObject : DetailPage
    {
        readonly NgWebDriver _driver;

        public EpoSettingsPageObject(NgWebDriver driver) : base(driver)
        {
            _driver = driver;
        }

        public TextField ConsumerKey => new TextField(Driver, "consumerKey");

        public TextField PrivateKey => new TextField(Driver, "privateKey");

        public bool IsTestDone => _driver.FindElements(By.ClassName("cpa-icon")).Count > 0;

        public bool TestIsSuccessful => _driver.FindElements(By.ClassName("alert-success")).Count == 1;

        public bool TestIsUnSuccessful => _driver.FindElements(By.ClassName("alert-danger")).Count == 1;

        public void TestSettings()
        {
            
            var testButton = _driver.FindElements(By.CssSelector("button[ng-click='vm.verify()']")).Single();

            testButton.TryClick();
        }
    }
}
