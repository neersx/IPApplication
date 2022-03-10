using System;
using System.Threading.Tasks;
using Inprotech.Integration.DmsIntegration;
using Inprotech.Integration.DmsIntegration.Component;
using Inprotech.Integration.DmsIntegration.Component.iManage;
using Inprotech.Integration.DmsIntegration.Component.iManage.v10;
using Inprotech.Tests.Extensions;
using NSubstitute;
using Xunit;

namespace Inprotech.Tests.Integration.DmsIntegration.Component.iManage.v10
{
    public class WorkServerConnectorFacts
    {
        public class WhenLoginTypeIsUsernamePassword
        {
            readonly IWorkServerClient _iWorkServerClient = Substitute.For<IWorkServerClient>();
            readonly IDmsEventEmitter _dmsEventEmitter = Substitute.For<IDmsEventEmitter>();
            readonly IAccessTokenManager _accessTokenManager = Substitute.For<IAccessTokenManager>();
            readonly IManageSettings.SiteDatabaseSettings _settings = new IManageSettings.SiteDatabaseSettings
            {
                LoginType = IManageSettings.LoginTypes.UsernamePassword,
                Server = "https://work.imanage.com"
            };

            [Fact]
            public async Task RequiresUsernameAndPassword()
            {
                // usernames and passwords are derived ultimately 
                // from Login ID and WorkSite Password from user preference.
                // SETTINGID = 9 and 10 respectively.
                _iWorkServerClient.Login(Arg.Any<Uri>(), Arg.Any<string>(), Arg.Any<string>()).Returns(true);
                await _iWorkServerClient.Connect(_dmsEventEmitter, _settings, "username", "password", _accessTokenManager);
                _dmsEventEmitter.DidNotReceive().Emit(Arg.Is<DocumentManagementEvent>(_ => _.Key == KnownDocumentManagementEvents.FailedLoginOrPasswordPreferences));

                _iWorkServerClient.Received(1).Login(new Uri("https://work.imanage.com/api/v1/session/login"), "username", "password")
                                  .IgnoreAwaitForNSubstituteAssertion();
            }

            [Fact]
            public async Task ThrowsExceptionWhenPasswordNotProvided()
            {
                await Assert.ThrowsAsync<AuthenticationException>(() => _iWorkServerClient.Connect(_dmsEventEmitter, _settings, "username", null, _accessTokenManager));
                _dmsEventEmitter.Received(1).Emit(Arg.Is<DocumentManagementEvent>(_ => _.Key == KnownDocumentManagementEvents.FailedLoginOrPasswordPreferences));

                _iWorkServerClient.DidNotReceiveWithAnyArgs().Login(null, null, null)
                                  .IgnoreAwaitForNSubstituteAssertion();
            }

            [Fact]
            public async Task ThrowsExceptionWhenUsernameNotProvided()
            {
                await Assert.ThrowsAsync<AuthenticationException>(() => _iWorkServerClient.Connect(_dmsEventEmitter, _settings, null, "password", _accessTokenManager));
                _dmsEventEmitter.Received(1).Emit(Arg.Is<DocumentManagementEvent>(_ => _.Key == KnownDocumentManagementEvents.FailedLoginOrPasswordPreferences));
                _iWorkServerClient.DidNotReceiveWithAnyArgs().Login(null, null, null)
                                  .IgnoreAwaitForNSubstituteAssertion();
            }
        }

        public class WhenLoginTypeIsTrustedLogin
        {
            readonly IWorkServerClient _iWorkServerClient = Substitute.For<IWorkServerClient>();
            readonly IDmsEventEmitter _dmsEventEmitter = Substitute.For<IDmsEventEmitter>();
            readonly IAccessTokenManager _accessTokenManager = Substitute.For<IAccessTokenManager>();

            readonly IManageSettings.SiteDatabaseSettings _settings = new IManageSettings.SiteDatabaseSettings
            {
                LoginType = IManageSettings.LoginTypes.TrustedLogin,
                Server = "https://work.imanage.com"
            };

            [Fact]
            public async Task RequiresUsernameAndPassword()
            {
                // usernames and passwords are derived ultimately 
                // from Login ID and WorkSite Password from user preference.
                // SETTINGID = 9 and 10 respectively.

                await _iWorkServerClient.Connect(_dmsEventEmitter, _settings, "username", "password", _accessTokenManager);

                _iWorkServerClient.Received(1).Login(new Uri("https://work.imanage.com/api/v1/session/network-login"), "username", "password")
                                  .IgnoreAwaitForNSubstituteAssertion();
            }

            [Fact]
            public async Task ThrowsExceptionWhenPasswordNotProvided()
            {
                await Assert.ThrowsAsync<AuthenticationException>(() => _iWorkServerClient.Connect(_dmsEventEmitter, _settings, "username", null, _accessTokenManager));
                _dmsEventEmitter.Received(1).Emit(Arg.Is<DocumentManagementEvent>(_ => _.Key == KnownDocumentManagementEvents.FailedLoginOrPasswordPreferences));

                _iWorkServerClient.DidNotReceiveWithAnyArgs().Login(null, null, null)
                                  .IgnoreAwaitForNSubstituteAssertion();
            }

            [Fact]
            public async Task ThrowsExceptionWhenUsernameNotProvided()
            {
                await Assert.ThrowsAsync<AuthenticationException>(() => _iWorkServerClient.Connect(_dmsEventEmitter, _settings, null, "password", _accessTokenManager));
                _dmsEventEmitter.Received(1).Emit(Arg.Is<DocumentManagementEvent>(_ => _.Key == KnownDocumentManagementEvents.FailedLoginOrPasswordPreferences));

                _iWorkServerClient.DidNotReceiveWithAnyArgs().Login(null, null, null)
                                  .IgnoreAwaitForNSubstituteAssertion();
            }
        }

        public class WhenLoginTypeIsTrustedLogin2
        {
            readonly IDmsEventEmitter _dmsEventEmitter = Substitute.For<IDmsEventEmitter>();
            readonly IAccessTokenManager _accessTokenManager = Substitute.For<IAccessTokenManager>();

            readonly IManageSettings.SiteDatabaseSettings _settings = new IManageSettings.SiteDatabaseSettings
            {
                LoginType = IManageSettings.LoginTypes.TrustedLogin2,
                Server = "https://work.imanage.com"
            };

            [Fact]
            public async Task CallsTrustedLogin2WithExplicitIdentityToken()
            {
                // This usually evaluates to the Service Startup Account
                // WindowsIdentity.GetCurrent().Token.ToInt32()
                // i.e. NT AUTHORITY\NETWORK SERVICE

                var subject = Substitute.For<IWorkServerClient>();

                await Assert.ThrowsAsync<NotSupportedException>(() => subject.Connect(_dmsEventEmitter, _settings, null, null, _accessTokenManager));
                _dmsEventEmitter.Received(1).Emit(Arg.Is<DocumentManagementEvent>(_ => _.Key == KnownDocumentManagementEvents.NotSupported));
            }
        }

        public class WhenLoginTypeIsUsernameWithImpersonation
        {
            readonly IWorkServerClient _subject = Substitute.For<IWorkServerClient>();
            readonly IDmsEventEmitter _dmsEventEmitter = Substitute.For<IDmsEventEmitter>();
            readonly IAccessTokenManager _accessTokenManager = Substitute.For<IAccessTokenManager>();

            readonly IManageSettings.SiteDatabaseSettings _settings = new IManageSettings.SiteDatabaseSettings
            {
                LoginType = IManageSettings.LoginTypes.UsernameWithImpersonation,
                Password = "this is the master password",
                Server = "https://work.imanage.com"
            };

            [Fact]
            public async Task DoesNotUsePasswordPassedIn()
            {
                await _subject.Connect(_dmsEventEmitter, _settings, "username", "not this one", _accessTokenManager);

                _subject.DidNotReceive().Login(new Uri("https://work.imanage.com/api/v1/session/login"), "username", "not this one")
                        .IgnoreAwaitForNSubstituteAssertion();
            }

            [Fact]
            public async Task RequiresUsernameAndImpersonationPassword()
            {
                // usernames is derived ultimately 
                // from Login ID from user preference.
                // SETTINGID = 9.

                await _subject.Connect(_dmsEventEmitter, _settings, "username", null, _accessTokenManager);

                _subject.Received(1).Login(new Uri("https://work.imanage.com/api/v1/session/login"), "username", _settings.Password)
                        .IgnoreAwaitForNSubstituteAssertion();
            }

            [Fact]
            public async Task ThrowsExceptionWhenUsernameNotProvided()
            {
                await Assert.ThrowsAsync<AuthenticationException>(
                                                                  () =>
                                                                      _subject.Connect(_dmsEventEmitter, _settings, null, null, _accessTokenManager)
                                                                 );

                _subject.DidNotReceiveWithAnyArgs().Login(null, null, null)
                        .IgnoreAwaitForNSubstituteAssertion();
            }
        }

        public class WhenLoginTypeIsInprotechUsernameWithImpersonation
        {
            readonly IWorkServerClient _subject = Substitute.For<IWorkServerClient>();
            readonly IDmsEventEmitter _dmsEventEmitter = Substitute.For<IDmsEventEmitter>();
            readonly IAccessTokenManager _accessTokenManager = Substitute.For<IAccessTokenManager>();

            readonly IManageSettings.SiteDatabaseSettings _settings = new IManageSettings.SiteDatabaseSettings
            {
                LoginType = IManageSettings.LoginTypes.InprotechUsernameWithImpersonation,
                Password = "this is the master password",
                Server = "https://work.imanage.com"
            };

            [Fact]
            public async Task DoesNotUsePasswordPassedIn()
            {
                await _subject.Connect(_dmsEventEmitter, _settings, "username", "not this one", _accessTokenManager);

                _subject.DidNotReceive().Login(new Uri("https://work.imanage.com/api/v1/session/login"), "username", "not this one")
                        .IgnoreAwaitForNSubstituteAssertion();
            }

            [Fact]
            public async Task RequiresInprotechUsernameAndImpersonationPassword()
            {
                // usernames is derived SecurityContext.Current.User

                await _subject.Connect(_dmsEventEmitter, _settings, "username", null, _accessTokenManager);

                _subject.Received(1).Login(new Uri("https://work.imanage.com/api/v1/session/login"), "username", _settings.Password)
                        .IgnoreAwaitForNSubstituteAssertion();
            }
        }
    }
}