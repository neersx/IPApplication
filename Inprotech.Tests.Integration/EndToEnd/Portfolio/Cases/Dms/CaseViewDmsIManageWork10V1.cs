using System;
using System.Linq;
using Inprotech.Infrastructure.Security;
using Inprotech.Infrastructure.Security.Licensing;
using Inprotech.Tests.Integration.DbHelpers;
using Inprotech.Tests.Integration.DbHelpers.Builders;
using Inprotech.Tests.Integration.Extensions;
using Inprotech.Tests.Integration.Utils;
using InprotechKaizen.Model;
using InprotechKaizen.Model.Cases;
using NUnit.Framework;
using OpenQA.Selenium;

namespace Inprotech.Tests.Integration.EndToEnd.Portfolio.Cases.Dms
{
    [Category(Categories.E2E)]
    [TestFixture]
    public class CaseViewDmsIManageWork10V1 : IntegrationTest
    {
        [TestCase(BrowserType.Chrome)]
        [TestCase(BrowserType.FireFox)]
        [TestCase(BrowserType.Ie)]
        public void DisplayDmsSection(BrowserType browserType)
        {
            var thisCase = Setup();
            var user = new Users()
                       .WithLicense(LicensedModule.CasesAndNames)
                       .WithPermission(ApplicationTask.AccessDocumentsfromDms)
                       .Create();

            var caseId = thisCase.Id;
            var driver = BrowserProvider.Get(browserType);
            SignIn(driver, $"/#/caseview/{caseId}", user.Username, user.Password);

            var dms = new DocumentManagementPageObject(driver);
            Assert.IsNotEmpty(dms.DirectoryTreeView.Folders);
            Assert.True(dms.DirectoryTreeView.Folders.First().FolderIcon.IndexOf("cpa-icon-workspace", StringComparison.Ordinal) > -1);

            Assert.True(dms.DirectoryTreeView.Folders.First().Children.Single(fn => fn.Name.Trim() == "Email").FolderIcon.IndexOf("cpa-icon-envelope", StringComparison.Ordinal) > -1);
            Assert.AreEqual(true, dms.DirectoryTreeView.Folders.First().Children.Single(fn => fn.Name.Trim() == "Correspondence").IsParent);
            Assert.True(dms.DirectoryTreeView.Folders.First().Children.First().FolderIcon.IndexOf("cpa-icon-folder", StringComparison.Ordinal) > -1);

            dms.DirectoryTreeView.Folders[0].Children[0].Click();
            Assert.IsNotEmpty(dms.Documents.Rows);
            Assert.AreEqual(1, dms.Documents.Cell(0, 1).FindElements(By.ClassName("cpa-icon-envelope")).Count);
            Assert.AreEqual(1, dms.Documents.Cell(0, 2).FindElements(By.ClassName("cpa-icon-paperclip")).Count);
            Assert.AreEqual(1, dms.Documents.Cell(1, 1).FindElements(By.ClassName("cpa-icon-file-o")).Count);
            Assert.AreEqual(1, dms.Documents.Cell(2, 1).FindElements(By.ClassName("cpa-icon-file-excel-o")).Count);
            Assert.AreEqual(1, dms.Documents.Cell(3, 1).FindElements(By.ClassName("cpa-icon-file-word-o")).Count);
            Assert.AreEqual(1, dms.Documents.Cell(4, 1).FindElements(By.ClassName("cpa-icon-file-pdf-o")).Count);
            Assert.AreEqual(1, dms.Documents.Cell(5, 1).FindElements(By.ClassName("cpa-icon-file-word-o")).Count);

            dms.Documents.Cell(0, 0).FindElement(By.TagName("a")).ClickWithTimeout();

            var detail = dms.Documents.DocumentDetail(0);
            Assert.AreEqual("comment", detail.Comments.Value());

            Assert.IsEmpty(detail.RelatedDocuments, "No Related Documents functionality from v1");
            Assert.NotNull(driver.FindElement(By.CssSelector(".k-pager-sizes")));
            StringAssert.Contains("1 - 10", driver.FindElement(By.CssSelector(".k-pager-info.k-label")).Text);
        }

        Case Setup()
        {
            Case case1 = null;
            DbSetup.Do(db =>
            {
                case1 = new CaseBuilder(db.DbContext).Create(Fixture.String(5) + "1", true);
                new ScreenCriteriaBuilder(db.DbContext).Create(case1, out _)
                                                       .WithTopicControl(KnownCaseScreenTopics.CaseHeader)
                                                       .WithTopicControl(KnownCaseScreenTopics.Dms);

                new DocumentManagementDbSetup().Setup(IntegrationType.Work10V1);
                db.DbContext.SaveChanges();
            });
            return case1;
        }
    }
}