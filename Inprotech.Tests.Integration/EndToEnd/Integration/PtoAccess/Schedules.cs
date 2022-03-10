using System;
using System.Linq;
using Inprotech.Infrastructure.Security;
using Inprotech.Integration;
using Inprotech.Integration.Schedules;
using Inprotech.Integration.Schedules.Extensions;
using Inprotech.Tests.Integration.DbHelpers;
using Inprotech.Tests.Integration.Extensions;
using Inprotech.Tests.Integration.PageObjects;
using Inprotech.Tests.Integration.Utils;
using Newtonsoft.Json;
using NUnit.Framework;

namespace Inprotech.Tests.Integration.EndToEnd.Integration.PtoAccess
{
    [TestFixture]
    [Category(Categories.E2E)]
    [RebuildsIntegrationDatabase]
    public class Schedules : IntegrationTest
    {
        [TestCase(BrowserType.Chrome)]
        [TestCase(BrowserType.Ie)]
        [TestCase(BrowserType.FireFox)]
        public void SchedulesTests(BrowserType browserType)
        {
            var driver = BrowserProvider.Get(browserType);

            var users = new Users();

            var user = users
                       .WithPermission(ApplicationTask.ScheduleUsptoTsdrDataDownload)
                       .WithPermission(ApplicationTask.ScheduleEpoDataDownload)
                       .WithPermission(ApplicationTask.ScheduleUsptoPrivatePairDataDownload)
                       .Create();

            IntegrationDbSetup.Do(x => x.Insert(new Schedule
            {
                CreatedBy = user.Id,
                Name = RandomString.Next(20),
                CreatedOn = DateTime.Now,
                DataSourceType = DataSourceType.UsptoPrivatePair,
                RunOnDays = "Mon",
                StartTime = DateTime.Now.TimeOfDay,
                DownloadType = DownloadType.All,
                ExtendedSettings = ScheduleSettings(new
                {
                    CustomerNumbers = "70859",
                    Certificates = 1,
                    CertificateName = Fixture.String(20),
                    DaysWithinLast = 3
                })
            }));

            IntegrationDbSetup.Do(x => x.Insert(new Schedule
            {
                CreatedBy = 45,
                Name = RandomString.Next(20),
                CreatedOn = DateTime.Now,
                DataSourceType = DataSourceType.UsptoTsdr,
                RunOnDays = "Wed",
                StartTime = DateTime.Now.TimeOfDay,
                DownloadType = DownloadType.All,
                ExtendedSettings = ScheduleSettings(new
                {
                    SavedQueryId = Fixture.Integer(),
                    SavedQueryName = RandomString.Next(20),
                    RunAsUserId = user.Id,
                    RunAsUserName = user.Username
                })
            }));

            IntegrationDbSetup.Do(x => x.Insert(new Schedule
            {
                CreatedBy = 45,
                Name = RandomString.Next(20),
                CreatedOn = DateTime.Now,
                DataSourceType = DataSourceType.Epo,
                RunOnDays = "Fri",
                StartTime = DateTime.Now.TimeOfDay,
                DownloadType = DownloadType.All,
                ExtendedSettings = ScheduleSettings(new
                {
                    SavedQueryId = Fixture.Integer(),
                    SavedQueryName = RandomString.Next(20),
                    RunAsUserId = user.Id,
                    RunAsUserName = user.Username
                })
            }));

            SignIn(driver, "/#/integration/ptoaccess/schedules", user.Username, user.Password);

            driver.With<SchedulesPageObject>(page =>
            {
                var scheduleSummaries = page.AllScheduleSummary().ToArray();

                Assert.AreEqual(3, scheduleSummaries.Length, "There should only 3 visible schedules");

                Assert.IsTrue(scheduleSummaries.Any(_ => _.Source == "USPTO Private PAIR"), "Private Pair schedule exists");

                Assert.IsTrue(scheduleSummaries.Any(_ => _.Source == "USPTO TSDR"), "TSDR schedule exists");

                Assert.IsTrue(scheduleSummaries.Any(_ => _.Source == "European Patent Office"), "EPO schedule exists");

                // Delete Private PAIR Schedule

                page.DeleteByRowIndex(scheduleSummaries.IndexBySource("USPTO Private PAIR"));
            });

            var remain = 0;
            var toRunNow = string.Empty;

            IntegrationDbSetup.Do(x => { remain = x.IntegrationDbContext.Set<Schedule>().WhereVisibleToUsers().Count(); });

            driver.With<SchedulesPageObject>((page, popup) =>
            {
                var scheduleSummaries = page.AllScheduleSummary().ToArray();

                Assert.IsFalse(scheduleSummaries.Any(_ => _.Source == "USPTO Private PAIR"), "Private Pair schedule should no longer exist");

                Assert.IsTrue(2 == page.Schedules.Rows.Count && 2 == remain, "There should only 2 visible schedules");

                // Run TSDR Schedule now

                toRunNow = scheduleSummaries[scheduleSummaries.IndexBySource("USPTO TSDR")].Name;

                page.RunNowByRowIndex(scheduleSummaries.IndexBySource("USPTO TSDR"));

                // notification message displayed.
                popup.WaitForFlashAlert();
            });

            IntegrationDbSetup.Do(x =>
            {
                var item = x.IntegrationDbContext
                            .Set<Schedule>()
                            .OrderByDescending(s => s.CreatedOn)
                            .First();

                Assert.AreEqual(DataSourceType.UsptoTsdr, item.DataSourceType, "A child TSDR schedule should be created.");
                Assert.AreEqual(toRunNow, item.Parent.Name, $"A child TSDR schedule should have parent name '{toRunNow}'.");
                Assert.IsTrue(new[] {ScheduleState.RunNow, ScheduleState.Purgatory, ScheduleState.Expired}.Contains(item.State),
                              "The child TSDR schedule should have state of 'Run Now', 'Purgatory' or 'Expired'");
            });
        }

        [TestCase(BrowserType.Chrome)]
        [TestCase(BrowserType.Ie)]
        [TestCase(BrowserType.FireFox)]
        public void OnlyAuthorisedSchedulesAreDisplayed(BrowserType browserType)
        {
            var driver = BrowserProvider.Get(browserType);

            var users = new Users();

            var user = users
                       .WithPermission(ApplicationTask.ScheduleUsptoPrivatePairDataDownload)
                       .WithPermission(ApplicationTask.ScheduleEpoDataDownload, Deny.Execute)
                       .WithPermission(ApplicationTask.ScheduleUsptoTsdrDataDownload, Deny.Execute)
                       .Create();

            IntegrationDbSetup.Do(x => x.Insert(new Schedule
            {
                CreatedBy = user.Id,
                Name = RandomString.Next(20),
                CreatedOn = DateTime.Now,
                DataSourceType = DataSourceType.UsptoPrivatePair,
                RunOnDays = "Mon",
                StartTime = DateTime.Now.TimeOfDay,
                DownloadType = DownloadType.All,
                ExtendedSettings = ScheduleSettings(new
                {
                    CustomerNumbers = "70859",
                    Certificates = 1,
                    CertificateName = Fixture.String(20),
                    DaysWithinLast = 3
                })
            }));

            IntegrationDbSetup.Do(x => x.Insert(new Schedule
            {
                CreatedBy = 45,
                Name = RandomString.Next(20),
                CreatedOn = DateTime.Now,
                DataSourceType = DataSourceType.UsptoTsdr,
                RunOnDays = "Wed",
                StartTime = DateTime.Now.TimeOfDay,
                DownloadType = DownloadType.All,
                ExtendedSettings = ScheduleSettings(new
                {
                    SavedQueryId = Fixture.Integer(),
                    SavedQueryName = RandomString.Next(20),
                    RunAsUserId = user.Id,
                    RunAsUserName = user.Username
                })
            }));

            IntegrationDbSetup.Do(x => x.Insert(new Schedule
            {
                CreatedBy = 45,
                Name = RandomString.Next(20),
                CreatedOn = DateTime.Now,
                DataSourceType = DataSourceType.Epo,
                RunOnDays = "Fri",
                StartTime = DateTime.Now.TimeOfDay,
                DownloadType = DownloadType.All,
                ExtendedSettings = ScheduleSettings(new
                {
                    SavedQueryId = Fixture.Integer(),
                    SavedQueryName = RandomString.Next(20),
                    RunAsUserId = user.Id,
                    RunAsUserName = user.Username
                })
            }));

            SignIn(driver, "/#/integration/ptoaccess/schedules", user.Username, user.Password);

            driver.With<SchedulesPageObject>(page =>
            {
                var scheduleSummaries = page.AllScheduleSummary().ToArray();

                Assert.AreEqual(1, scheduleSummaries.Length, "There should only 3 visible schedules");

                Assert.IsTrue(scheduleSummaries.Any(_ => _.Source == "USPTO Private PAIR"), "Private Pair schedule exists");

                Assert.IsFalse(scheduleSummaries.Any(_ => _.Source == "USPTO TSDR"), "TSDR schedule should not be visible as user no longer have the permission to view.");

                Assert.IsFalse(scheduleSummaries.Any(_ => _.Source == "European Patent Office"), "EPO schedule should not be visible as user no longer have the permission to view.");
            });
        }

        static string ScheduleSettings(dynamic props)
        {
            return JsonConvert.SerializeObject(props, Formatting.None);
        }
    }
}