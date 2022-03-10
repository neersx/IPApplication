using Inprotech.Infrastructure;
using Inprotech.Infrastructure.Security;
using Inprotech.Tests.Integration.DbHelpers;
using Inprotech.Tests.Integration.Extensions;
using Inprotech.Tests.Integration.PageObjects;
using Inprotech.Tests.Integration.PageObjects.Modals;
using Inprotech.Tests.Integration.Utils;
using NUnit.Framework;
using OpenQA.Selenium;
using Protractor;
using RCIndex = Inprotech.Tests.Integration.EndToEnd.Portfolio.Cases.CaseRelatedCasesTopic.InternalUser;
using DJIndex = Inprotech.Tests.Integration.EndToEnd.Portfolio.Cases.DesignatedJurisdictionTopic.InternalUser;

namespace Inprotech.Tests.Integration.EndToEnd.Portfolio.Cases.IpPlatform
{
    [Category(Categories.E2E)]
    [TestFixture]
    public class IppCaseView : IppIntegrationTest
    {
        [TearDown]
        public void CleanupModifiedData()
        {
            SiteControlRestore.ToDefault(SiteControls.CriticalDates_Internal, SiteControls.LANGUAGE, SiteControls.HomeNameNo, SiteControls.CPA_UseClientCaseCode);
        }

        [TestCase(BrowserType.Chrome)]
        [TestCase(BrowserType.FireFox)]
        public void CaseViewReadOnlyWithIppIntegration(BrowserType browserType)
        {
            var user = new Users()
                       .WithPermission(ApplicationTask.ViewFileCase, Allow.Create)
                       .CreateIpPlatformUser();

            var setup = new CaseDetailsDbSetup();
            var data = setup.ReadOnlyDataSetup();

            var driver = BrowserProvider.Get(browserType);
            var caseUrl = $"{Env.RootUrl}/#/caseview/{data.Patent.Case.Id}";

            SignInToThePlatform(driver, caseUrl, user);

            TestFileIconInDesignatedJurisdiction(driver);

            driver.Visit($"{Env.RootUrl}/#/caseview/{data.Trademark.Case.Id}");
            driver.WaitForAngularWithTimeout();

            TestFileIconInRelatedCases(driver);

            SignOutOfThePlatform(driver);
        }

        static void TestFileIconInDesignatedJurisdiction(NgWebDriver driver)
        {
            var jurisdictionTopic = new DesignatedJurisdictionTopic(driver);
            jurisdictionTopic.DesignatedJurisdictionGrid.Grid.WithJs().ScrollIntoView();

            Assert.True(jurisdictionTopic.DesignatedJurisdictionGrid.Grid.Displayed, "Designated Jurisdiction Section is showing");

            var fileIcon = jurisdictionTopic.DesignatedJurisdictionGrid.Cell(0, (int)DJIndex.FileIcon).FindElement(By.CssSelector(".cpa-icon-file-instruct"));
            Assert.NotNull(fileIcon, "Designated Jurisdiction: Should have a file icon");
            Assert.True(fileIcon.GetParent().Enabled, "Designated Jurisdiction: Should have file icon that is enabled");

            fileIcon.WithJs().Click();

            var popups = new CommonPopups(driver);
            Assert.NotNull(popups.AlertModal);

            // The case is not found at the IP Platform.
            popups.AlertModal.Ok();

            Assert.Throws<NoSuchElementException>(() => jurisdictionTopic.DesignatedJurisdictionGrid.Cell(1, (int)DJIndex.FileIcon).FindElement(By.CssSelector(".cpa-icon-file-instruct")), "Designated Jurisdiction 2: Should have not have a file icon");
        }

        static void TestFileIconInRelatedCases(NgWebDriver driver)
        {
            var relatedCasesTopic = new CaseRelatedCasesTopic(driver);
            relatedCasesTopic.RelatedCasesGrid.Grid.WithJs().ScrollIntoView();

            Assert.True(relatedCasesTopic.RelatedCasesGrid.Grid.Displayed, "Related Cases Section is showing");

            var fileIcon = relatedCasesTopic.RelatedCasesGrid.Cell(1, (int)RCIndex.FileIcon).FindElement(By.CssSelector(".cpa-icon-file-instruct"));
            Assert.NotNull(fileIcon, "Related Cases: Should have a file icon");
            Assert.True(fileIcon.GetParent().Enabled, "Related Cases: Should have file icon that is enabled");

            fileIcon.WithJs().Click();

            var popups = new CommonPopups(driver);
            Assert.NotNull(popups.AlertModal);

            // The case is not found at the IP Platform.
            popups.AlertModal.Ok();

            Assert.Throws<NoSuchElementException>(() => relatedCasesTopic.RelatedCasesGrid.Cell(0, (int)RCIndex.FileIcon).FindElement(By.CssSelector(".cpa-icon-file-instruct")), "Designated Jurisdiction 2: Should have not have a file icon");
        }
    }
}
