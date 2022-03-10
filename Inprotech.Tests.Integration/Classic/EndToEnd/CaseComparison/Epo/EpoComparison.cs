using System;
using System.Collections.Generic;
using Inprotech.Infrastructure.Security;
using Inprotech.Integration;
using Inprotech.Tests.Integration.Classic.EndToEnd.CaseComparison.Extensions;
using Inprotech.Tests.Integration.DbHelpers;
using Inprotech.Tests.Integration.Extensions;
using Inprotech.Tests.Integration.PageObjects;
using Inprotech.Tests.Integration.Utils;
using InprotechKaizen.Model;
using NUnit.Framework;

namespace Inprotech.Tests.Integration.Classic.EndToEnd.CaseComparison.Epo
{
    [TestFixture]
    [Category(Categories.E2E)]
    [RebuildsIntegrationDatabase]
    public class EpoComparison : IntegrationTest
    {
        [TearDown]
        public void CleanupFiles()
        {
            foreach (var file in _filesAdded)
                FileSetup.DeleteFile(file);
        }

        readonly List<string> _filesAdded = new List<string>();

        [TestCase(BrowserType.Chrome)]
        [TestCase(BrowserType.Ie)]
        [TestCase(BrowserType.FireFox)]
        public void StandardComparisonScenario(BrowserType browserType)
        {
            var applicationNumber = RandomString.Next(20);
            var sessionGuid = Guid.NewGuid();

            var setup = new CaseComparisonDbSetup();
            var inprotechCase = setup.BuildInprotechCase("EP", "P")
                                     .WithOfficialNumber(KnownNumberTypes.Application, applicationNumber);

            string fullPath;
            setup.BuildIntegrationEnvironment(DataSourceType.Epo, sessionGuid)
                 .BuildIntegrationCase(DataSourceType.Epo, inprotechCase.Id, applicationNumber)
                 .WithSuccessNotification(inprotechCase.Title)
                 .InStorage(sessionGuid, "cpa-xml.xml", out fullPath);

            CreateFileInStorage("epo.ops.cpaxml.xml", "cpa-xml.xml", fullPath);

            var ken = new Users()
                .WithPermission(ApplicationTask.ViewCaseDataComparison)
                .WithPermission(ApplicationTask.SaveImportedCaseData)
                .Create();

            var driver = BrowserProvider.Get(browserType);

            SignIn(driver, "/#/casecomparison/inbox", ken.Username, ken.Password);

            driver.With<InboxPageObject>(page =>
                                         {
                                             Assert.AreEqual(1, page.Notifications.Count, "Should have a single notification.");

                                             Assert.IsTrue(page.CaseComparisonView.IsDisplayed(), "Should display case comparison view.");

                                             Assert.IsTrue(page.CaseComparisonView.OfficialNumbers.Displayed, "Should contain some official numbers");

                                             Assert.IsNotEmpty(page.CaseComparisonView.CaseNames, "Should contain some names");

                                             Assert.IsTrue(page.CaseComparisonView.UpdateCase.IsVisible(), "Should have the 'Update Case' button as it is not readonly");

                                             Assert.IsTrue(page.CaseComparisonView.MarkReviewed.IsVisible(), "Should have the 'Mark Review' button as it is not readonly");

                                             Assert.IsTrue(page.CaseComparisonView.UpdateCase.IsDisabled(), "Should have the 'Update Case' button disabled initially");

                                             Assert.IsFalse(page.CaseComparisonView.MarkReviewed.IsDisabled(), "Should have the 'Mark Review' button enabled all the time");

                                             // update case

                                             page.CaseComparisonView.Title.Click();

                                             page.CaseComparisonView.Update();
                                         });
        }

        void CreateFileInStorage(string file, string name, string fullPath)
        {
            var filePath = FileSetup.SendToStorage(file, name, fullPath.Replace(name, string.Empty));

            _filesAdded.Add(filePath);
        }
    }
}