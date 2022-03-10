using System.Linq;
using Inprotech.Infrastructure;
using Inprotech.Infrastructure.Web;
using Inprotech.Tests.Fakes;
using Inprotech.Tests.Web.Builders.Model.Security;
using Inprotech.Web.Accounting.Time;
using InprotechKaizen.Model.Components.Profiles;
using InprotechKaizen.Model.Components.Security;
using InprotechKaizen.Model.Profiles;
using InprotechKaizen.Model.Security;
using Newtonsoft.Json.Linq;
using NSubstitute;
using Xunit;

namespace Inprotech.Tests.Web.Accounting.Time
{
    public class TimePreferencesControllerFacts : FactBase
    {
        [Fact]
        public void GetsUserTimeRecordingPreferences()
        {
            var f = new TimePreferencesControllerFixture(Db);
            f.Subject.ViewData();
            f.UserPreferenceManager.Received(1).GetPreferences<UserPreference>(f.Staff.Id, Arg.Is<int[]>(_ => _.SequenceEqual(f.TimeRecordingSettings)));
        }

        [Theory]
        [InlineData(true)]
        [InlineData(false)]
        public void UpdatesBooleanUserTimeRecordingPreferences(bool setting)
        {
            var booleanPreference = new UserPreference
            {
                BooleanValue = setting,
                Id = Fixture.Integer(),
                DataType = "B"
            };
            var integerPreference = new UserPreference
            {
                IntegerValue = Fixture.Integer(),
                Id = Fixture.Integer(),
                DataType = "I"
            };
            var f = new TimePreferencesControllerFixture(Db);
            f.Subject.UpdateSettings(new[] {booleanPreference, integerPreference});
            f.UserPreferenceManager.Received(1).SetPreference(f.Staff.Id, booleanPreference.Id, booleanPreference.BooleanValue);
            f.UserPreferenceManager.Received(1).SetPreference(f.Staff.Id, integerPreference.Id, integerPreference.IntegerValue);
            f.UserPreferenceManager.Received(1).GetPreferences<UserPreference>(f.Staff.Id, Arg.Is<int[]>(_ => _.SequenceEqual(f.TimeRecordingSettings)));
        }

        [Fact]
        public void ResetsUserLevelTimeRecordingPreferences()
        {
            var f = new TimePreferencesControllerFixture(Db);
            f.Subject.ResetSettings();
            f.UserPreferenceManager.Received(1).ResetUserPreferences(f.Staff.Id, Arg.Is<int[]>(_ => _.SequenceEqual(f.TimeRecordingSettings)));
            f.UserPreferenceManager.Received(1).GetPreferences<UserPreference>(f.Staff.Id, Arg.Is<int[]>(_ => _.SequenceEqual(f.TimeRecordingSettings)));
        }

        [Fact]
        public void GetsWorkingHours()
        {
            var expectedResult = new WorkingHours {FromSeconds = 10, ToSeconds = 100};
            var f = new TimePreferencesControllerFixture(Db);
            f.JsonPreferenceManager.Get(Arg.Any<int>(), Arg.Any<int>()).ReturnsForAnyArgs(JObject.FromObject(expectedResult));
            var result = f.Subject.GetWorkingHours();

            f.JsonPreferenceManager.Received(1).Get(f.Staff.Id, KnownSettingIds.WorkingHours);
            Assert.Equal(expectedResult.FromSeconds, result.FromSeconds);
            Assert.Equal(expectedResult.ToSeconds, result.ToSeconds);
        }

        [Fact]
        public void SetsWorkingHours()
        {
            var input = new WorkingHours {FromSeconds = 10, ToSeconds = 100};
            var f = new TimePreferencesControllerFixture(Db);
            f.Subject.UpdateSettingWorkingHours(input);

            f.JsonPreferenceManager.Received(1).Set(f.Staff.Id, KnownSettingIds.WorkingHours, Arg.Is<JObject>(x => x.ToObject<WorkingHours>().FromSeconds == input.FromSeconds && x.ToObject<WorkingHours>().ToSeconds == input.ToSeconds));
        }

        public class TimePreferencesControllerFixture : IFixture<TimePreferencesController>
        {
            internal readonly int[] TimeRecordingSettings =
            {
                KnownSettingIds.DisplayTimeWithSeconds,
                KnownSettingIds.AddEntryOnSave,
                KnownSettingIds.TimeFormat12Hours,
                KnownSettingIds.HideContinuedEntries,
                KnownSettingIds.ContinueFromCurrentTime,
                KnownSettingIds.ValueTimeOnEntry,
                KnownSettingIds.TimePickerInterval,
                KnownSettingIds.DurationPickerInterval
            };

            public TimePreferencesControllerFixture(InMemoryDbContext db)
            {
                Security = Substitute.For<ISecurityContext>();
                Staff = new UserBuilder(db).Build();
                Security.User.Returns(Staff);
                var user = new User();
                Security.User.Returns(user);
                UserPreferenceManager = Substitute.For<IUserPreferenceManager>();
                JsonPreferenceManager = Substitute.For<IJsonPreferenceManager>();
                Subject = new TimePreferencesController(Security, UserPreferenceManager, JsonPreferenceManager);
            }

            public User Staff { get; set; }
            public IUserPreferenceManager UserPreferenceManager { get; set; }
            public IJsonPreferenceManager JsonPreferenceManager { get; set; }
            public ISecurityContext Security { get; set; }
            public TimePreferencesController Subject { get; set; }
        }
    }
}