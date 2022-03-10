using Inprotech.Tests.Integration.Utils;
using NUnit.Framework;
using OpenQA.Selenium;

namespace Inprotech.Tests.Integration.EndToEnd.Exchange
{
    [Category(Categories.E2E)]
    [TestFixture]
    [ChangeAppSettings(AppliesTo.InprotechServer, "GraphApiUrl", "http://localhost/e2e/exchange/configuration/test/")]
    [ChangeAppSettings(AppliesTo.IntegrationServer, "GraphApiUrl", "http://localhost/e2e/exchange/configuration/test/")]
    public class ExchangeTestConnection : IntegrationTest
    {
        [TestCase(BrowserType.Chrome)]
        [TestCase(BrowserType.Ie)]
        [TestCase(BrowserType.FireFox)]
        public void TestConnection(BrowserType browserType)
        {
            ExchangeQueueDbSetup.ScenarioData scenario;
            using (var setup = new ExchangeQueueDbSetup())
            {
                scenario = setup.DataSetup(serviceType: "Graph");
            }

            var driver = BrowserProvider.Get(browserType);

            SignIn(driver, "/#/exchange-configuration", scenario.User.Username, scenario.User.Password);

            var clientSecretInput = driver.FindElement(By.Name("clientSecret"));
            clientSecretInput.Clear();
            clientSecretInput.SendKeys(Fixture.AlphaNumericString(10));

            var saveButton = driver.FindElement(By.CssSelector(".btn-save"));
            saveButton.Click();
            driver.WaitForBlockUi();
            var testConnectionButton = driver.FindElement(By.Id("testConnection"));
            testConnectionButton.WithJs().Click();
            driver.WaitForAngular();
            Assert.True(driver.FindElement(By.XPath("//span[text()='Successfully verified access to Exchange Server mailboxes.']")).Displayed, "Ensure that test connection succeed.");
        }
    }
}
