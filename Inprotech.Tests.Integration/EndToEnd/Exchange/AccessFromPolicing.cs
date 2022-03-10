using Inprotech.Infrastructure.Security;
using Inprotech.Tests.Integration.DbHelpers;
using Inprotech.Tests.Integration.EndToEnd.Policing.PageObjects;
using Inprotech.Tests.Integration.Extensions;
using Inprotech.Tests.Integration.Utils;
using NUnit.Framework;

namespace Inprotech.Tests.Integration.EndToEnd.Exchange
{
    [Category(Categories.E2E)]
    [TestFixture]
    public class AccessFromPolicing : IntegrationTest
    {
        TestUser _loginUser;

        [SetUp]
        public void CreatePoliceViewUser()
        {
            _loginUser = new Users()
                .WithPermission(ApplicationTask.ViewPolicingDashboard)
                .WithPermission(ApplicationTask.ExchangeIntegrationAdministration)
                .Create();
        }

        [TestCase(BrowserType.Chrome)]
        [TestCase(BrowserType.FireFox)]
        public void AccessExchangeLink(BrowserType browserType)
        {
            var driver = BrowserProvider.Get(browserType);
            SignIn(driver, "/#/policing-dashboard", _loginUser.Username, _loginUser.Password);

            var dashboardPage = new DashboardPageObject(driver);
            driver.WaitForAngular();

            var exchangeIntegrationLink = dashboardPage.ViewExchangeIntegration;

            Assert.IsNotNull(exchangeIntegrationLink, "Exchange Integration link is not visible.");

            driver.ClickLinkToNewBrowserWindow(exchangeIntegrationLink);

            var url = driver.WithJs().GetUrl();

            Assert.True(url.Contains("/exchange-requests"),
                        $"The link should take the user to Exchange Integration but was {url}");

        }
    }
}