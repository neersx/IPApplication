using System;
using System.Linq;
using Inprotech.Infrastructure.Security;
using Inprotech.Integration.Schedules;
using Inprotech.Integration.Schedules.Extensions;
using Inprotech.Tests.Integration.DbHelpers;
using Inprotech.Tests.Integration.Extensions;
using Inprotech.Tests.Integration.PageObjects;
using InprotechKaizen.Model.Settings;
using NUnit.Framework;
using Extended = Inprotech.Integration.Schedules.Extensions.Innography;

namespace Inprotech.Tests.Integration.EndToEnd.Integration.PtoAccess.Innography
{
    [TestFixture]
    [Category(Categories.E2E)]
    [RebuildsIntegrationDatabase]
    internal class InnographySchedule : IntegrationTest
    {
        [TearDown]
        public void Restore()
        {
            UpdateAuthMode();
        }

        [TestCase(BrowserType.Chrome)]
        [TestCase(BrowserType.Ie)]
        [TestCase(BrowserType.FireFox)]
        public void NewScheduleTests(BrowserType browserType)
        {
            var driver = BrowserProvider.Get(browserType);

            var user = new Users()
                .WithPermission(ApplicationTask.ScheduleIpOneDataDownload)
                .Create();

            SignIn(driver, "/#/integration/ptoaccess/schedules", user.Username, user.Password);

            var name = RandomString.Next(20);

            driver.With<SchedulesPageObject>((page, popup) => { page.NewSchedule(); });

            driver.With<NewInnographySchedulePageObject>((page, popup) =>
            {
                page.ScheduleName.Input.SendKeys(name);

                page.DataSourceType.Input.SelectByText("IP One Data");

                page.Apply();

                Assert.True(page.SaveQuery.HasError, "Should display saved query not provided message");

                Assert.True(page.RunAs.HasError, "Should display run as not provided message");

                page.ExpiresAfter.Enter(DateTime.Today.AddDays(2).ToString("yyyy-MM-dd"));

                page.SaveQuery.EnterAndSelect("R"); // Recent Cases

                page.RunAs.EnterAndSelect("Adm"); // Administrator
                
                page.DownloadType.Value = "All";

                page.Save();
            });

            IntegrationDbSetup.Do(x =>
            {
                var schedule = x.IntegrationDbContext.Set<Schedule>().WhereVisibleToUsers().Single();

                var innographySchedule = schedule.GetExtendedSettings<Extended.InnographySchedule>();

                Assert.AreEqual("Sun,Mon,Tue,Wed,Thu,Fri,Sat", schedule.RunOnDays, "Should save schedule as recurring daily since this is the default.");

                Assert.AreEqual(DownloadType.All, schedule.DownloadType, "Should save schedule that downloads all, as specified");

                Assert.NotNull(schedule.NextRun, "Should save schedule with Next Run populated");

                Assert.NotNull(innographySchedule.RunAsUserId, "Should save schedule run as user id.");

                Assert.NotNull(innographySchedule.RunAsUserName, "Should save schedule run as user name.");

                Assert.NotNull(innographySchedule.SavedQueryId, "Should save schedule with saved query id.");

                Assert.NotNull(innographySchedule.SavedQueryName, "Should save schedule with saved query name.");
            });

            driver.With<SchedulesPageObject>(page =>
            {
                var schedules = page.AllScheduleSummary().ToArray();

                Assert.AreEqual(1, schedules.Length, "Should list the only created Innography schedule.");

                Assert.AreEqual("IP One Data", schedules[0].Source, "Should show that its Datasource is 'IP One Data'");

                Assert.AreEqual(name, schedules[0].Name, $"Should have the same name '{name}' as it was created'");
            });
        }

        [TestCase(BrowserType.Chrome)]
        [TestCase(BrowserType.Ie)]
        [TestCase(BrowserType.FireFox)]
        public void NewSchedulePrerequisiteUnmet(BrowserType browserType)
        {
            var driver = BrowserProvider.Get(browserType);

            var user = new Users()
                .WithPermission(ApplicationTask.ScheduleIpOneDataDownload)
                .Create();

            UpdateAuthMode("Forms"); // So that Sso is not enable, making innorgaphy pre-requisite to be unmet.

            SignIn(driver, "/#/integration/ptoaccess/schedules", user.Username, user.Password);

            var name = RandomString.Next(20);

            driver.With<SchedulesPageObject>((page, popup) => { page.NewSchedule(); });

            driver.With<NewInnographySchedulePageObject>((page, popup) =>
            {
                page.ScheduleName.Input.SendKeys(name);

                page.DataSourceType.Input.SelectByText("IP One Data");

                Assert.True(page.DataSourceType.HasError, "Should display source requirement not met message");
            });

            IntegrationDbSetup.Do(x => { Assert.False(x.IntegrationDbContext.Set<Schedule>().WhereVisibleToUsers().Any(), "Should not save any Innography schedule as pre-requisite unmet"); });
        }

        [TestCase(BrowserType.Chrome)]
        [TestCase(BrowserType.Ie)]
        [TestCase(BrowserType.FireFox)]
        public void NewRunOnceScheduleTests(BrowserType browserType)
        {
            var driver = BrowserProvider.Get(browserType);

            var user = new Users()
                .WithPermission(ApplicationTask.ScheduleIpOneDataDownload)
                .Create();

            SignIn(driver, "/#/integration/ptoaccess/schedules", user.Username, user.Password);

            var scheduleNameRunOnce = RandomString.Next(20);
            
            driver.With<SchedulesPageObject>((page, popup) => { page.NewSchedule(); });

            driver.With<NewInnographySchedulePageObject>((page, popup) =>
            {
                page.ScheduleName.Input.SendKeys(scheduleNameRunOnce);

                page.DataSourceType.Input.SelectByText("IP One Data");

                page.SaveQuery.EnterAndSelect("R"); // Recent Cases

                page.RunAs.EnterAndSelect("Adm"); // Administrator

                page.DownloadType.Value = "All";

                page.RunOnceOption.Click();

                page.Save();
            });

            IntegrationDbSetup.Do(x =>
            {
                var schedule = x.IntegrationDbContext.Set<Schedule>().WhereVisibleToUsers().Single(_ => _.Name == scheduleNameRunOnce);

                var innographySchedule = schedule.GetExtendedSettings<Extended.InnographySchedule>();

                Assert.Null(schedule.RunOnDays, "Should save schedule without any recurring days.");

                Assert.AreEqual(DownloadType.All, schedule.DownloadType, "Should save schedule that downloads all, as specified");

                Assert.AreEqual(DateTime.Today, schedule.ExpiresAfter.GetValueOrDefault().Date, "Should save schedule that expires immediately");

                if (schedule.State == ScheduleState.Active)
                {
                    /* the schedule has not already been picked up by Schedule Runtime */
                    Assert.AreEqual(DateTime.Today, schedule.NextRun.GetValueOrDefault().Date, "Should save schedule with Next Run populated as today");

                    Assert.Null(schedule.LastRunStartOn, "Should not have Last Run Start On filled as it has not already been run");
                }

                if (schedule.State == ScheduleState.Expired)
                {
                    /* the schedule has just been completed by the Schedule Runtime */
                    Assert.Null(schedule.NextRun, "Should have saved schedule with Next Run populated as today but has already been picked up and executed.");

                    Assert.AreEqual(DateTime.Today, schedule.LastRunStartOn.GetValueOrDefault().Date, "Should have Last Run Start On filled as Today as it has executed the schedule just then");
                }

                Assert.NotNull(innographySchedule.RunAsUserId, "Should save schedule run as user id.");

                Assert.NotNull(innographySchedule.RunAsUserName, "Should save schedule run as user name.");

                Assert.NotNull(innographySchedule.SavedQueryId, "Should save schedule with saved query id.");

                Assert.NotNull(innographySchedule.SavedQueryName, "Should save schedule with saved query name.");
            });

            driver.With<SchedulesPageObject>(page =>
            {
                // Create new schedule again

                page.NewSchedule();
            });

            var scheduleNameRunOnceLater = RandomString.Next(20);

            driver.With<NewInnographySchedulePageObject>((page, popup) =>
            {
                // create a run now schedule by specifying run now start time

                page.ScheduleName.Input.SendKeys(scheduleNameRunOnceLater);

                page.DataSourceType.Input.SelectByText("IP One Data");

                page.SaveQuery.EnterAndSelect("R"); // Recent Cases

                page.RunAs.EnterAndSelect("Adm"); // Administrator
                
                page.DownloadType.Value = "All";

                page.RunOnceOption.Click();

                page.AsapOption.Click();

                page.StartTimeHour.SelectByText("12");

                page.StartTimeMinutes.SelectByText("45");

                page.Save();
            });

            IntegrationDbSetup.Do(x =>
            {
                var schedule = x.IntegrationDbContext.Set<Schedule>().WhereVisibleToUsers().Single(_ => _.Name == scheduleNameRunOnceLater);

                var innographySchedule = schedule.GetExtendedSettings<Extended.InnographySchedule>();

                Assert.Null(schedule.RunOnDays, "Should save schedule without any recurring days.");

                Assert.AreEqual(DownloadType.All, schedule.DownloadType, "Should save schedule that downloads all, as specified");

                Assert.AreEqual(DateTime.Today, schedule.NextRun.GetValueOrDefault().Date, "Should save schedule with Next Run populated as today");

                Assert.AreEqual(DateTime.Today, schedule.ExpiresAfter.GetValueOrDefault().Date, "Should save schedule that expires immediately");

                Assert.AreEqual("12:45:00", schedule.StartTimeValue, $"Should save schedule start time as specified {schedule.StartTimeValue}");

                Assert.NotNull(innographySchedule.RunAsUserId, "Should save schedule run as user id.");

                Assert.NotNull(innographySchedule.RunAsUserName, "Should save schedule run as user name.");

                Assert.NotNull(innographySchedule.SavedQueryId, "Should save schedule with saved query id.");

                Assert.NotNull(innographySchedule.SavedQueryName, "Should save schedule with saved query name.");
            });
        }

        void UpdateAuthMode(string auth = "Forms,Windows,Sso")
        {
            DbSetup.Do(x =>
            {
                var settings = x.DbContext.Set<ConfigSetting>();

                var authMode = settings.Single(_ => _.Key == "InprotechServer.AppSettings.AuthenticationMode");

                authMode.Value = auth;

                x.DbContext.SaveChanges();
            });
        }
    }
}