using System;
using System.Linq;
using Inprotech.Tests.Integration.Extensions;
using Inprotech.Tests.Integration.PageObjects;
using NUnit.Framework;
using OpenQA.Selenium;

namespace Inprotech.Tests.Integration.EndToEnd.Components
{
    [Category(Categories.E2E)]
    [TestFixture]
    public class QuickSearchTextboxTest : IntegrationTest
    {
        [TestCase(BrowserType.Chrome)]
        [TestCase(BrowserType.Ie)]
        [TestCase(BrowserType.FireFox)]
        public void QuickSearchDisplayCorrectResults(BrowserType browserType)
        {
            var setup = new QuickSearchDbSetup().Setup();

            var driver = BrowserProvider.Get(browserType);
            SignIn(driver, "/#");

            var quickSearch = new QuickSearchControl(driver);
            
            quickSearch.Input.SendKeys(setup.SearchBy);
            Assert.IsNotNull(quickSearch.Picklist, "typing should open the picklist");

            var items = quickSearch.Picklist.Items;

            Assert.AreEqual(setup.Irns.Count, items.Count);

            foreach (var irn in setup.Irns)
                Assert.IsTrue(items.Any(x => x.Irn == irn));

            quickSearch.Input.SendKeys(Keys.Down);
            Assert.IsTrue(items[0].IsHighlighted, "highlighting should be changeable by key up/down");
            
            var selectedIrn = items[0].Irn;

            quickSearch.Input.SendKeys(Keys.Tab);
            Assert.IsNull(quickSearch.Picklist, "tab key should populate the textbox with list item");
            Assert.AreEqual(selectedIrn, quickSearch.Input.Value(), "tab key should not change content of the texbox");

            quickSearch.Input.SendKeys(Keys.Enter);
            Assert.IsNull(quickSearch.Picklist, "enter key should close the picklist");
            Assert.IsTrue(driver.Url.IndexOf("caseview", StringComparison.InvariantCultureIgnoreCase) > 0, "Navigates to case view");

            var title = driver.FindElement(By.CssSelector("ipx-sticky-header ipx-page-title div.page-title span.ipx-page-subtitle")).Text;
            Assert.True(title.IndexOf(selectedIrn, StringComparison.InvariantCultureIgnoreCase) > 0);
        }

        [TestCase(BrowserType.Chrome)]
        [TestCase(BrowserType.Ie)]
        [TestCase(BrowserType.FireFox)]
        public void QuickSearchNavigateToCaseOnEnterWhenOnlyOneResult(BrowserType browserType)
        {
            var setup = new QuickSearchDbSetup().SetupSingleResult();

            var driver = BrowserProvider.Get(browserType);
            SignIn(driver, "/#/configuration/rules/workflows");

            var quickSearch = new QuickSearchControl(driver);
            
            quickSearch.Input.SendKeys(setup.SearchBy);
            driver.WaitForAngularWithTimeout();
            Assert.IsNotNull(quickSearch.Picklist, "typing should open the picklist");

            var items = quickSearch.Picklist.Items;
            var selected = items[0].Irn;

            Assert.AreEqual(setup.Irns.Count, items.Count);

            foreach (var irn in setup.Irns)
                Assert.IsTrue(items.Any(x => x.Irn == irn));
            
            quickSearch.Input.SendKeys(Keys.Enter);
            Assert.IsNull(quickSearch.Picklist, "enter key should close the picklist");
            Assert.IsTrue(driver.Url.IndexOf("caseview", StringComparison.InvariantCultureIgnoreCase) > 0, "Navigates to case view");
            
            driver.WaitForAngularWithTimeout();
            var title = driver.FindElement(By.CssSelector("ipx-sticky-header ipx-page-title div.page-title span.ipx-page-subtitle")).Text;
            Assert.True(title.IndexOf(selected, StringComparison.InvariantCultureIgnoreCase) > 0);
        }
    }
}