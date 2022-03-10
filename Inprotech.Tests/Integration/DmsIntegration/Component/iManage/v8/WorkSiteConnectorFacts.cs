using IManage;
using Inprotech.Integration.DmsIntegration;
using Inprotech.Integration.DmsIntegration.Component;
using Inprotech.Integration.DmsIntegration.Component.iManage;
using Inprotech.Integration.DmsIntegration.Component.iManage.v8;
using NSubstitute;
using Xunit;

namespace Inprotech.Tests.Integration.DmsIntegration.Component.iManage.v8
{
    public class WorkSiteConnectorFacts
    {
        public class WhenLoginTypeIsUsernamePassword
        {
            readonly IManSession _iManSession = Substitute.For<IManSession>();

            readonly IManageSettings.SiteDatabaseSettings _settings = new IManageSettings.SiteDatabaseSettings
            {
                LoginType = IManageSettings.LoginTypes.UsernamePassword
            };

            readonly IDmsEventEmitter _dmsEventEmitter = Substitute.For<IDmsEventEmitter>();

            [Fact]
            public void RequiresUsernameAndPassword()
            {
                // usernames and passwords are derived ultimately 
                // from Login ID and WorkSite Password from user preference.
                // SETTINGID = 9 and 10 respectively.

                _iManSession.Connect(_dmsEventEmitter, _settings, "username", "password");

                _iManSession.Received(1).Login("username", "password");
            }

            [Fact]
            public void ThrowsExceptionWhenPasswordNotProvided()
            {
                Assert.Throws<AuthenticationException>(
                                                       () =>
                                                           _iManSession.Connect(_dmsEventEmitter, _settings, "username", null)
                                                      );
                _dmsEventEmitter.Received(1).Emit(Arg.Is<DocumentManagementEvent>(_ => _.Key == KnownDocumentManagementEvents.FailedLoginOrPasswordPreferences));
                _iManSession.DidNotReceiveWithAnyArgs().Login(null, null);
            }

            [Fact]
            public void ThrowsExceptionWhenUsernameNotProvided()
            {
                Assert.Throws<AuthenticationException>(
                                                       () =>
                                                           _iManSession.Connect(_dmsEventEmitter, _settings, null, "password")
                                                      );
                _dmsEventEmitter.Received(1).Emit(Arg.Is<DocumentManagementEvent>(_ => _.Key == KnownDocumentManagementEvents.FailedLoginOrPasswordPreferences));
                _iManSession.DidNotReceiveWithAnyArgs().Login(null, null);
            }
        }

        public class WhenLoginTypeIsTrustedLogin
        {
            readonly IManSession _iManSession = Substitute.For<IManSession>();
            readonly IDmsEventEmitter _dmsEventEmitter = Substitute.For<IDmsEventEmitter>();

            readonly IManageSettings.SiteDatabaseSettings _settings = new IManageSettings.SiteDatabaseSettings
            {
                LoginType = IManageSettings.LoginTypes.TrustedLogin
            };

            [Fact]
            public void CallsTrustedLogin()
            {
                // This usually evaluates to the Service Startup Account
                // i.e. NT AUTHORITY\NETWORK SERVICE

                _iManSession.Connect(_dmsEventEmitter, _settings, null, null);

                _iManSession.Received(1).TrustedLogin();
            }
        }

        public class WhenLoginTypeIsTrustedLogin2
        {
            readonly IManSession _iManSession = Substitute.For<IManSession>();
            readonly IDmsEventEmitter _dmsEventEmitter = Substitute.For<IDmsEventEmitter>();

            readonly IManageSettings.SiteDatabaseSettings _settings = new IManageSettings.SiteDatabaseSettings
            {
                LoginType = IManageSettings.LoginTypes.TrustedLogin2
            };

            [Fact]
            public void CallsTrustedLogin2WithExplicitIdentityToken()
            {
                // This usually evaluates to the Service Startup Account
                // WindowsIdentity.GetCurrent().Token.ToInt32()
                // i.e. NT AUTHORITY\NETWORK SERVICE

                _iManSession.Connect(_dmsEventEmitter, _settings, null, null);

                _iManSession.Received(1).TrustedLogin2(Arg.Any<int>());
            }
        }

        public class WhenLoginTypeIsUsernameWithImpersonation
        {
            readonly IManSession _iManSession = Substitute.For<IManSession>();
            readonly IDmsEventEmitter _dmsEventEmitter = Substitute.For<IDmsEventEmitter>();

            readonly IManageSettings.SiteDatabaseSettings _settings = new IManageSettings.SiteDatabaseSettings
            {
                LoginType = IManageSettings.LoginTypes.UsernameWithImpersonation,
                Password = "this is the master password"
            };

            [Fact]
            public void DoesNotUsePasswordPassedIn()
            {
                _iManSession.Connect(_dmsEventEmitter, _settings, "username", "not this one");

                _iManSession.DidNotReceive().Login("username", "not this one");
            }

            [Fact]
            public void RequiresUsernameAndImpersonationPassword()
            {
                // usernames is derived ultimately 
                // from Login ID from user preference.
                // SETTINGID = 9.

                _iManSession.Connect(_dmsEventEmitter, _settings, "username", null);

                _iManSession.Received(1).Login("username", _settings.Password);
            }

            [Fact]
            public void ThrowsExceptionWhenUsernameNotProvided()
            {
                Assert.Throws<AuthenticationException>(
                                                       () =>
                                                           _iManSession.Connect(_dmsEventEmitter, _settings, null, null)
                                                      );
                _dmsEventEmitter.Received(1).Emit(Arg.Is<DocumentManagementEvent>(_ => _.Key == KnownDocumentManagementEvents.MissingLoginPreference));
                _iManSession.DidNotReceiveWithAnyArgs().Login(null, null);
            }
        }

        public class WhenLoginTypeIsInprotechUsernameWithImpersonation
        {
            readonly IManSession _iManSession = Substitute.For<IManSession>();
            readonly IDmsEventEmitter _dmsEventEmitter = Substitute.For<IDmsEventEmitter>();

            readonly IManageSettings.SiteDatabaseSettings _settings = new IManageSettings.SiteDatabaseSettings
            {
                LoginType = IManageSettings.LoginTypes.InprotechUsernameWithImpersonation,
                Password = "this is the master password"
            };

            [Fact]
            public void DoesNotUsePasswordPassedIn()
            {
                _iManSession.Connect(_dmsEventEmitter, _settings, "username", "not this one");

                _iManSession.DidNotReceive().Login("username", "not this one");
            }

            [Fact]
            public void RequiresInprotechUsernameAndImpersonationPassword()
            {
                // usernames is derived SecurityContext.Current.User

                _iManSession.Connect(_dmsEventEmitter, _settings, "username", null);

                _iManSession.Received(1).Login("username", _settings.Password);
            }
        }
    }
}