using System;
using System.Collections.Generic;
using System.Linq;
using Inprotech.Tests.Integration.Extensions;
using Inprotech.Tests.Integration.PageObjects;
using Inprotech.Tests.Integration.PageObjects.Modals;
using Inprotech.Tests.Integration.Utils;
using OpenQA.Selenium;
using Protractor;

namespace Inprotech.Tests.Integration.EndToEnd.Integration.PtoAccess
{
    public class SchedulesPageObject : PageObject
    {
        public SchedulesPageObject(NgWebDriver driver) : base(driver)
        {
        }

        public KendoGrid Schedules => new KendoGrid(Driver, "searchResults");

        public void NewSchedule()
        {
            Driver.FindElement(By.CssSelector(".cpa-icon-plus-circle")).ClickWithTimeout();
        }
        
        public void DeleteByRowIndex(int rowNumber)
        {
            ClickButtonInScheduleRow("Delete", rowNumber);

            new CommonPopups(Driver).ConfirmDeleteModal.Delete().WithJs().Click();
        }

        public void RunNowByRowIndex(int rowNumber)
        {
            ClickButtonInScheduleRow("RunNow", rowNumber);

            new CommonPopups(Driver).ConfirmModal.Yes().WithJs().Click();
        }

        void ClickButtonInScheduleRow(string name, int rowNumber)
        {
            Schedules.Rows[rowNumber].FindElement(By.CssSelector($"button[id*=\"btn{name}\"")).Click();
        }

        public IEnumerable<ScheduleSummary> AllScheduleSummary()
        {
            for (var i = 0; i < Schedules.Rows.Count; i++)
            {
                var scheduleName = Schedules.CellText(i, "Schedule");
                var source = Schedules.CellText(i, "Data Source");
                var status = Schedules.CellText(i, "Status");

                scheduleName = (scheduleName?.Split(new[] {Environment.NewLine}, StringSplitOptions.RemoveEmptyEntries) ?? new string[0]).FirstOrDefault();

                yield return new ScheduleSummary
                {
                    Name = scheduleName?.Trim(),
                    Source = source?.Trim(),
                    Status = status?.Trim()
                };
            }
        }

        public class ScheduleSummary
        {
            public string Name { get; set; }

            public string Source { get; set; }

            public string Status { get; set; }
        }
    }

    public static class ScheduleSummaryExtension
    {
        public static int IndexBySource(this SchedulesPageObject.ScheduleSummary[] summaries, string source)
        {
            var summary = summaries.SingleOrDefault(_ => _.Source == source);

            if (summary == null)
            {
                return -1;
            }

            return Array.IndexOf(summaries, summary);
        }

        public static int IndexByName(this SchedulesPageObject.ScheduleSummary[] summaries, string name)
        {
            var summary = summaries.SingleOrDefault(_ => _.Name == name);

            if (summary == null)
            {
                return -1;
            }

            return Array.IndexOf(summaries, summary);
        }
    }
}