using Inprotech.Infrastructure.Security;
using Inprotech.Tests.Integration.DbHelpers;
using Inprotech.Tests.Integration.Extensions;
using Inprotech.Tests.Integration.Utils;
using NUnit.Framework;
using MenuItemsPageObject = Inprotech.Tests.Integration.PageObjects.MenuItems;

namespace Inprotech.Tests.Integration.EndToEnd.Portal
{
    [Category(Categories.E2E)]
    [TestFixture]
    public class MenuItems : IntegrationTest
    {
        [SetUp]
        public void RemoveAllExistingLinks()
        {
        }

        [TestCase(BrowserType.Chrome)]
        [TestCase(BrowserType.FireFox)]
        [TestCase(BrowserType.Ie)]
        public void InternalUserMenu(BrowserType browserType)
        {
            var internalUser = new Users().WithPermission(ApplicationTask.NamesConsolidation)
                                          .WithPermission(ApplicationTask.ShowLinkstoWeb)
                                          .Create();

            var driver = BrowserProvider.Get(browserType);
            SignIn(driver, "/#/portal2", internalUser.Username, internalUser.Password);

            var menu = new MenuItemsPageObject(driver);
            menu.TogglElement.Click();

            var utilities = menu.Utilities;
            Assert.NotNull(utilities, "utility is shown");
            Assert.NotNull(menu.UtilitiesExpandIcon);
            utilities.GetParent().Click();
            menu = new MenuItemsPageObject(driver);
            var namesConsolidation = menu.NamesConsolidation;
            Assert.NotNull(namesConsolidation, "namesConsolidation is shown");
            Assert.NotNull(menu.Inprotech);
        }

        [TestCase(BrowserType.Chrome)]
        [TestCase(BrowserType.FireFox)]
        [TestCase(BrowserType.Ie)]
        public void ShowLinkToWeb(BrowserType browserType)
        {
            var driver = BrowserProvider.Get(browserType);
            var internalUser = new Users().WithPermission(ApplicationTask.ShowLinkstoWeb).Create();

            SignIn(driver, "/#/portal2", internalUser.Username, internalUser.Password);
            var menu = new MenuItemsPageObject(driver);
            menu.TogglElement.Click();
            Assert.NotNull(menu.Inprotech);
        }

        [TestCase(BrowserType.Chrome)]
        [TestCase(BrowserType.FireFox)]
        [TestCase(BrowserType.Ie)]
        public void HideLinkToWeb(BrowserType browserType)
        {
            var driver = BrowserProvider.Get(browserType);
            var internalUser = new Users().WithPermission(ApplicationTask.ShowLinkstoWeb, Deny.Execute).Create();
            SignIn(driver, "/#/portal2", internalUser.Username, internalUser.Password);

            var menu2 = new MenuItemsPageObject(driver);
            menu2.TogglElement.Click();
            Assert.Null(menu2.Inprotech);
        }
    }
}