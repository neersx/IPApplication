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
    public class NamesGridTest : IntegrationTest
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
        }
    }
}