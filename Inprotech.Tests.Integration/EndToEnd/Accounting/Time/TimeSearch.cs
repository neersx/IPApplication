using Inprotech.Tests.Integration.DbHelpers;
using InprotechKaizen.Model.Security;
using NUnit.Framework;

namespace Inprotech.Tests.Integration.EndToEnd.Accounting.Time
{
    [Category(Categories.E2E)]
    [TestFixture]
    public class TimeSearchBase : IntegrationTest
    {
        protected TimeRecordingData DbData;

        [SetUp]
        public void Setup()
        {
            DbData = TimeRecordingDbHelper.Setup(withHoursOnlyTime: true);
            AccountingDbHelper.SetupPeriod();
            TimeRecordingDbHelper.SetupFunctionSecurity(new[]
            {
                FunctionSecurityPrivilege.CanRead,
                FunctionSecurityPrivilege.CanInsert,
                FunctionSecurityPrivilege.CanPost,
                FunctionSecurityPrivilege.CanUpdate,
                FunctionSecurityPrivilege.CanDelete
            }, DbData.User.NameId);
        }

        [TearDown]
        public void CleanUpModifiedData()
        {
            TimeRecordingDbHelper.Cleanup();
        }

        public int CurrentDiaryCountForUser => TimeRecordingDbHelper.GetDiaryCount(DbData.User.NameId);
    }
}