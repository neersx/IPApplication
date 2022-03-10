using Inprotech.Infrastructure;
using Inprotech.Infrastructure.Security;
using Inprotech.Infrastructure.Security.Licensing;
using Inprotech.Tests.Integration.DbHelpers;
using Inprotech.Tests.Integration.Extensions;
using Inprotech.Tests.Integration.Utils;
using NUnit.Framework;
using OpenQA.Selenium;
using Protractor;

namespace Inprotech.Tests.Integration.EndToEnd.Portfolio.Cases.Efiling
{
    [Category(Categories.E2E)]
    [TestFixture]
    public class CaseViewEfiling : IntegrationTest
    {
        [SetUp]
        public void Setup()
        {
            DatabaseRestore.CreateElectronicFilingArtifacts();
        }

        [TearDown]
        public void CleanupModifiedData()
        {
            SiteControlRestore.ToDefault(SiteControls.CriticalDates_Internal, SiteControls.LANGUAGE, SiteControls.HomeNameNo, SiteControls.CPA_UseClientCaseCode);
        }

        [TestCase(BrowserType.Chrome)]
        [TestCase(BrowserType.FireFox)]
        [TestCase(BrowserType.Ie)]
        public void DisplayEfilingSection(BrowserType browserType)
        {
            var setup = new CaseDetailsDbSetup();
            var data = setup.ReadOnlyDataSetup();
            var thisCase = data.Trademark.Case;
            var user = new Users()
                       .WithLicense(LicensedModule.CasesAndNames)
                       .WithSubjectPermission(ApplicationSubject.EFiling)
                       .Create();

            var caseId = (int)thisCase.Id;
            var driver = BrowserProvider.Get(browserType);
            SignIn(driver, $"/#/caseview/{caseId}?section=efiling", user.Username, user.Password);

            var eFiling = new EfilingTopic(driver);

            Assert.True(eFiling.EfilingGrid.Grid.Displayed, "Expected E-filing Section to be displayed");
            Assert.AreEqual(2, eFiling.EfilingGrid.Rows.Count, "Expected correct number of packages to be returned.");
            Assert.AreEqual("e2e-PackageType", eFiling.EfilingGrid.CellText(1, 1), "Expect Package Type to be correctly retrieved.");
            Assert.AreEqual("e2e-PackageReference01", eFiling.EfilingGrid.CellText(0, 2), "Expect Package Reference to be correctly retrieved.");
            Assert.AreEqual("e2e-Status02", eFiling.EfilingGrid.CellText(1, 4), "Expect Status to be correctly retrieved.");
            Assert.True(eFiling.IsActive(), "E-filing section is selected by default.");
            Assert.AreEqual(2, eFiling.NumberOfRecords(), "Ensure the number of records are counted correctly.");

            TestHistoryDialog(driver, eFiling);

            TestColumnSelection(driver, eFiling);

            eFiling.EfilingGrid.ToggleDetailsRow(0);

            Assert.True(eFiling.EfilingFilesGrid.Grid.Displayed, "Expected E-filing Section to be displayed");
            Assert.AreEqual(3, eFiling.EfilingFilesGrid.Rows.Count, "Expected correct number of packages files to be returned.");
            Assert.AreEqual("e2e1-ComponentDescription", eFiling.EfilingFilesGrid.CellText(0, 0), "Expect packages files Component to be correctly retrieved.");
            Assert.AreEqual("e2e2-FileName.jpg", eFiling.EfilingFilesGrid.CellText(1, 1), "Expect packages files Name to be correctly retrieved.");
            Assert.AreEqual("100069", eFiling.EfilingFilesGrid.CellText(2, 2), "Expect packages files Size to be correctly retrieved.");

            if (browserType == BrowserType.Ie) return;
            eFiling.EfilingFilesGrid.Cell(1, 1).FindElement(By.TagName("a")).ClickWithTimeout(waitForAngular: false);
            var windowCount = driver.WindowHandles.Count;
            Assert.AreEqual(2, windowCount, "Ensure a new window is opened.");
        }

        void TestColumnSelection(NgWebDriver driver, EfilingTopic topic)
        {
            Assert.AreEqual(false, topic.EfilingGrid.HeaderColumn("userName").Displayed, "User Name column should be hidden by default");
            Assert.AreEqual(false, topic.EfilingGrid.HeaderColumn("server").Displayed, "Server column should be hidden by default");

            topic.ColumnSelector.ColumnMenuButtonClick();
            Assert.IsTrue(topic.ColumnSelector.IsColumnChecked("packageReference"), "The column appears checked in the menu");

            topic.ColumnSelector.ToggleGridColumn("packageReference");
            topic.ColumnSelector.ColumnMenuButtonClick();
            Assert.AreEqual(false, topic.EfilingGrid.HeaderColumn("packageReference").Displayed, "Package Reference column should be hidden");

            topic.ColumnSelector.ColumnMenuButtonClick();
            Assert.IsFalse(topic.ColumnSelector.IsColumnChecked("packageReference"), "The column is unchecked in the menu");
            topic.ColumnSelector.ToggleGridColumn("userName");
            topic.ColumnSelector.ColumnMenuButtonClick();
            Assert.AreEqual(true, topic.EfilingGrid.HeaderColumn("userName").WithJs().IsVisible(), "User Name Column should be displayed");

            topic.ColumnSelector.ColumnMenuButtonClick();
            topic.ColumnSelector.ToggleGridColumn("packageReference");
            topic.ColumnSelector.ToggleGridColumn("userName");
            topic.ColumnSelector.ColumnMenuButtonClick();
            Assert.AreEqual(true, topic.EfilingGrid.HeaderColumn("packageReference").WithJs().IsVisible(), "Package Reference Column should be displayed");
            Assert.AreEqual(false, topic.EfilingGrid.HeaderColumn("userName").Displayed, "User Name column should be hidden");

            topic.ColumnSelector.ColumnMenuButtonClick();
            topic.ColumnSelector.ToggleGridColumn("server");
            topic.ColumnSelector.ToggleGridColumn("packageReference");
            topic.ColumnSelector.ColumnMenuButtonClick();

            Assert.AreEqual(false, topic.EfilingGrid.HeaderColumn("packageReference").Displayed, "Package Reference column should be hidden");
            Assert.AreEqual(true, topic.EfilingGrid.HeaderColumn("server").WithJs().IsVisible(), "Server Column should be displayed");

            topic.ColumnSelector.ColumnMenuButtonClick();
            topic.ColumnSelector.ResetColumns();

            Assert.AreEqual(true, topic.EfilingGrid.HeaderColumn("packageReference").WithJs().IsVisible(), "Package Reference Column should be displayed after reset");
            Assert.AreEqual(false, topic.EfilingGrid.HeaderColumn("userName").Displayed, "User Name column should be hidden after reset");
            Assert.AreEqual(false, topic.EfilingGrid.HeaderColumn("server").Displayed, "Server column should be hidden after reset");
        }

        void TestHistoryDialog(NgWebDriver driver, EfilingTopic eFiling)
        {
            eFiling.EfilingGrid.Cell(0, 3).FindElement(By.TagName("a")).ClickWithTimeout();
            var eFilingHistoryModal = new EfilingHistoryDialog(driver, "eFilingHistory");
            var statusText = eFilingHistoryModal.EfilingHistoryGrid.CellText(0, 1);
            var statusDescriptionText = eFilingHistoryModal.EfilingHistoryGrid.CellText(1, 2);

            Assert.True(eFilingHistoryModal.IsVisible(), "Ensure that the history dialog is displayed");
            Assert.AreEqual("Task completed successfully (Prepare Package).", statusDescriptionText, "Description is retrieved correctly.");
            Assert.AreEqual("Pack for DPMA failed.", statusText, "Status should be correctly retrieved.");

            eFilingHistoryModal.FindElement(By.ClassName("btn-discard")).ClickWithTimeout();
        }
    }
}