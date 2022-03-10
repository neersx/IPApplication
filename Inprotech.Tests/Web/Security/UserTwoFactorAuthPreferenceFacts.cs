using System.Threading.Tasks;
using Inprotech.Contracts;
using Inprotech.Infrastructure.Caching;
using Inprotech.Tests.Fakes;
using InprotechKaizen.Model.Components.Profiles;
using InprotechKaizen.Model.Profiles;
using NSubstitute;
using Xunit;

namespace Inprotech.Tests.Web.Security
{
    public class UserTwoFactorAuthPreferenceFacts : FactBase
    {
        public class TwoFactorAuthPreferenceFixture : IFixture<UserTwoFactorAuthPreferenceSettings>
        {
            public TwoFactorAuthPreferenceFixture(InMemoryDbContext db)
            {
                LifetimeScope = Substitute.For<LifetimeScopeCache>();
                CryptoService = Substitute.For<ICryptoService>();
                CryptoService.Decrypt(Arg.Any<string>()).Returns(x => x[0]);
                CryptoService.Encrypt(Arg.Any<string>()).Returns(x => x[0]);
                Subject = new UserTwoFactorAuthPreferenceSettings(db, CryptoService);
            }

            public ILifetimeScopeCache LifetimeScope { get; }
            public UserTwoFactorAuthPreferenceSettings Subject { get; }
            public ICryptoService CryptoService { get; }
        }

        public class TwoFactorAppFacts : FactBase
        {
            [Theory]
            [InlineData("")]
            [InlineData("email")]
            [InlineData("app")]
            public async Task DeleteTwoFactorKeyShouldDefaultToEmailConfigurationAndDisableAppConfiguration(string preference)
            {
                var password = Fixture.String();
                var bob = CreateUser("bob", password, true);
                
                new SettingValues()
                {
                    SettingId = KnownSettingIds.PreferredTwoFactorMode,
                    CharacterValue = preference,
                    User = bob
                }.In(Db);

                new SettingValues()
                {
                    SettingId = KnownSettingIds.AppSecretKey,
                    CharacterValue = Fixture.String(),
                    User = bob
                }.In(Db);

                var fixture = new TwoFactorAuthPreferenceFixture(Db);
                var subject = fixture.Subject;
                await subject.RemoveAppSecretKey(bob.Id);
                var preferredMethod = await subject.ResolvePreferredMethod(bob.Id);
                var appSecretKey = await subject.ResolveAppSecretKey(bob.Id);
                
                Assert.Equal("email", preferredMethod);
                Assert.True(string.IsNullOrWhiteSpace(appSecretKey));
            }

            [Theory]
            [InlineData("app", "app")]
            [InlineData("email", "email")]
            public async Task CorrectPreferenceValueReturned(string setPreference, string expectedPreference)
            {
                var password = Fixture.String();
                var bob = CreateUser("bob", password, true);
                var notBob = CreateUser("notbob", password, true);
                var notBobValue = Fixture.String();

                new SettingValues()
                {
                    SettingId = KnownSettingIds.PreferredTwoFactorMode,
                    CharacterValue = notBobValue,
                    User = notBob
                }.In(Db);

                new SettingValues()
                {
                    SettingId = KnownSettingIds.PreferredTwoFactorMode,
                    CharacterValue = setPreference,
                    User = bob
                }.In(Db);

                var fixture = new TwoFactorAuthPreferenceFixture(Db);
                var subject = fixture.Subject;

                var keyBob = await subject.ResolvePreferredMethod(bob.Id);

                Assert.Equal(expectedPreference, keyBob);
                Assert.NotEqual(notBobValue, keyBob);
            }

            [Fact]
            public async Task NoPreferenceYieldsEmail()
            {
                var password = Fixture.String();
                var bob = CreateUser("bob", password, true);
                var notBob = CreateUser("bob", password, true);

                var fixture = new TwoFactorAuthPreferenceFixture(Db);
                var subject = fixture.Subject;

                var keyNotBob = await subject.ResolvePreferredMethod(notBob.Id);
                var keyBob = await subject.ResolvePreferredMethod(bob.Id);

                Assert.Equal("email", keyBob);
                Assert.Equal("email", keyNotBob);
            }

            [Fact]
            public async Task CorrectEmailKeyReturned()
            {
                var password = Fixture.String();
                var bob = CreateUser("bob", password, true);
                var notBob = CreateUser("bob", password, true);
                var bobSecretKey = Fixture.String();

                new SettingValues()
                {
                    SettingId = KnownSettingIds.EmailSecretKey,
                    CharacterValue = "email",
                    User = notBob
                }.In(Db);

                new SettingValues()
                {
                    SettingId = KnownSettingIds.EmailSecretKey,
                    CharacterValue = bobSecretKey,
                    User = bob
                }.In(Db);

                var fixture = new TwoFactorAuthPreferenceFixture(Db);
                var subject = fixture.Subject;

                var keyBob = await subject.ResolveEmailSecretKey(bob.Id);

                Assert.Equal(bobSecretKey, keyBob);
            }

            [Fact]
            public async Task EmailKeyReturnsValueIfNoSetting()
            {
                var password = Fixture.String();
                var bob = CreateUser("bob", password, true);

                var fixture = new TwoFactorAuthPreferenceFixture(Db);
                var subject = fixture.Subject;

                var keyBob = await subject.ResolveEmailSecretKey(bob.Id);

                Assert.False(string.IsNullOrWhiteSpace(keyBob));
            }
        }
    }
}
