using Inprotech.Contracts;
using Inprotech.Infrastructure;
using Inprotech.Infrastructure.Messaging;
using Inprotech.Infrastructure.Security;
using Inprotech.Tests.Fakes;
using Inprotech.Web.Security;
using Inprotech.Web.Security.TwoFactorAuth;
using InprotechKaizen.Model.Components.Security;
using InprotechKaizen.Model.Security;
using NSubstitute;
using System;
using System.Threading.Tasks;
using Xunit;

namespace Inprotech.Tests.Web.Security
{
    public class PasswordManagementFacts : FactBase
    {
        readonly ILogger<PasswordManagementController> _logger;
        readonly ISecurityContext _securityContext;
        readonly PasswordManagementController _subject;
        readonly ITaskSecurityProvider _taskSecurityProvider;
        readonly IUserValidation _validation;
        readonly IPasswordPolicy _passwordPolicy;
        
        public PasswordManagementFacts()
        {
            var configuredAccess = Substitute.For<IConfiguredAccess>();
            configuredAccess.For(Arg.Any<User>()).Returns(true);

            var twoFactorAuthVerify = Substitute.For<ITwoFactorAuthVerify>();
            _validation = new UserValidation(Db,
                                             configuredAccess,
                                             Substitute.For<ISiteControlReader>(),
                                             Substitute.For<IBus>(),
                                             () => DateTime.Now, twoFactorAuthVerify);

            _securityContext = Substitute.For<ISecurityContext>();
            _taskSecurityProvider = Substitute.For<ITaskSecurityProvider>();
            _logger = Substitute.For<ILogger<PasswordManagementController>>();
            _passwordPolicy = Substitute.For<IPasswordPolicy>();
            _passwordPolicy.ShouldEnforcePasswordPolicy.Returns(false);
            var passwordVerifier = Substitute.For<IPasswordVerifier>();
            _subject = new PasswordManagementController(_validation, Db, _taskSecurityProvider, _securityContext, _logger, _passwordPolicy, passwordVerifier);
        }

        [Theory]
        [InlineData(true)]
        [InlineData(false)]
        public async Task InvalidPasswordFails(bool passwordMd5)
        {
            var user = CreateUser("bob", "dabadee", passwordMd5);
            _securityContext.User.Returns(user); // bob is the user
            _taskSecurityProvider.HasAccessTo(ApplicationTask.ChangeMyPassword).Returns(true); // bob is allowed to change password

            var result = await _subject.UpdateUserPassword(new PasswordManagementRequest
            {
                IdentityKey = user.Id,
                OldPassword = "wrongpassword",
                NewPassword = "goodPassword",
                ConfirmNewPassword = "goodPassword"
            });

            Assert.Equal(PasswordManagementStatus.OldPasswordNotCorrect, result.Status);
        }

        [Theory]
        [InlineData(true)]
        [InlineData(false)]
        public async Task EmptyPasswordFails(bool passwordMd5)
        {
            var user = CreateUser("bob", "dabadee", passwordMd5);

            _securityContext.User.Returns(user); // bob is the user
            _taskSecurityProvider.HasAccessTo(ApplicationTask.ChangeMyPassword).Returns(true); // bob is allowed to change password

            var result = await _subject.UpdateUserPassword(new PasswordManagementRequest
            {
                IdentityKey = user.Id,
                OldPassword = "dabadee",
                NewPassword = null, // empty!
                ConfirmNewPassword = null
            });

            Assert.Equal(PasswordManagementStatus.NewPasswordNotProvided, result.Status);
        }

        [Theory]
        [InlineData(true)]
        [InlineData(false)]
        public async Task MissmatchingPasswordsFail(bool passwordMd5)
        {
            var user = CreateUser("bob", "dabadee", passwordMd5);

            _securityContext.User.Returns(user); // bob is the user
            _taskSecurityProvider.HasAccessTo(ApplicationTask.ChangeMyPassword).Returns(true); // bob is allowed to change password

            var result = await _subject.UpdateUserPassword(new PasswordManagementRequest
            {
                IdentityKey = user.Id,
                OldPassword = "dabadee",
                NewPassword = "oneVersion",
                ConfirmNewPassword = "differentVersion" // different!
            });

            Assert.Equal(PasswordManagementStatus.NewPasswordsDoNotMatch, result.Status);
        }

        [Theory]
        [InlineData(true)]
        [InlineData(false)]
        public async Task FailsWhenUserHasNoPermissionsToChangePassword(bool passwordMd5)
        {
            var user = CreateUser("bob", "dabadee", passwordMd5);

            _taskSecurityProvider.HasAccessTo(ApplicationTask.ChangeMyPassword).Returns(false); // bob is allowed to change password

            var request = new PasswordManagementRequest
            {
                IdentityKey = user.Id,
                OldPassword = "dabadee",
                NewPassword = "goodPassword",
                ConfirmNewPassword = "goodPassword"
            };
            var result = await _subject.UpdateUserPassword(request);
            Assert.Equal(PasswordManagementStatus.NotPermitted, result.Status);

            _securityContext.User.Returns(user);
            result = await _subject.UpdateUserPassword(request);
            Assert.Equal(PasswordManagementStatus.NotPermitted, result.Status);

        }

        [Theory]
        [InlineData(true)]
        [InlineData(false)]
        public async Task CorrectPasswordWorks(bool passwordMd5)
        {
            var user = CreateUser("bob", "dabadee", passwordMd5);

            _securityContext.User.Returns(user); // bob is the user
            _taskSecurityProvider.HasAccessTo(ApplicationTask.ChangeMyPassword).Returns(true); // bob is allowed to change password

            var result = await _subject.UpdateUserPassword(new PasswordManagementRequest
            {
                IdentityKey = user.Id,
                OldPassword = "dabadee",
                NewPassword = "goodPassword",
                ConfirmNewPassword = "goodPassword"
            });

            Assert.Equal(PasswordManagementStatus.Success, result.Status);
        }

        [Theory]
        [InlineData(true)]
        [InlineData(false)]
        public async Task ChangeOthersPasswordWorks(bool passwordMd5)
        {
            var user = CreateUser("bob", "dabadee", passwordMd5);
            var admin = CreateUser("admin", "admin", false);

            _securityContext.User.Returns(admin); // admin is the user
            _taskSecurityProvider.HasAccessTo(ApplicationTask.ChangeUserPassword).Returns(true); // admin is allowed to change password

            var result = await _subject.UpdateUserPassword(new PasswordManagementRequest
            {
                IdentityKey = user.Id,
                OldPassword = null,
                NewPassword = "goodPassword",
                ConfirmNewPassword = "goodPassword"
            });

            Assert.Equal(PasswordManagementStatus.Success, result.Status);
        }

        [Theory]
        [InlineData(true)]
        [InlineData(false)]
        public async Task ChangeOthersPasswordFailsIfNotPermitted(bool passwordMd5)
        {
            var user = CreateUser("bob", "dabadee", passwordMd5);
            var nobody = CreateUser("nobody", "nobody", false);

            _securityContext.User.Returns(nobody); // nobody is the user
            _taskSecurityProvider.HasAccessTo(ApplicationTask.ChangeUserPassword).Returns(false); // nobody is not allowed

            var result = await _subject.UpdateUserPassword(new PasswordManagementRequest
            {
                IdentityKey = user.Id,
                OldPassword = null,
                NewPassword = "goodPassword",
                ConfirmNewPassword = "goodPassword"
            });

            Assert.Equal(PasswordManagementStatus.NotPermitted, result.Status);

            var validation = await _validation.Validate(user, "goodPassword");

            _logger.ReceivedWithAnyArgs(1).Warning(Arg.Any<string>());

            Assert.False(validation.Accepted);
        }

        [Theory]
        [InlineData(true)]
        [InlineData(false)]
        public async Task ChangeOthersPasswordFailsIfPermittedButFromOtherFirm(bool passwordMd5)
        {
            var user = CreateUser("bob", "dabadee", passwordMd5);
            var nobody = CreateUser("nobody", "nobody", false, true);

            var securityContextAccessAccount = new AccessAccount(1, "abc").In(Db);
            nobody.AccessAccount = securityContextAccessAccount;

            _securityContext.User.Returns(nobody); // nobody is the user
            _taskSecurityProvider.HasAccessTo(ApplicationTask.ChangeUserPassword).Returns(true); // nobody is not allowed

            var result = await _subject.UpdateUserPassword(new PasswordManagementRequest
            {
                IdentityKey = user.Id,
                OldPassword = null,
                NewPassword = "goodPassword",
                ConfirmNewPassword = "goodPassword"
            });

            Assert.Equal(PasswordManagementStatus.NotPermitted, result.Status);
            _logger.ReceivedWithAnyArgs(1).Warning(Arg.Any<string>());
            var validation = await _validation.Validate(user, "goodPassword");
            Assert.False(validation.Accepted);
        }

        [Theory]
        [InlineData(true)]
        [InlineData(false)]
        public async Task ShouldEnforcePasswordPolicyFail(bool passwordMd5)
        {
            var user = CreateUser("bob", "dabadee", passwordMd5);

            var response = new PasswordManagementResponse(PasswordManagementStatus.PasswordPolicyValidationFailed);

            _passwordPolicy.ShouldEnforcePasswordPolicy.Returns(true);
            _passwordPolicy.EnsureValid(Arg.Any<string>(), user).Returns(response);
            _securityContext.User.Returns(user); // bob is the user
            _taskSecurityProvider.HasAccessTo(ApplicationTask.ChangeMyPassword).Returns(true); // bob is allowed to change password

            var result = await _subject.UpdateUserPassword(new PasswordManagementRequest
            {
                IdentityKey = user.Id,
                OldPassword = "dabadee",
                NewPassword = "oneVersion",
                ConfirmNewPassword = "oneVersion" // different!
            });

            Assert.Equal(PasswordManagementStatus.PasswordPolicyValidationFailed, result.Status);
        }
    }
}