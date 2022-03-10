using System;
using Inprotech.Tests.Integration.DbHelpers;
using Inprotech.Tests.Integration.EndToEnd.Accounting.Time;
using InprotechKaizen.Model.Cases;
using NUnit.Framework;

namespace Inprotech.Tests.Integration.EndToEnd.TaskPlanner
{
    [Category(Categories.E2E)]
    [TestFixture]
    public class TaskPlannerRecordTime : TimeRecordingFromOtherApps
    {
        TestUser _user;
        Case _case;

        [SetUp]
        public new void Setup()
        {
            var data = TaskPlannerService.SetupData();
            _user = data.User;
            _case = data.Data[0].Case;

            var today = DateTime.Today;
            TaskPlannerService.InsertAdHocDate(_case.Id, today.AddDays(5), _user);
        }

        [TestCase(BrowserType.Chrome)]
        [TestCase(BrowserType.Ie)]
        [TestCase(BrowserType.FireFox)]
        public void CreateTimeEntry(BrowserType browserType)
        {
            var driver = BrowserProvider.Get(browserType);

            SignIn(driver, "/#/task-planner", _user.Username, _user.Password);
            var page = new TaskPlannerPageObject(driver);

            page.ContextMenu.RecordTime(0);

            CheckRecordTime(driver, browserType, _case.Irn);
        }

        [TestCase(BrowserType.Chrome)]
        [TestCase(BrowserType.Ie)]
        [TestCase(BrowserType.FireFox)]
        public void CreateTimerEntry(BrowserType browserType)
        {
            var driver = BrowserProvider.Get(browserType);

            SignIn(driver, "/#/task-planner", _user.Username, _user.Password);
            var page = new TaskPlannerPageObject(driver);

            page.ContextMenu.RecordTimeWithTimer(0);

            CheckRecordTimeWithTimer(driver, browserType, _case.Irn);
        }
    }
}