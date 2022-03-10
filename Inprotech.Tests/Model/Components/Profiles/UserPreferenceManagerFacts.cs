using System.Linq;
using System.Threading.Tasks;
using Inprotech.Infrastructure;
using Inprotech.Infrastructure.Localisation;
using Inprotech.Tests.Fakes;
using Inprotech.Tests.Web.Builders.Model.Security;
using InprotechKaizen.Model.Components.Profiles;
using InprotechKaizen.Model.Profiles;
using InprotechKaizen.Model.Security;
using NSubstitute;
using Xunit;

namespace Inprotech.Tests.Model.Components.Profiles
{
    public class UserPreferenceManagerFacts
    {
        public class SetPreferences : FactBase
        {
            [Theory]
            [InlineData(true)]
            [InlineData(false)]
            [InlineData(null)]
            public void SetsBooleanValueForTheUserPreference(bool settingValue)
            {
                var f = new UserPreferenceManagerFixture(Db);
                var settingId = Fixture.Integer();
                var settingName = Fixture.String();
                var settingDefinition = new SettingDefinition { SettingId = settingId, Name = settingName, Description = settingName + "_Description" }.In(Db);
                new SettingValues { BooleanValue = !settingValue, SettingId = settingId, Definition = settingDefinition, User = new UserBuilder(Db).Build() }.In(Db);
                new SettingValues { BooleanValue = settingValue, SettingId = settingId, Definition = settingDefinition, User = f.Staff }.In(Db);

                f.Subject.SetPreference<bool?>(f.Staff.Id, settingId, settingValue);
                Assert.NotNull(Db.Set<SettingValues>().Single(_ => _.BooleanValue == settingValue && _.SettingId == settingId && _.User.Id == f.Staff.Id));
            }

            [Theory]
            [InlineData(true)]
            [InlineData(false)]
            public void SetsStringValueForTheUserPreference(bool withValue)
            {
                var settingValue = withValue ? Fixture.String() : null;
                var f = new UserPreferenceManagerFixture(Db);

                var settingId = Fixture.Integer();
                var settingName = Fixture.String();
                var settingDefinition = new SettingDefinition { SettingId = settingId, Name = settingName, Description = settingName + "_Description" }.In(Db);
                new SettingValues { CharacterValue = settingValue, SettingId = settingId, Definition = settingDefinition, User = new UserBuilder(Db).Build() }.In(Db);
                new SettingValues { CharacterValue = settingValue, SettingId = settingId, Definition = settingDefinition, User = f.Staff }.In(Db);

                f.Subject.SetPreference(f.Staff.Id, settingId, settingValue);
                Assert.NotNull(Db.Set<SettingValues>().Single(_ => _.CharacterValue == settingValue && _.SettingId == settingId && _.User.Id == f.Staff.Id));
            }

            [Theory]
            [InlineData(true)]
            [InlineData(false)]
            public void SetsIntegerValueForTheUserPreference(bool withValue)
            {
                var settingValue = withValue ? Fixture.Integer() : (int?)null;
                var f = new UserPreferenceManagerFixture(Db);

                var settingId = Fixture.Integer();
                var settingName = Fixture.String();
                var settingDefinition = new SettingDefinition { SettingId = settingId, Name = settingName, Description = settingName + "_Description" }.In(Db);
                new SettingValues { IntegerValue = settingValue, SettingId = settingId, Definition = settingDefinition, User = new UserBuilder(Db).Build() }.In(Db);
                new SettingValues { IntegerValue = settingValue, SettingId = settingId, Definition = settingDefinition, User = f.Staff }.In(Db);

                f.Subject.SetPreference(f.Staff.Id, settingId, settingValue);
                Assert.NotNull(Db.Set<SettingValues>().Single(_ => _.IntegerValue == settingValue && _.SettingId == settingId && _.User.Id == f.Staff.Id));
            }

            [Theory]
            [InlineData(true)]
            [InlineData(false)]
            public void SetsDecimalValueForTheUserPreference(bool withValue)
            {
                var settingValue = withValue ? Fixture.Decimal() : (decimal?)null;
                var f = new UserPreferenceManagerFixture(Db);

                var settingId = Fixture.Integer();
                var settingName = Fixture.String();
                var settingDefinition = new SettingDefinition { SettingId = settingId, Name = settingName, Description = settingName + "_Description" }.In(Db);
                new SettingValues { DecimalValue = settingValue, SettingId = settingId, Definition = settingDefinition, User = new UserBuilder(Db).Build() }.In(Db);
                new SettingValues { DecimalValue = settingValue, SettingId = settingId, Definition = settingDefinition, User = f.Staff }.In(Db);

                f.Subject.SetPreference(f.Staff.Id, settingId, settingValue);
                Assert.NotNull(Db.Set<SettingValues>().Single(_ => _.DecimalValue == settingValue && _.SettingId == settingId && _.User.Id == f.Staff.Id));
            }
        }

        public class GetBooleanPreference : FactBase
        {
            [Theory]
            [InlineData(true)]
            [InlineData(false)]
            public void ReturnsDefaultPreferences(bool settingValue)
            {
                var settingId = Fixture.Integer();
                var settingName = Fixture.String();
                var settingDefinition = new SettingDefinition { SettingId = settingId, Name = settingName, Description = settingName + "_Description" }.In(Db);
                var f = new UserPreferenceManagerFixture(Db);
                new SettingValues { BooleanValue = settingValue, SettingId = settingId, Definition = settingDefinition, User = null }.In(Db);
                new SettingValues { BooleanValue = settingValue, SettingId = settingId, Definition = settingDefinition, User = f.Staff }.In(Db);
                var result = f.Subject.GetPreference<bool>(Fixture.Integer(), settingId);
                Assert.Equal(settingValue, result);
            }

            [Theory]
            [InlineData(true)]
            [InlineData(false)]
            public void ReturnsPreferencesForUser(bool settingValue)
            {
                var settingId = Fixture.Integer();
                var settingName = Fixture.String();
                var settingDefinition = new SettingDefinition { SettingId = settingId, Name = settingName, Description = settingName + "_Description" }.In(Db);
                new SettingValues { BooleanValue = !settingValue, SettingId = settingId, Definition = settingDefinition, User = null }.In(Db);
                var f = new UserPreferenceManagerFixture(Db);
                new SettingValues { BooleanValue = settingValue, SettingId = settingId, Definition = settingDefinition, User = f.Staff }.In(Db);
                var result = f.Subject.GetPreference<bool>(f.Staff.Id, settingId);
                Assert.Equal(settingValue, result);
            }
        }

        public class GetPreferences : FactBase
        {
            [Theory]
            [InlineData(true)]
            [InlineData(false)]
            public async Task ReturnsDefaultPreferences(bool booleanSettingValue)
            {
                var settingId1 = Fixture.Integer();
                var settingId2 = Fixture.Integer();
                var integerSetting = Fixture.Integer();
                var settingName = Fixture.String();
                var settingDefinition1 = new SettingDefinition { SettingId = settingId1, Name = settingName, Description = settingName + "_Description", DataType = "B"}.In(Db);
                var settingDefinition2 = new SettingDefinition { SettingId = settingId2, Name = settingName, Description = settingName + "_Description2", DataType ="B" }.In(Db);
                var settingDefinition3 = new SettingDefinition { SettingId = integerSetting, Name = $"{settingName}_Integer", Description = settingName + "_Description3", DataType ="I" }.In(Db);
                var f = new UserPreferenceManagerFixture(Db);
                new SettingValues { BooleanValue = booleanSettingValue, SettingId = settingId1, Definition = settingDefinition1, User = null }.In(Db);
                new SettingValues { BooleanValue = booleanSettingValue, SettingId = settingId2, Definition = settingDefinition2, User = null }.In(Db);
                new SettingValues { BooleanValue = booleanSettingValue, SettingId = settingId1, Definition = settingDefinition1, User = f.Staff }.In(Db);
                var integerDefault = new SettingValues { IntegerValue = Fixture.Integer(), SettingId = integerSetting, Definition = settingDefinition3, User = null }.In(Db);
                new SettingValues { IntegerValue = Fixture.Integer(), SettingId = integerSetting, Definition = settingDefinition3, User = f.Staff }.In(Db);
                var result = await f.Subject.GetPreferences<UserPreference>(Fixture.Integer(), new[] { settingId1, settingId2, integerSetting });
                Assert.Equal(3, result.Length);
                var match = result[0];
                Assert.Equal(settingId1, match.Id);
                Assert.Equal(booleanSettingValue, match.BooleanValue);
                Assert.Equal(settingDefinition1.Name, match.Name);
                Assert.Equal(settingName + "_Description", match.Description);
                match = result[1];
                Assert.Equal(settingId2, match.Id);
                Assert.Equal(booleanSettingValue, match.BooleanValue);
                Assert.Equal(settingDefinition2.Name, match.Name);
                Assert.Equal(settingName + "_Description2", match.Description);
                match = result[2];
                Assert.Equal(integerSetting, match.Id);
                Assert.Equal(integerDefault.IntegerValue, match.IntegerValue);
                Assert.Equal(settingDefinition3.Name, match.Name);
                Assert.Equal(settingName + "_Description3", match.Description);
                f.PreferredCultureResolver.Received(1).Resolve();
            }

            [Theory]
            [InlineData(true)]
            [InlineData(false)]
            public async Task ReturnsPreferencesForUser(bool booleanSettingValue)
            {
                var settingId1 = Fixture.Integer();
                var settingId2 = Fixture.Integer();
                var integerSetting = Fixture.Integer();
                var settingName = Fixture.String();
                var settingDefinition1 = new SettingDefinition { SettingId = settingId1, Name = settingName, Description = settingName + "_Description", DataType = "B"}.In(Db);
                var settingDefinition2 = new SettingDefinition { SettingId = settingId2, Name = settingName, Description = settingName + "_Description2", DataType = "B"}.In(Db);
                var settingDefinition3 = new SettingDefinition { SettingId = integerSetting, Name = $"{settingName}_Integer", Description = settingName + "_Description3", DataType ="I" }.In(Db);
                new SettingValues { BooleanValue = !booleanSettingValue, SettingId = settingId1, Definition = settingDefinition1, User = null }.In(Db);
                new SettingValues { BooleanValue = !booleanSettingValue, SettingId = settingId2, Definition = settingDefinition2, User = null }.In(Db);
                var f = new UserPreferenceManagerFixture(Db);
                new SettingValues { BooleanValue = booleanSettingValue, SettingId = settingId1, Definition = settingDefinition1, User = f.Staff }.In(Db);
                new SettingValues { IntegerValue = Fixture.Integer(), SettingId = integerSetting, Definition = settingDefinition3, User = null }.In(Db);
                var userIntegerSetting = new SettingValues { IntegerValue = Fixture.Integer(), SettingId = integerSetting, Definition = settingDefinition3, User = f.Staff }.In(Db);
                var result = await f.Subject.GetPreferences<UserPreference>(f.Staff.Id, new[] { settingId1, settingId2, integerSetting });
                Assert.Equal(3, result.Length);
                var match = result[0];
                Assert.Equal(settingId1, match.Id);
                Assert.Equal(booleanSettingValue, match.BooleanValue);
                Assert.Equal(settingName, match.Name);
                Assert.Equal(settingName + "_Description", match.Description);
                match = result[1];
                Assert.Equal(settingId2, match.Id);
                Assert.Equal(!booleanSettingValue, match.BooleanValue);
                Assert.Equal(settingName, match.Name);
                Assert.Equal(settingName + "_Description2", match.Description);
                match = result[2];
                Assert.Equal(integerSetting, match.Id);
                Assert.Equal(userIntegerSetting.IntegerValue, match.IntegerValue);
                Assert.Equal(settingDefinition3.Name, match.Name);
                Assert.Equal(settingName + "_Description3", match.Description);
                f.PreferredCultureResolver.Received(1).Resolve();
            }
        }
        
        public class ResetUserPreference : FactBase
        {
            [Fact]
            public void DeletesSettingForTheUser()
            {
                var f = new UserPreferenceManagerFixture(Db);
                var settingValue = Fixture.String();
                var settingId = Fixture.Integer();
                var settingName = Fixture.String();
                var settingDefinition = new SettingDefinition { SettingId = settingId, Name = settingName, Description = settingName + "_Description" }.In(Db);

                var otherUser = new UserBuilder(Db).Build().In(Db);
                new SettingValues { CharacterValue = settingValue, SettingId = settingId, Definition = settingDefinition, User = otherUser }.In(Db);
                new SettingValues { CharacterValue = settingValue, SettingId = settingId, Definition = settingDefinition, User = f.Staff }.In(Db);
                new SettingValues { CharacterValue = settingValue, SettingId = settingId+1, Definition = settingDefinition, User = f.Staff }.In(Db);

                f.Subject.ResetUserPreferences(f.Staff.Id, new [] { settingId });
                Assert.Null(Db.Set<SettingValues>().SingleOrDefault(_ => _.CharacterValue == settingValue && _.SettingId == settingId && _.User.Id == f.Staff.Id));
                Assert.Equal(1, Db.Set<SettingValues>().Count(_ => _.CharacterValue == settingValue && _.SettingId == settingId));
                Assert.Equal(1, Db.Set<SettingValues>().Count(_ => _.CharacterValue == settingValue && _.SettingId == settingId+1));
            }
        }
        public class UserPreferenceManagerFixture : IFixture<IUserPreferenceManager>
        {
            public UserPreferenceManagerFixture(InMemoryDbContext db)
            {
                Staff = new UserBuilder(db).Build().In(db);
                PreferredCultureResolver = Substitute.For<IPreferredCultureResolver>();
                Subject = new UserPreferenceManager(db, PreferredCultureResolver);
            }

            public User Staff { get; set; }
            public IPreferredCultureResolver PreferredCultureResolver { get; set; }
            public ISiteControlReader SiteControlReader { get; set; }
            public IUserPreferenceManager Subject { get; }
        }
    }
}