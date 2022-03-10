using Inprotech.Tests.Integration.Extensions;
using Inprotech.Tests.Integration.PageObjects;
using Inprotech.Tests.Integration.PageObjects.Modals;
using Inprotech.Tests.Integration.Utils;
using InprotechKaizen.Model.Components.Integration.Exchange;
using NUnit.Framework;
using OpenQA.Selenium;
using Protractor;

namespace Inprotech.Tests.Integration.EndToEnd.Exchange
{
    [Category(Categories.E2E)]
    [TestFixture]
    class ExchangeQueue : IntegrationTest
    {
        [TestCase(BrowserType.Chrome)]
        [TestCase(BrowserType.Ie, Ignore = "Flaky Test")]
        [TestCase(BrowserType.FireFox)]
        public void ViewAndResetAndDeleteExchangeRequestQueue(BrowserType browserType)
        {
            ExchangeQueueDbSetup.ScenarioData scenario;
            using (var setup = new ExchangeQueueDbSetup())
            {
                scenario = setup.DataSetup();
            }

            var driver = BrowserProvider.Get(browserType);

            SignIn(driver, "/#/exchange-requests", scenario.User.Username, scenario.User.Password);

            var exchangeRequestList = new KendoGrid(driver, "exchangeRequestList");
            Assert.AreEqual(3, exchangeRequestList.Rows.Count,
                            "Ensure that exchange request list shows correct number of items");

            var bulkMenu = new ActionMenu(driver, "exchangeRequestListMenu");
            bulkMenu.OpenOrClose();
            bulkMenu.SelectAll();
            bulkMenu.Option("resetRequest").Click();

            Assert.AreEqual("Ready", exchangeRequestList.Cell(0, 8).Text);
            Assert.AreEqual("Ready", exchangeRequestList.Cell(1, 8).Text);
            Assert.AreEqual("Email Draft", exchangeRequestList.Cell(2, 2).Text);

            Assert.True(exchangeRequestList.Cell(0, 5).Text.Contains(scenario.ExchangeRequestQueueItem.Event.Description), "Ensure that Description shows correct value for 'Add' request type");
            Assert.True(exchangeRequestList.Cell(1, 5).Text.Contains(scenario.FailedExchangeRequestQueueItem.Event.Description), "Ensure that Description shows correct value for 'Add' request type");
            Assert.True(exchangeRequestList.Cell(2, 5).Text.Contains(scenario.DraftExchangeRequestQueueItem.Subject), "Ensure that Description shows correct value for 'Draft Email' request type");

            Assert.AreEqual(scenario.Settings.CharacterValue, exchangeRequestList.Cell(0, 6).Text, "Ensure that Mailbox shows correct value for 'Add' request type");
            Assert.AreEqual(scenario.Settings.CharacterValue, exchangeRequestList.Cell(1, 6).Text, "Ensure that Mailbox shows correct value for 'Add' request type");
            Assert.AreEqual(scenario.DraftExchangeRequestQueueItem.MailBox, exchangeRequestList.Cell(2, 6).Text, "Ensure that Mailbox shows correct value for 'Draft Email' request type");

            Assert.AreEqual(string.Empty, exchangeRequestList.Cell(0, 7).Text, "Ensure that Recipients shows empty value for 'Add' request type");
            Assert.AreEqual(string.Empty, exchangeRequestList.Cell(1, 7).Text, "Ensure that Recipients shows empty value for 'Add' request type");
            Assert.AreEqual(string.Join("; ", scenario.DraftExchangeRequestQueueItem.Recipients.Split(';')), exchangeRequestList.Cell(2, 7).Text, "Ensure that Recipients shows correct value for 'Draft Email' request type");

            bulkMenu.OpenOrClose();
            bulkMenu.SelectAll();
            bulkMenu.Option("delete").Click();

            var popups = new CommonPopups(driver);
            popups.ConfirmDeleteModal.Delete().ClickWithTimeout();

            Assert.AreEqual(0, exchangeRequestList.Rows.Count);
        }

        [TestCase(BrowserType.Chrome)]
        [TestCase(BrowserType.Ie, Ignore = "Flaky Test")]
        [TestCase(BrowserType.FireFox)]
        public void PagingIsAvailable(BrowserType browserType)
        {
            ExchangeQueueDbSetup.ScenarioData scenario;
            using (var setup = new ExchangeQueueDbSetup())
            {
                scenario = setup.DataSetup(true);
            }

            var driver = BrowserProvider.Get(browserType);

            SignIn(driver, "/#/exchange-requests", scenario.User.Username, scenario.User.Password);

            var exchangeRequestList = new KendoGrid(driver, "exchangeRequestList");
            exchangeRequestList.PageNext();
            Assert.AreEqual(3, exchangeRequestList.Rows.Count,
                            "Ensure that exchange request list pages to second page correctly.");

            exchangeRequestList.PagePrev();
            Assert.AreEqual(50, exchangeRequestList.Rows.Count,
                            "Ensure that exchange request list pages back to page one correctly.");

            exchangeRequestList.ChangePageSize(1);
            Assert.AreEqual(53, exchangeRequestList.Rows.Count,
                            "Ensure that exchange request list shows all items when page count changed to 100.");
        }
    }

    [Category(Categories.E2E)]
    [TestFixture]
    class ExchangeConfiguration : IntegrationTest
    {
        [TestCase(BrowserType.Chrome)]
        [TestCase(BrowserType.Ie)]
        [TestCase(BrowserType.FireFox)]
        public void ViewExchangeConfigation(BrowserType browserType)
        {
            ExchangeQueueDbSetup.ScenarioData scenario;
            using (var setup = new ExchangeQueueDbSetup())
            {
                scenario = setup.DataSetup();
            }

            var driver = BrowserProvider.Get(browserType);

            SignIn(driver, "/#/exchange-requests", scenario.User.Username, scenario.User.Password);

            var configureButton = driver.FindElement(By.Id("configure"));
            configureButton.Click();
            driver.WaitForAngular();
            var url = driver.WithJs().GetUrl();
            var user = driver.FindElement(By.Name("userName")).FindElement(By.TagName("input")).Value();
            var server = driver.FindElement(By.Name("server")).Value();
            var domain = driver.FindElement(By.Name("domain")).FindElement(By.TagName("input")).Value();
            var password = driver.FindElement(By.Name("password")).Value();

            Assert.True(url.Contains("exchange-configuration"),
                        $"Clicking on the Configure Settings link should take the user to the Exchange Integration page but was {url}");
            Assert.AreEqual(scenario.DefaultConfiguration.UserName, user,
                        "Ensure that the User ID is correctly displayed");
            Assert.AreEqual(scenario.DefaultConfiguration.Server, server,
                            "Ensure that the Server is correctly displayed");
            Assert.AreEqual(scenario.DefaultConfiguration.Domain, domain,
                            "Ensure that the Domain is correctly displayed");
            Assert.IsEmpty(password, "Password should never be displayed.");
        }

        [TestCase(BrowserType.Chrome)]
        [TestCase(BrowserType.Ie)]
        [TestCase(BrowserType.FireFox)]
        public void SaveExchangeConfiguration(BrowserType browserType)
        {
            ExchangeQueueDbSetup.ScenarioData scenario;
            using (var setup = new ExchangeQueueDbSetup())
            {
                scenario = setup.DataSetup();
            }

            var driver = BrowserProvider.Get(browserType);

            SignIn(driver, "/#/exchange-requests", scenario.User.Username, scenario.User.Password);

            var configureButton = driver.FindElement(By.Id("configure"));
            configureButton.Click();
            driver.WaitForAngular();

            var userInput = driver.FindElement(By.Name("userName")).FindElement(By.TagName("input"));
            userInput.Clear();
            userInput.SendKeys(scenario.NewConfiguration.UserName);
            var serverInput = driver.FindElement(By.Name("server"));
            serverInput.Clear();
            serverInput.SendKeys(Fixture.String(20));

            serverInput.Clear();
            serverInput.SendKeys(scenario.NewConfiguration.Server);

            var domainInput = driver.FindElement(By.Name("domain")).FindElement(By.TagName("input"));
            domainInput.Clear();
            domainInput.SendKeys(scenario.NewConfiguration.Domain);
            var passwordInput = driver.FindElement(By.Name("password"));
            passwordInput.Clear();
            passwordInput.SendKeys(scenario.NewConfiguration.Password);

            var saveButton = driver.FindElement(By.CssSelector(".btn-save"));
            saveButton.Click();

            var backToList = driver.FindElement(By.Id("configure"));
            backToList.Click();

            driver.FindElement(By.Id("configure")).Click();

            var user = driver.FindElement(By.Name("userName")).FindElement(By.TagName("input")).Value();
            var server = driver.FindElement(By.Name("server")).Value();
            var domain = driver.FindElement(By.Name("domain")).FindElement(By.TagName("input")).Value();
            var password = driver.FindElement(By.Name("password")).Value();

            Assert.AreEqual(scenario.NewConfiguration.UserName, user,
                            "Ensure that the User ID is correctly saved");
            Assert.AreEqual(scenario.NewConfiguration.Server, server,
                            "Ensure that the Server is correctly saved");
            Assert.AreEqual(scenario.NewConfiguration.Domain, domain,
                            "Ensure that the Domain is correctly saved");
            Assert.AreEqual(string.Empty, password,
                            "Ensure that the Password is correctly saved but not displayed");
        }

    }

    [Category(Categories.E2E)]
    [TestFixture] 
    [ChangeAppSettings(AppliesTo.InprotechServer, "BindingUrls", "http://*:80,https://*:443")]
    class ExchangeGraphConfiguration : IntegrationTest
    {
        [TestCase(BrowserType.Chrome)]
        [TestCase(BrowserType.Ie)]
        [TestCase(BrowserType.FireFox)]
        public void ViewExchangeConfiguration(BrowserType browserType)
        {
            ExchangeQueueDbSetup.ScenarioData scenario;
            using (var setup = new ExchangeQueueDbSetup())
            {
                scenario = setup.DataSetup(serviceType: "Graph");
            }

            var driver = BrowserProvider.Get(browserType);

            SignIn(driver, "/#/exchange-requests", scenario.User.Username, scenario.User.Password);

            var configureButton = driver.FindElement(By.Id("configure"));
            configureButton.Click();
            driver.WaitForAngular();
            var url = driver.WithJs().GetUrl();
            Assert.True(url.Contains("exchange-configuration"),
                        $"Clicking on the Configure Settings link should take the user to the Exchange Integration page but was {url}");
            AssertGraphConfigurationValues(driver, scenario.DefaultConfiguration);
            var redirectUri = driver.FindElement(By.Name("redirectUri")).FindElement(By.TagName("textarea")).Value();
            Assert.True(redirectUri.Contains("api/graph/auth/redirect"));
        }

        [TestCase(BrowserType.Chrome)]
        [TestCase(BrowserType.Ie)]
        [TestCase(BrowserType.FireFox)]
        public void SaveExchangeConfiguration(BrowserType browserType)
        {
            ExchangeQueueDbSetup.ScenarioData scenario;
            using (var setup = new ExchangeQueueDbSetup())
            {
                scenario = setup.DataSetup(serviceType: "Graph");
            }

            var driver = BrowserProvider.Get(browserType);

            SignIn(driver, "/#/exchange-requests", scenario.User.Username, scenario.User.Password);

            var configureButton = driver.FindElement(By.Id("configure"));
            configureButton.Click();
            driver.WaitForAngular();

            var tenantIdInput = driver.FindElement(By.Name("tenantId")).FindElement(By.TagName("input"));
            var clientIdInput = driver.FindElement(By.Name("clientId")).FindElement(By.TagName("input"));
            var clientSecretInput = driver.FindElement(By.Name("clientSecret"));
            tenantIdInput.Clear();
            tenantIdInput.SendKeys(scenario.NewConfiguration.ExchangeGraph.TenantId);
            clientIdInput.Clear();
            clientIdInput.SendKeys(scenario.NewConfiguration.ExchangeGraph.ClientId);
            clientSecretInput.Clear();
            clientSecretInput.SendKeys(scenario.NewConfiguration.ExchangeGraph.ClientSecret);

            var saveButton = driver.FindElement(By.CssSelector(".btn-save"));
            saveButton.Click();

            var backToList = driver.FindElement(By.Id("configure"));
            backToList.Click();

            driver.FindElement(By.Id("configure")).Click();
            AssertGraphConfigurationValues(driver, scenario.NewConfiguration);
        }

        void AssertGraphConfigurationValues(NgWebDriver driver, ExchangeConfigurationSettings settings)
        {
            var tenantId = driver.FindElement(By.Name("tenantId")).FindElement(By.TagName("input")).Value();
            var clientId = driver.FindElement(By.Name("clientId")).FindElement(By.TagName("input")).Value();
            var clientSecret = driver.FindElement(By.Name("clientSecret")).Value();

            Assert.AreEqual(settings.ExchangeGraph.TenantId, tenantId,
                            "Ensure that the Tenant Id is correctly displayed");
            Assert.AreEqual(settings.ExchangeGraph.ClientId, clientId,
                            "Ensure that the Client Id is correctly displayed");
            Assert.IsEmpty(clientSecret, "Client Secret should never be displayed.");

        }

    }
}
