using System;
using System.Collections.Generic;
using System.Linq;
using Inprotech.Infrastructure.Security;
using Inprotech.Integration.Schedules;
using Xunit;

namespace Inprotech.Tests.Integration.Schedules
{
    public class DataDownloadControllersTaskSecurityFacts
    {
        [Theory]
        [InlineData(typeof(DownloadController))]
        [InlineData(typeof(ScheduleViewController))]
        [InlineData(typeof(SchedulesController))]
        [InlineData(typeof(SchedulesViewController))]
        [InlineData(typeof(ScheduleExecutionsController))]
        [InlineData(typeof(ScheduleFailuresController))]
        [InlineData(typeof(NewScheduleController))]
        [InlineData(typeof(NewScheduleViewController))]
        [InlineData(typeof(RecoveryScheduleController))]
        [InlineData(typeof(FailureSummaryController))]
        public void AllScheduleDataDownloadControllersAreProtected(Type type)
        {
            var requiresAccessAttribute = Attribute.GetCustomAttributes(type)
                                                   .OfType<RequiresAccessToAttribute>()
                                                   .Select(_ => _.Task)
                                                   .ToList();

            foreach (var task in DataDownloadTasks())
                Assert.Contains(task, requiresAccessAttribute);
        }

        static IEnumerable<ApplicationTask> DataDownloadTasks()
        {
            return Enum.GetNames(typeof(ApplicationTask))
                       .Where(_ => _.StartsWith("Schedule") && _.EndsWith("DataDownload"))
                       .Select(_ => (ApplicationTask) Enum.Parse(typeof(ApplicationTask), _));
        }
    }
}