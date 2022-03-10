using Inprotech.Contracts;
using Inprotech.Infrastructure;
using Inprotech.Infrastructure.Messaging;
using Inprotech.Infrastructure.Security;
using Inprotech.Tests.Fakes;
using Inprotech.Tests.Web.Builders.Model.Configuration;
using Inprotech.Tests.Web.Builders.Model.Names;
using Inprotech.Web.Security;
using Inprotech.Web.Security.ResetPassword;
using Inprotech.Web.Security.TwoFactorAuth;
using InprotechKaizen.Model;
using InprotechKaizen.Model.Configuration;
using InprotechKaizen.Model.Profiles;
using InprotechKaizen.Model.Security;
using NSubstitute;
using System;
using System.Linq;
using System.Net.Http;
using System.Threading.Tasks;
using System.Web.Http;
using System.Web.Http.Hosting;
using Xunit;

namespace Inprotech.Tests.Web.Security.ResetPassword
{
    public class ResetPasswordControllerFacts : FactBase
    {
        public class ResetPasswordControllerFixture : IFixture<ResetPasswordController>
        {
            public ICryptoService CryptoService { get; set; }
            public IUserAuditLogger<ResetPasswordController> Logger { get; set; }
            public ITaskSecurityProvider TaskSecurityProvider { get; set; }
            public IResetPasswordHelper ResetPasswordHelper { get; set; }
            public ISiteControlReader SiteControlReader { get; set; }

            public IPasswordManagementController PmController { get; set; }
            public Func<DateTime> Now { get; set; }
            public IUserValidation Validation { get; set; }

            public ResetPasswordController Subject { get; set; }

            public ResetPasswordControllerFixture(InMemoryDbContext db)
            {
                CryptoService = Substitute.For<ICryptoService>();
                Logger = Substitute.For<IUserAuditLogger<ResetPasswordController>>();
                TaskSecurityProvider = Substitute.For<ITaskSecurityProvider>();
                ResetPasswordHelper = Substitute.For<IResetPasswordHelper>();
                SiteControlReader = Substitute.For<ISiteControlReader>();
                Now = Substitute.For<Func<DateTime>>();
                PmController = Substitute.For<IPasswordManagementController>();
                var configuredAccess = Substitute.For<IConfiguredAccess>();
                configuredAccess.For(Arg.Any<User>()).Returns(true);

                var twoFactorAuthVerify = Substitute.For<ITwoFactorAuthVerify>();
                Validation = new UserValidation(db,
                                                configuredAccess,
                                                Substitute.For<ISiteControlReader>(),
                                                Substitute.For<IBus>(),
                                                () => DateTime.Now, twoFactorAuthVerify);

                SiteControlReader.Read<int?>(SiteControls.LogTimeOffset).Returns(0);
                Now().Returns(DateTime.Now);
                
                Subject = new ResetPasswordController(db, CryptoService, SiteControlReader, TaskSecurityProvider, Logger, ResetPasswordHelper, PmController, Now,Validation)
                {
                    Request = new HttpRequestMessage(HttpMethod.Post, Urls.ResetPassword)
                };

                Subject.Request.Properties.Add(HttpPropertyKeys.HttpConfigurationKey, new HttpConfiguration());
            }
        }

        public User ReturnsUser(ResetPasswordControllerFixture fixture)
        {
            var user = CreateUser("bob", "dabadee", true);
            fixture.TaskSecurityProvider.UserHasAccessTo(user.Id, ApplicationTask.ChangeMyPassword).Returns(true);
            return user;
        }

        public User ReturnsUserWithEmail(ResetPasswordControllerFixture fixture)
        {
            var user = CreateUser("bob", "dabadee", true);
            fixture.TaskSecurityProvider.UserHasAccessTo(user.Id, ApplicationTask.ChangeMyPassword).Returns(true);
            var tb1 = new TableCodeBuilder {TableCode = (int) KnownTelecomTypes.Email}.For(TableTypes.TelecommunicationsType).Build().In(Db);
            var t1 = new TelecommunicationBuilder {TelecomType = tb1, TelecomNumber = "abc@xyz"}.Build().In(Db);
            var nt = new NameTelecomBuilder(Db){Name = user.Name, Telecommunication = t1}.Build().In(Db);
            user.Name.MainEmailId = t1.Id;
            user.Name.Telecoms.Add(nt);
            return user;
        }

        [Fact]
        public async Task ThrowsExceptionWhenUserNameNotProvidedInRequest()
        {
            var f = new ResetPasswordControllerFixture(Db);

            var request = new ResetPasswordController.SendLinkRequest
                            {
                                Username = null
                            };

            var exception = await Assert.ThrowsAsync<ArgumentNullException>(
                            async () => await f.Subject.SendLink(request));

            Assert.IsType<ArgumentNullException>(exception);
        }

        [Fact]
        public async Task LogsWarningWhenUserNameNotValid()
        {
            var f = new ResetPasswordControllerFixture(Db);

            var response = await f.Subject.SendLink(new ResetPasswordController.SendLinkRequest()
            {
                Username = Fixture.String(),
                Url = Fixture.String()
            });

            f.Logger.Received(1).Warning("Username provided is not valid", Arg.Any<object>());
            Assert.NotNull(response);
            Assert.Equal(System.Net.HttpStatusCode.OK, response.StatusCode);
        }

        [Fact]
        public async Task CallResetEmailWhenUserNameIsValid()
        {
            var f = new ResetPasswordControllerFixture(Db);
            var user = ReturnsUser(f);
            var request = new ResetPasswordController.SendLinkRequest()
            {
                Username = user.UserName,
                Url = Fixture.String()
            };
            var response = await f.Subject.SendLink(request);

            await f.ResetPasswordHelper.Received(1).SendResetEmail(user, request.Url);
            Assert.NotNull(response);
            Assert.Equal(System.Net.HttpStatusCode.OK, response.StatusCode);
        }

        [Fact]
        public async Task ThrowsExceptionWhenRequestNotProvided()
        {
            var f = new ResetPasswordControllerFixture(Db);
            
            var exception = await Assert.ThrowsAsync<ArgumentNullException>(
                                                                            async () => await f.Subject.VerifyLink(null));

            Assert.IsType<ArgumentNullException>(exception);
        }

        [Fact]
        public async Task LogWarningForIncorrectToken()
        {
            var f = new ResetPasswordControllerFixture(Db);

            var request = new ResetPasswordController.ResetPasswordRequest()
            {
                Token = Fixture.String()
            };

            var response = await f.Subject.VerifyLink(request);
            f.Logger.Received(1).Warning(Arg.Is(" | Incorrect token passed | IncorrectToken"), Arg.Any<object>());
            Assert.NotNull(response);
            Assert.Equal(System.Net.HttpStatusCode.BadRequest, response.StatusCode);

            f.CryptoService.Decrypt(Arg.Any<string>()).Returns(Fixture.String());
            response = await f.Subject.VerifyLink(request);
            f.Logger.Received(2).Warning(Arg.Is(" | Incorrect token passed | IncorrectToken"), Arg.Any<object>());
            Assert.Equal(System.Net.HttpStatusCode.BadRequest, response.StatusCode);

        }

        [Fact]
        public async Task LogWarningForInvalidUser()
        {
            var f = new ResetPasswordControllerFixture(Db);
            var key = Fixture.String("Secret");
            new SettingValues {SettingId = KnownSettingIds.ResetPasswordSecretKey, CharacterValue = key, User = null}.In(Db);
            f.CryptoService.Decrypt(Arg.Any<string>()).Returns(key);

            var request = new ResetPasswordController.ResetPasswordRequest()
            {
                Token = Fixture.String()
            };

            var response = await f.Subject.VerifyLink(request);
            f.Logger.Received(1).Warning(Arg.Is(" | Not a valid user | UserInvalid"), Arg.Any<object>());
            Assert.Equal(System.Net.HttpStatusCode.BadRequest, response.StatusCode);
        }

        [Fact]
        public async Task LogWarningForUser()
        {
            var f = new ResetPasswordControllerFixture(Db);
            var key = Fixture.String("Secret");
            var user = CreateUser("bob", "dabadee", true);
            new SettingValues {SettingId = KnownSettingIds.ResetPasswordSecretKey, CharacterValue = key, User = user}.In(Db);
            f.CryptoService.Decrypt(Arg.Any<string>()).Returns(key);

            var request = new ResetPasswordController.ResetPasswordRequest()
            {
                Token = Fixture.String()
            };

            f.TaskSecurityProvider.UserHasAccessTo(user.Id, ApplicationTask.ChangeMyPassword).Returns(false);
            var response = await f.Subject.VerifyLink(request);
            f.Logger.Received(1).Warning(Arg.Is("bob | The user is not authorized to change password | Unauthorized"), Arg.Any<object>());
            Assert.Equal(System.Net.HttpStatusCode.BadRequest, response.StatusCode);

            f.TaskSecurityProvider.UserHasAccessTo(user.Id, ApplicationTask.ChangeMyPassword).Returns(true);
            user.IsLocked = true;
            response = await f.Subject.VerifyLink(request);
            f.Logger.Received(1).Warning(Arg.Is("bob | User account locked | UserLocked"), Arg.Any<object>());
            Assert.Equal(System.Net.HttpStatusCode.BadRequest, response.StatusCode);

            user.IsLocked = false;
            response = await f.Subject.VerifyLink(request);
            f.Logger.Received(1).Warning(Arg.Is("bob | User email not valid | UserEmailNotProvided"), Arg.Any<object>());
            Assert.Equal(System.Net.HttpStatusCode.BadRequest, response.StatusCode);
        }

        [Fact]
        public async Task LogWarningForTimestampGreaterThan30Minutes()
        {
            var f = new ResetPasswordControllerFixture(Db);
            var key = Fixture.String("Secret");
            var user = ReturnsUserWithEmail(f);
            new SettingValues {SettingId = KnownSettingIds.ResetPasswordSecretKey, CharacterValue = key, User = user, TimeStamp = DateTime.Now.Add(TimeSpan.FromMinutes(-45))}.In(Db);
            f.CryptoService.Decrypt(Arg.Any<string>()).Returns(key);

            var request = new ResetPasswordController.ResetPasswordRequest
            {
                Token = Fixture.String()
            };

            var response = await f.Subject.VerifyLink(request);
            f.Logger.Received(1).Warning(Arg.Is("bob | User reset password request has expired | RequestExpired"), Arg.Any<object>());
            Assert.Equal(System.Net.HttpStatusCode.BadRequest, response.StatusCode);
        }

        [Fact]
        public async Task PasswordNotUpdated()
        {
            var f = new ResetPasswordControllerFixture(Db);
            var key = Fixture.String("Secret");
            var user = ReturnsUserWithEmail(f);
            new SettingValues {SettingId = KnownSettingIds.ResetPasswordSecretKey, CharacterValue = key, User = user, TimeStamp = DateTime.Now.Add(TimeSpan.FromMinutes(-5))}.In(Db);
            f.CryptoService.Decrypt(Arg.Any<string>()).Returns(key);
            var pmResponse = new PasswordManagementResponse(PasswordManagementStatus.NewPasswordsDoNotMatch);
            f.PmController.UpdateUserPassword(Arg.Any<PasswordManagementRequest>()).Returns(pmResponse);
            var request = new ResetPasswordController.ResetPasswordRequest()
            {
                Token = Fixture.String()
            };

            var response = await f.Subject.VerifyLink(request);
            f.Logger.Received(1).Warning(Arg.Is("bob | " + pmResponse.Status + " | PasswordNotUpdated"), Arg.Any<object>());
            Assert.Equal(System.Net.HttpStatusCode.BadRequest, response.StatusCode);
        }
        
        [Fact]
        public async Task PasswordNotUpdatedIfOldPasswordInvalid()
        {
            var f = new ResetPasswordControllerFixture(Db);
            var key = Fixture.String("Secret");
            var user = ReturnsUserWithEmail(f);
            new SettingValues { SettingId = KnownSettingIds.ResetPasswordSecretKey, CharacterValue = key, User = user, TimeStamp = DateTime.Now.Add(TimeSpan.FromMinutes(-5)) }.In(Db);
            f.CryptoService.Decrypt(Arg.Any<string>()).Returns(key);
            var request = new ResetPasswordController.ResetPasswordRequest()
            {
                Token = Fixture.String(),
                OldPassword = "WrongPassword",
                IsPasswordExpired = true
            };
            var response = await f.Subject.VerifyLink(request);
            var result = await response.Content.ReadAsAsync<dynamic>();
            Assert.Equal(ResetPasswordController.ResetPasswordStatus.OldPasswordNotCorrect, result.Status);
        }

        [Fact]
        public async Task UpdatePassword()
        {
            var f = new ResetPasswordControllerFixture(Db);
            var key = Fixture.String("Secret");
            var user = ReturnsUserWithEmail(f);
            new SettingValues {SettingId = KnownSettingIds.ResetPasswordSecretKey, CharacterValue = key, User = user, TimeStamp = DateTime.Now.Add(TimeSpan.FromMinutes(-5))}.In(Db);
            f.CryptoService.Decrypt(Arg.Any<string>()).Returns(key);
            var pmResponse = new PasswordManagementResponse(PasswordManagementStatus.Success);
            f.PmController.UpdateUserPassword(Arg.Any<PasswordManagementRequest>()).Returns(pmResponse);
            var request = new ResetPasswordController.ResetPasswordRequest()
            {
                Token = Fixture.String()
            };

            var response = await f.Subject.VerifyLink(request);
            Assert.False(Db.Set<SettingValues>().Any(_ => _.SettingId == KnownSettingIds.ResetPasswordSecretKey && _.User == user));
            Assert.Equal(System.Net.HttpStatusCode.OK, response.StatusCode);
        }

    }
}
