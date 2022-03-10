using System;
using System.Linq;
using Inprotech.Infrastructure;
using Inprotech.Tests.Integration.DbHelpers;
using Inprotech.Tests.Integration.Extensions;
using Inprotech.Tests.Integration.PageObjects.Modals;
using Inprotech.Tests.Integration.Utils;
using InprotechKaizen.Model.Configuration.SiteControl;
using NUnit.Framework;

namespace Inprotech.Tests.Integration.EndToEnd.TaskPlanner
{
    [Category(Categories.E2E)]
    [TestFixture]
    public class TaskPlannerExport : IntegrationTest
    {
        [TestCase(BrowserType.Chrome)]
        public void ExportTaskPlannerAllFormats(BrowserType browserType)
        {
            var taskPlannerData = TaskPlannerService.SetupData();
            var data = taskPlannerData.Data;
            var user = taskPlannerData.User;

            DbSetup.Do(x =>
            {
                var exportLimit = x.DbContext.Set<SiteControl>().First(_ => _.ControlId == SiteControls.ExportLimit);
                exportLimit.IntegerValue = 1; 
                x.DbContext.SaveChanges();
            });

            var today = DateTime.Today;
            TaskPlannerService.InsertAdHocDate(data[0].Case.Id, today.AddDays(5), user);
            TaskPlannerService.InsertAdHocDate(data[1].Case.Id, today.AddDays(5), user);
            TaskPlannerService.InsertAdHocDate(data[2].Case.Id, today.AddDays(5), user);

            var downloadsFolder = KnownFolders.GetPath(KnownFolder.Downloads);

            ExportHelper.DeleteFilesFromDirectory(downloadsFolder, new[] { "TaskList.xlsx" });
            ExportHelper.DeleteFilesFromDirectory(downloadsFolder, new[] { "TaskList.docx" });
            ExportHelper.DeleteFilesFromDirectory(downloadsFolder, new[] { "TaskList.pdf" });
            var driver = BrowserProvider.Get(browserType);
            SignIn(driver, "/#/task-planner", user.Username, user.Password);
            var page = new TaskPlannerPageObject(driver);

            page.FilterButton.ClickWithTimeout();
            page.Cases.CaseReference.SendKeys("TaskPlanner");
            page.AdvancedSearchButton.ClickWithTimeout();

            page.OpenExportBulkOption("export-excel");
            page.Proceed();
            var popup = new CommonPopups(driver);
            popup.WaitForFlashAlert();
            var excel = ExportHelper.GetDownloadedFile(driver, "TaskList.xlsx");
            Assert.AreEqual($"{downloadsFolder}\\TaskList.xlsx", excel);
            
            page.OpenExportBulkOption("export-pdf");
            page.Proceed();
            popup.WaitForFlashAlert();
            var pdf = ExportHelper.GetDownloadedFile(driver, "TaskList.pdf");
            Assert.AreEqual($"{downloadsFolder}\\TaskList.pdf", pdf);
            
            page.OpenExportBulkOption("export-word");
            page.Proceed();
            popup.WaitForFlashAlert();
            var word = ExportHelper.GetDownloadedFile(driver, "TaskList.docx");
            Assert.AreEqual($"{downloadsFolder}\\TaskList.docx", word);

            DbSetup.Do(x =>
            {
                var exportLimit = x.DbContext.Set<SiteControl>().First(_ => _.ControlId == SiteControls.ExportLimit);
                exportLimit.IntegerValue = 1000; 
                x.DbContext.SaveChanges();
            });
        }
    }
}
