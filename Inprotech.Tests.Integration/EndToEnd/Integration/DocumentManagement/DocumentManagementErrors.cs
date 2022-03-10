using Inprotech.Infrastructure.Security;
using Inprotech.Tests.Integration.DbHelpers;
using Inprotech.Tests.Integration.DbHelpers.Builders;
using Inprotech.Tests.Integration.EndToEnd.Portfolio.Cases.Dms;
using Inprotech.Tests.Integration.EndToEnd.Search.Case;
using Inprotech.Tests.Integration.Extensions;
using Inprotech.Tests.Integration.Utils;
using NUnit.Framework;
using OpenQA.Selenium;

namespace Inprotech.Tests.Integration.EndToEnd.Integration.DocumentManagement
{
    [Category(Categories.E2E)]
    [TestFixture]
    public class DocumentManagementErrors : IntegrationTest
    {
        static dynamic CreateCase()
        {
            return DbSetup.Do(x =>
            {
                var irnPrefix = "tasks_case";

                var c = new CaseBuilder(x.DbContext).Create(irnPrefix);

                return new
                {
                    CasePrefix = irnPrefix,
                    CaseIrn = c.Irn,
                    Case = c
                };
            });
        }

        [TestCase(BrowserType.Chrome)]
        [TestCase(BrowserType.FireFox)]
        [TestCase(BrowserType.Ie)]
        public void DoesNotShowErrorConfigSetUpCorrectly(BrowserType browserType)
        {
            var @case = CreateCase();
            new DocumentManagementDbSetup().Setup();
            var internalUser = new Users().WithPermission(ApplicationTask.AccessDocumentsfromDms).Create();
            var driver = BrowserProvider.Get(browserType);
            SignIn(driver, $"/#/search-result?queryContext=2&q={@case.CasePrefix}", internalUser.Username, internalUser.Password);

            var searchResultPageObject = new SearchPageObject(driver);
            searchResultPageObject.TaskMenuButton().Click();

            driver.WaitForAngular();
            WaitHelper.Wait(1000);
            Assert.IsFalse(searchResultPageObject.OpenDmsMenu.IsDisabled());
            searchResultPageObject.OpenDmsMenu.Click();
            driver.WaitForAngular();
            WaitHelper.Wait(1000);

            var documentManagementPage = new DocumentManagementPageObject(driver);
            Assert.True(documentManagementPage.Documents.Grid.WithJs().IsVisible(), "Grid should be displayed");
            Assert.IsNotEmpty(documentManagementPage.DirectoryTreeView.Folders, "Should have folders");
            Assert.Throws<NoSuchElementException>(() => documentManagementPage.ErrorMessage.Click());
        }

        [TestCase(BrowserType.Chrome)]
        [TestCase(BrowserType.FireFox)]
        [TestCase(BrowserType.Ie)]
        public void ShowsErrorIfNoConfig(BrowserType browserType)
        {
            var @case = CreateCase();
            var internalUser = new Users().WithPermission(ApplicationTask.AccessDocumentsfromDms).Create();
            var driver = BrowserProvider.Get(browserType);
            SignIn(driver, $"/#/search-result?queryContext=2&q={@case.CasePrefix}", internalUser.Username, internalUser.Password);

            var searchResultPageObject = new SearchPageObject(driver);
            searchResultPageObject.TaskMenuButton().Click();

            driver.WaitForAngular();
            WaitHelper.Wait(1000);
            Assert.IsFalse(searchResultPageObject.OpenDmsMenu.IsDisabled());
            searchResultPageObject.OpenDmsMenu.Click();
            driver.WaitForAngular();
            WaitHelper.Wait(1000);

            var documentManagementPage = new DocumentManagementPageObject(driver);
            Assert.Throws<NoSuchElementException>(() => documentManagementPage.Documents.Grid.Click());
            Assert.True(documentManagementPage.ErrorMessage.Displayed);
        }
    }
}