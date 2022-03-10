using System.Linq;
using NUnit.Framework;
using OpenQA.Selenium;

namespace Inprotech.Tests.Integration.EndToEnd.Portal
{
    [Category(Categories.E2E)]
    [TestFixture]
    public class PortalWidgetsTest : IntegrationTest
    {
        [TestCase(BrowserType.Chrome)]
        [TestCase(BrowserType.FireFox)]
        [TestCase(BrowserType.Ie)]
        public void WidgetsAreThereOnPortalPage(BrowserType browserType)
        {
            var driver = BrowserProvider.Get(browserType);
            SignIn(driver, "/#/portal2");

            var portalPage = new PortalPage(driver);
            Assert.IsTrue(portalPage.RecentCasesWidget.Grid.Rows.Count > 0, "Recent Cases widget must be there and it must list some cases");

            var firstRow = portalPage.RecentCasesWidget.Grid.Rows[0];
            Assert.IsTrue(firstRow.FindElements(By.TagName("a")).Any(), "There must be a link in the row");
        }
    }
}