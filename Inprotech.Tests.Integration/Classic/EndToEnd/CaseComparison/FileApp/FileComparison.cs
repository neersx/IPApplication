using System;
using System.Collections.Generic;
using System.Linq;
using Inprotech.Infrastructure.Security;
using Inprotech.Integration;
using Inprotech.Tests.Integration.Classic.EndToEnd.CaseComparison.Extensions;
using Inprotech.Tests.Integration.DbHelpers;
using Inprotech.Tests.Integration.DbHelpers.Builders;
using Inprotech.Tests.Integration.Extensions;
using Inprotech.Tests.Integration.PageObjects;
using Inprotech.Tests.Integration.Utils;
using InprotechKaizen.Model;
using InprotechKaizen.Model.Ede.DataMapping;
using NUnit.Framework;
using Mapping = InprotechKaizen.Model.Ede.DataMapping.Mapping;

namespace Inprotech.Tests.Integration.Classic.EndToEnd.CaseComparison.FileApp
{
    [TestFixture]
    [Category(Categories.E2E)]
    [RebuildsIntegrationDatabase]
    public class FileComparison : IntegrationTest
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
            var applicationNumberAu = RandomString.Next(20);
            var applicationNumberPct = "111222333";
            var sessionGuid = Guid.NewGuid();

            var setup = new CaseComparisonDbSetup();

            var pctCase = setup.BuildInprotechCase("PCT", "P")
                                     .WithOfficialNumber(KnownNumberTypes.Application, applicationNumberPct);

            var inprotechAuCase = setup.BuildInprotechCase("AU", "P")
                                       .WithOfficialNumber(KnownNumberTypes.Application, applicationNumberAu)
                                       .WithParentPctCase(pctCase);

            DbSetup.Do(db =>
            {
                var mapStructure = db.DbContext.Set<MapStructure>()
                                     .SingleOrDefault(_ => _.Id == KnownMapStructures.Events);

                var source = db.DbContext.Set<DataSource>()
                               .SingleOrDefault(_ => _.SystemId == (short) KnownExternalSystemIds.File);

                var event1 = new EventBuilder(db.DbContext).Create();

                var mapping = db.DbContext.Set<Mapping>().Single(_ => _.InputDescription == "SENT TO AGENT" && _.MapStructure.Id == mapStructure.Id && _.DataSource.Id == source.Id);
                mapping.IsNotApplicable = false;
                mapping.OutputValue = event1.Id.ToString();
               
                db.DbContext.SaveChanges();
            });

            string fullPath;
            setup.BuildIntegrationEnvironment(DataSourceType.File, sessionGuid)
                 .BuildIntegrationCase(DataSourceType.File, inprotechAuCase.Id, applicationNumberAu)
                 .WithSuccessNotification(null)
                 .InStorage(sessionGuid, "cpa-xml.xml", out fullPath);

            CreateFileInStorage("file.e2e.cpaxml.xml", "cpa-xml.xml", fullPath);

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

                                             Assert.IsNotEmpty(page.CaseComparisonView.CaseNames, "Should contain some names");

                                             Assert.IsTrue(page.CaseComparisonView.OfficialNumbers.Displayed, "Should contain some official numbers");

                                             Assert.IsNotEmpty(page.CaseComparisonView.ParentRelatedCases, "Should contain atleast one relationship");

                                             Assert.IsNotEmpty(page.CaseComparisonView.Events, "Should contain some events");

                                             Assert.IsTrue(page.CaseComparisonView.UpdateCase.IsVisible(), "Should have the 'Update Case' button as it is not readonly");

                                             Assert.IsTrue(page.CaseComparisonView.MarkReviewed.IsVisible(), "Should have the 'Mark Review' button as it is not readonly");

                                             Assert.IsTrue(page.CaseComparisonView.UpdateCase.IsDisabled(), "Should have the 'Update Case' button disabled initially");

                                             Assert.IsFalse(page.CaseComparisonView.MarkReviewed.IsDisabled(), "Should have the 'Mark Review' button enabled all the time");
                                         });

        }

        void CreateFileInStorage(string file, string name, string fullPath)
        {
            var filePath = FileSetup.SendToStorage(file, name, fullPath.Replace(name, string.Empty));

            _filesAdded.Add(filePath);
        }
    }
}