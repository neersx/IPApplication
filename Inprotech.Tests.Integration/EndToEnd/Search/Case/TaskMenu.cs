using System.Linq;
using Inprotech.Tests.Integration.DbHelpers;
using Inprotech.Tests.Integration.EndToEnd.Portfolio.Cases;
using Inprotech.Tests.Integration.EndToEnd.Portfolio.Cases.Dms;
using Inprotech.Tests.Integration.EndToEnd.Search.Case.CaseSearch;
using Inprotech.Tests.Integration.Extensions;
using Inprotech.Tests.Integration.Utils;
using InprotechKaizen.Model.Cases;
using InprotechKaizen.Model.ValidCombinations;
using NUnit.Framework;
using OpenQA.Selenium;
using OpenQA.Selenium.Interactions;

namespace Inprotech.Tests.Integration.EndToEnd.Search.Case
{
    [Category(Categories.E2E)]
    [TestFixture]
    public class TaskMenu : IntegrationTest
    {
        string _irnPrefix = "tasks_case";
        InprotechKaizen.Model.Cases.Case _case;

        [SetUp]
        public void PrepareData()
        {
            DbSetup.Do(x =>
            {
                var caseBuilder = new CaseSearchCaseBuilder(x.DbContext);
                var data = caseBuilder.Build(_irnPrefix);
                x.DbContext.SaveChanges();
                _case = data.Case;
            });
        }

        [TestCase(BrowserType.Chrome)]
        [TestCase(BrowserType.FireFox)]
        [TestCase(BrowserType.Ie)]
        public void VerifyCaseWebLink(BrowserType browserType)
        {
            var driver = BrowserProvider.Get(browserType);
            Actions action = new Actions(driver);
            SignIn(driver, $"/#/search-result?queryContext=2&q={_irnPrefix}");

            var searchResultPageObject = new SearchPageObject(driver);
            Assert.IsFalse(searchResultPageObject.TaskMenuButton().IsDisabled());
            searchResultPageObject.TaskMenuButton().Click();

            driver.WaitForAngular();
            WaitHelper.Wait(1000);
            Assert.IsFalse(searchResultPageObject.CaseWebLinkTaskMenu.IsDisabled());
            action.MoveToElement(searchResultPageObject.CaseWebLinkTaskMenu).Perform();

            driver.WaitForAngular();
            Assert.IsFalse(searchResultPageObject.WebLinkGroupTaskMenu.IsDisabled());
            action.MoveToElement(searchResultPageObject.WebLinkGroupTaskMenu).Perform();

            driver.WaitForAngular();
            Assert.IsFalse(searchResultPageObject.WebLinkTaskMenu.IsDisabled());
            searchResultPageObject.WebLinkTaskMenu.Click();

            var browserTabs = driver.WindowHandles;
            Assert.AreEqual(2, browserTabs.Count);
        }

        [TestCase(BrowserType.Chrome)]
        [TestCase(BrowserType.FireFox)]
        [TestCase(BrowserType.Ie)]
        public void DisplayProgramsInTasksMenu(BrowserType browserType)
        {
            var driver = BrowserProvider.Get(browserType);
            Actions action = new Actions(driver);
            SignIn(driver, $"/#/search-result?queryContext=2&q={_irnPrefix}");

            var searchResultPageObject = new SearchPageObject(driver);
            Assert.IsFalse(searchResultPageObject.TaskMenuButton().IsDisabled());
            searchResultPageObject.TaskMenuButton().Click();

            driver.WaitForAngularWithTimeout();
            Assert.IsFalse(searchResultPageObject.OpenWithTaskMenu.IsDisabled());
            action.MoveToElement(searchResultPageObject.OpenWithTaskMenu).Perform();

            driver.WaitForAngularWithTimeout();
            Assert.IsFalse(searchResultPageObject.OpenWithCaseEnquiryTaskMenu.IsDisabled());
            searchResultPageObject.OpenWithCaseEnquiryTaskMenu.Click();
            driver.WaitForAngularWithTimeout();
            var caseViewPage = new NewCaseViewDetail(driver);
            Assert.True(caseViewPage.PageTitle().Contains(_case.Irn), "Expected the Case IRN to be in Page Title");
            Assert.True(caseViewPage.PageTitle().Contains("Case Enquiry"), "Expected selected program to be displayed");

            caseViewPage.LevelUpButton.ClickWithTimeout();
            driver.WaitForAngularWithTimeout();

            searchResultPageObject.ResultGrid.Cell(0, 2).FindElements(By.TagName("a"))?.First().ClickWithTimeout();
            Assert.True(caseViewPage.PageTitle().Contains(_case.Irn), "Expected the Case IRN to be in Page Title");
            Assert.True(caseViewPage.PageTitle().Contains("Case"), "Expected Default program to be displayed");
        }

        [TestCase(BrowserType.Chrome)]
        [TestCase(BrowserType.FireFox)]
        [TestCase(BrowserType.Ie)]
        public void VerifyDocumentManagementLink(BrowserType browserType)
        {
            var data = GetDocumentManagementData();
            var driver = BrowserProvider.Get(browserType);
            SignIn(driver, $"/#/search-result?queryContext=2&q={data.CasePrefix}");

            var searchResultPageObject = new SearchPageObject(driver);
            Assert.IsFalse(searchResultPageObject.TaskMenuButton().IsDisabled());
            searchResultPageObject.TaskMenuButton().Click();

            driver.WaitForAngular();
            WaitHelper.Wait(1000);
            Assert.IsFalse(searchResultPageObject.OpenDmsMenu.IsDisabled());
            searchResultPageObject.OpenDmsMenu.Click();
            var popup = new DocumentManagementPageObject(driver);

            Assert.AreEqual(data.CaseIrn, popup.IrnLabel.First().Text);
            Assert.AreEqual(data.Case.Type.Name, popup.CaseTypeLabel.First().Text);
        }

        dynamic GetDocumentManagementData()
        {
            var data = DbSetup.Do(setup =>
            {
                new DocumentManagementDbSetup().Setup();
                var status = new Status(Fixture.Short(), Fixture.String(10));
                var country = new Country(Fixture.String(3), Fixture.String(10), "1");

                var case1 = _case;
                var validProperty = new ValidProperty() {CountryId = country.Id, PropertyName = Fixture.String(10), PropertyTypeId = case1.PropertyTypeId};
                case1.CaseStatus = status;
                case1.Country = country;
                setup.DbContext.SaveChanges();
                return new
                {
                    CasePrefix = _irnPrefix,
                    CaseIrn = case1.Irn,
                    Case = case1,
                    Status = status,
                    Country = country,
                    ValidProperty = validProperty
                };
            });
            return data;
        }
    }
}