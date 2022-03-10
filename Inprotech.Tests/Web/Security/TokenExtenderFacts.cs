using System;
using System.Threading;
using System.Threading.Tasks;
using Inprotech.Infrastructure.Compatibility;
using Inprotech.Infrastructure.Security;
using Inprotech.Tests.Extensions;
using Inprotech.Web.Security;
using NSubstitute;
using NSubstitute.ExceptionExtensions;
using Xunit;

namespace Inprotech.Tests.Web.Security
{
    public class TokenExtenderFacts
    {
        const int UserId = 1;
        const int DefaultExtensionToleranceMinutes = 3;

        public class DoesNotExtendWhenValidationFailures
        {
            [Theory]
            [InlineData(AuthenticationModeKeys.Forms)]
            [InlineData(AuthenticationModeKeys.Windows)]
            public async Task NonSsoLastActiveLoginNotFound(string authMode)
            {
                var fixture = new TokenExtenderFixture();
                var cookieData = TokenExtenderFixture.GetCookieData(UserId, authMode);

                fixture.UserIdentityAccessManager.When(x => x.TryExtendProviderSession(cookieData.LogId, cookieData.UserId, authMode, null, DefaultExtensionToleranceMinutes))
                       .Do(x => throw new Exception());

                var r = await fixture.Subject.ShouldExtend(cookieData);
                Assert.False(r.shouldExtend);
                Assert.False(r.tokenValid);
            }

            [Theory]
            [InlineData(AuthenticationModeKeys.Sso)]
            [InlineData(AuthenticationModeKeys.Adfs)]
            public async Task SsoLastActiveLoginNotFound(string authMode)
            {
                var fixture = new TokenExtenderFixture();
                var cookieData = TokenExtenderFixture.GetCookieData(UserId, authMode);

                fixture.UserIdentityAccessManager.When(x => x.ExtendProviderSession(cookieData.LogId, cookieData.UserId, authMode, Arg.Any<UserIdentityAccessData>()))
                       .Do(x => throw new Exception());

                var r = await fixture.Subject.ShouldExtend(cookieData);
                Assert.False(r.shouldExtend);
                Assert.False(r.tokenValid);
            }

            [Fact]
            public async Task AuthModeNotEnabled()
            {
                var fixture = new TokenExtenderFixture().WithDisabledAuthModes();
                var r = await fixture.Subject.ShouldExtend(TokenExtenderFixture.GetCookieData(UserId, AuthenticationModeKeys.Forms));
                Assert.False(r.shouldExtend);
                Assert.False(r.tokenValid);
            }

            [Fact]
            public async Task InvalidAuthMode()
            {
                var cookieData = TokenExtenderFixture.GetCookieData(UserId, "invalidAuthMode");
                var fixture = new TokenExtenderFixture();

                var r = await fixture.Subject.ShouldExtend(cookieData);

                Assert.False(r.shouldExtend);
                Assert.False(r.tokenValid);
            }

            [Fact]
            public async Task MultipleRequestsShouldNotReValidateSso()
            {
                var cookieData = TokenExtenderFixture.GetCookieData(UserId);

                var firstRequest = new TokenExtenderFixture().WithExtendSession(cookieData);
                var secondRequest = new TokenExtenderFixture().WithExtendSession(cookieData);
                var thirdRequest = new TokenExtenderFixture().WithNewToken(cookieData);

                var firstRequestExtension = new ManualResetEvent(false);
                var blocked = new ManualResetEvent(false);

                firstRequest.TokenRefresh.Refresh(Arg.Any<string>(), Arg.Any<string>(), Arg.Any<string>())
                            .Returns(_ =>
                            {
                                firstRequestExtension.Set();
                                blocked.WaitOne();

                                return (firstRequest.NewAccessToken, firstRequest.NewRefreshToken);
                            });

                var t1 = Task.Run(async () => await firstRequest.Subject.ShouldExtend(cookieData));

                firstRequestExtension.WaitOne();

                var second = await secondRequest.Subject.ShouldExtend(cookieData);

                blocked.Set();

                var first = t1.Result;

                var third = await thirdRequest.Subject.ShouldExtend(cookieData);

                Assert.True(first.shouldExtend);
                Assert.True(first.tokenValid);

                Assert.False(second.shouldExtend);
                Assert.True(second.tokenValid);

                Assert.True(third.shouldExtend);
                Assert.True(third.tokenValid);
            }

            [Fact]
            public async Task NoCookieData()
            {
                var fixture = new TokenExtenderFixture();

                var r = await fixture.Subject.ShouldExtend(null);

                Assert.False(r.shouldExtend);
                Assert.False(r.tokenValid);
            }

            [Fact]
            public async Task NoCookieDataPre12_1()
            {
                var fixture = new TokenExtenderFixture().WithOlderThan12_1();

                var r = await fixture.Subject.ShouldExtend(null);

                Assert.False(r.shouldExtend);
                Assert.True(r.tokenValid);
            }
        }

        public class ShouldExtendSession
        {
            [Theory]
            [InlineData(AuthenticationModeKeys.Forms)]
            [InlineData(AuthenticationModeKeys.Windows)]
            public async Task NonSsoExtension(string authMode)
            {
                var cookieData = TokenExtenderFixture.GetCookieData(UserId, authMode);
                var fixture = new TokenExtenderFixture().WithExtendSession(cookieData);
                fixture.UserIdentityAccessManager.TryExtendProviderSession(Arg.Any<long>(), Arg.Any<int>(), Arg.Any<string>(), Arg.Any<UserIdentityAccessData>(), Arg.Any<int>()).Returns(true);

                var r = await fixture.Subject.ShouldExtend(cookieData);

                Assert.True(r.shouldExtend);
                Assert.True(r.tokenValid);
                fixture.UserIdentityAccessManager.Received(1).TryExtendProviderSession(cookieData.LogId, cookieData.UserId, authMode, null, DefaultExtensionToleranceMinutes).IgnoreAwaitForNSubstituteAssertion();
            }

            [Theory]
            [InlineData(AuthenticationModeKeys.Forms)]
            [InlineData(AuthenticationModeKeys.Windows)]
            public async Task NonSsoExtensionWithLowerSessionTimeOut(string authMode)
            {
                var cookieData = TokenExtenderFixture.GetCookieData(UserId, authMode);
                var fixture = new TokenExtenderFixture().WithExtendSession(cookieData).WithSessionTimeout(DefaultExtensionToleranceMinutes - 1);
                fixture.UserIdentityAccessManager.TryExtendProviderSession(Arg.Any<long>(), Arg.Any<int>(), Arg.Any<string>(), Arg.Any<UserIdentityAccessData>(), Arg.Any<int>()).Returns(true);

                var r = await fixture.Subject.ShouldExtend(cookieData);

                Assert.True(r.shouldExtend);
                Assert.True(r.tokenValid);
                fixture.UserIdentityAccessManager.Received(1).TryExtendProviderSession(cookieData.LogId, cookieData.UserId, authMode, null, 0).IgnoreAwaitForNSubstituteAssertion();
            }

            [Theory]
            [InlineData(AuthenticationModeKeys.Forms)]
            [InlineData(AuthenticationModeKeys.Windows)]
            public async Task NonSsoExtensionWithinTolerance(string authMode)
            {
                var cookieData = TokenExtenderFixture.GetCookieData(UserId, authMode);
                var fixture = new TokenExtenderFixture().WithExtendSession(cookieData);
                fixture.UserIdentityAccessManager.TryExtendProviderSession(Arg.Any<long>(), Arg.Any<int>(), Arg.Any<string>(), Arg.Any<UserIdentityAccessData>(), Arg.Any<int>()).Returns(false);

                var r = await fixture.Subject.ShouldExtend(cookieData);

                Assert.False(r.shouldExtend);
                Assert.True(r.tokenValid);
                fixture.UserIdentityAccessManager.Received(1).TryExtendProviderSession(cookieData.LogId, cookieData.UserId, authMode, null, DefaultExtensionToleranceMinutes).IgnoreAwaitForNSubstituteAssertion();
            }

            [Theory]
            [InlineData(AuthenticationModeKeys.Sso)]
            [InlineData(AuthenticationModeKeys.Adfs)]
            public async Task SsoExtension(string authMode)
            {
                var cookieData = TokenExtenderFixture.GetCookieData(UserId, authMode);
                var fixture = new TokenExtenderFixture().WithNewToken(cookieData);

                var r = await fixture.Subject.ShouldExtend(cookieData);

                Assert.True(r.shouldExtend);
                Assert.True(r.tokenValid);
                fixture.TokenRefresh.Received(1).Refresh(fixture.StoredAccessToken, fixture.StoredRefreshToken, authMode);
                fixture.UserIdentityAccessManager
                       .Received(1)
                       .ExtendProviderSession(cookieData.LogId, cookieData.UserId, authMode,
                                              Arg.Is<UserIdentityAccessData>(_ => _.RefreshToken == fixture.NewRefreshToken && _.AccessToken == fixture.NewAccessToken))
                       .IgnoreAwaitForNSubstituteAssertion();
            }
        }

        public class SsoToken
        {
            [Fact]
            public async Task DoesExtendSessionIfLastExtensionWithinToleranceButLowerThanSessionTimeout()
            {
                var fixture = new TokenExtenderFixture().WithSessionTimeout(DefaultExtensionToleranceMinutes - 1);

                var cookieData = TokenExtenderFixture.GetCookieData(UserId);
                fixture.UserIdentityAccessManager.GetSigninData(cookieData.LogId, UserId, AuthenticationModeKeys.Sso).Returns((new UserIdentityAccessData(Fixture.String(), Fixture.String(), Fixture.String()), Fixture.Today()));

                var r = await fixture.Subject.ShouldExtend(cookieData);

                Assert.True(r.shouldExtend);
                Assert.True(r.tokenValid);
                fixture.TokenRefresh.DidNotReceiveWithAnyArgs().Refresh(Arg.Any<string>(), Arg.Any<string>(), Arg.Any<string>());
                fixture.UserIdentityAccessManager.DidNotReceiveWithAnyArgs()
                       .ExtendProviderSession(Arg.Any<long>(), Arg.Any<int>(), Arg.Any<string>(), Arg.Any<UserIdentityAccessData>())
                       .IgnoreAwaitForNSubstituteAssertion();
            }

            [Fact]
            public async Task DoesNotExtendSessionIfAccessTokenThrows()
            {
                var cookieData = TokenExtenderFixture.GetCookieData(UserId);

                var fixture = new TokenExtenderFixture().WithNewToken(cookieData);
                fixture.TokenRefresh.Refresh(Arg.Any<string>(), Arg.Any<string>(), Arg.Any<string>()).ThrowsForAnyArgs(new Exception());

                var r = await fixture.Subject.ShouldExtend(cookieData);

                Assert.False(r.shouldExtend);
                Assert.False(r.tokenValid);

                fixture.UserIdentityAccessManager
                       .DidNotReceiveWithAnyArgs()
                       .ExtendProviderSession(Arg.Any<long>(), Arg.Any<int>(), Arg.Any<string>(), Arg.Any<UserIdentityAccessData>())
                       .IgnoreAwaitForNSubstituteAssertion();
            }

            [Fact]
            public async Task DoesNotExtendSessionIfLastExtensionWithinTolerance()
            {
                var fixture = new TokenExtenderFixture();

                var cookieData = TokenExtenderFixture.GetCookieData(UserId);
                fixture.UserIdentityAccessManager.GetSigninData(cookieData.LogId, UserId, AuthenticationModeKeys.Sso).Returns((new UserIdentityAccessData(Fixture.String(), Fixture.String(), Fixture.String()), Fixture.Today()));

                var r = await fixture.Subject.ShouldExtend(cookieData);

                Assert.False(r.shouldExtend);
                Assert.True(r.tokenValid);
                fixture.TokenRefresh.DidNotReceiveWithAnyArgs().Refresh(Arg.Any<string>(), Arg.Any<string>(), Arg.Any<string>());
                fixture.UserIdentityAccessManager.DidNotReceiveWithAnyArgs()
                       .ExtendProviderSession(Arg.Any<long>(), Arg.Any<int>(), Arg.Any<string>(), Arg.Any<UserIdentityAccessData>())
                       .IgnoreAwaitForNSubstituteAssertion();
            }

            [Fact]
            public async Task DoesNotExtendSessionIfRefreshTokenNotFoundOrLastActiveLoginNotFound()
            {
                var fixture = new TokenExtenderFixture();

                var cookieData = TokenExtenderFixture.GetCookieData(UserId);
                fixture.AuthSettings.AuthenticationModeEnabled(cookieData.AuthMode).Returns(true);
                fixture.UserIdentityAccessManager.GetSigninData(cookieData.LogId, UserId, AuthenticationModeKeys.Sso).Returns((null, Fixture.PastDate()));

                var r = await fixture.Subject.ShouldExtend(cookieData);

                Assert.False(r.shouldExtend);
                Assert.False(r.tokenValid);
            }

            [Fact]
            public async Task ExtendSessionAndRecordThatInformationForAdfs()
            {
                var fixture = new TokenExtenderFixture();

                var cookieData = TokenExtenderFixture.GetCookieData(UserId, AuthenticationModeKeys.Adfs);
                fixture.AuthSettings.AuthenticationModeEnabled(cookieData.AuthMode).Returns(true);
                fixture.UserIdentityAccessManager.GetSigninData(cookieData.LogId, UserId, AuthenticationModeKeys.Adfs)
                       .Returns((new UserIdentityAccessData {AccessToken = fixture.StoredAccessToken, RefreshToken = fixture.StoredRefreshToken}, Fixture.PastDate()));
                fixture.TokenRefresh.Refresh(Arg.Any<string>(), Arg.Any<string>(), AuthenticationModeKeys.Adfs)
                       .Returns((fixture.NewAccessToken, fixture.NewRefreshToken));

                var r = await fixture.Subject.ShouldExtend(cookieData);

                Assert.True(r.shouldExtend);
                Assert.True(r.tokenValid);

                fixture.TokenRefresh.Received(1).Refresh(fixture.StoredAccessToken, fixture.StoredRefreshToken, AuthenticationModeKeys.Adfs);
                fixture.UserIdentityAccessManager
                       .Received(1)
                       .ExtendProviderSession(cookieData.LogId, cookieData.UserId, AuthenticationModeKeys.Adfs, Arg.Is<UserIdentityAccessData>(_ => _.RefreshToken == fixture.NewRefreshToken))
                       .IgnoreAwaitForNSubstituteAssertion();
            }
        }

        public class TokenExtenderFixture : IFixture<ITokenExtender>
        {
            public TokenExtenderFixture()
            {
                AuthSettings = Substitute.For<IAuthSettings>();
                UserIdentityAccessManager = Substitute.For<IUserIdentityAccessManager>();
                TokenRefresh = Substitute.For<ITokenRefresh>();
                InprotechVersionChecker = Substitute.For<IInprotechVersionChecker>();

                AuthSettings.AuthenticationModeEnabled(Arg.Any<string>()).Returns(true);
                AuthSettings.SessionTimeout.Returns(120);
                InprotechVersionChecker.CheckMinimumVersion(Arg.Any<int>(), Arg.Any<int>()).Returns(true);

                Subject = new TokenExtender(AuthSettings, UserIdentityAccessManager, TokenRefresh, InprotechVersionChecker, Fixture.Today);
            }

            public IAuthSettings AuthSettings { get; set; }

            public IUserIdentityAccessManager UserIdentityAccessManager { get; set; }
            public ITokenRefresh TokenRefresh { get; }

            public IInprotechVersionChecker InprotechVersionChecker { get; }

            public string StoredAccessToken => "Access";
            public string StoredRefreshToken => "Refresh";
            public string NewAccessToken => "NewAccessToken";
            public string NewRefreshToken => "NewRefresh";

            public ITokenExtender Subject { get; }

            public static AuthCookieData GetCookieData(int userId, string authMode = AuthenticationModeKeys.Sso)
            {
                return new AuthCookieData(new AuthUser("name", userId, authMode, 1), false);
            }

            public TokenExtenderFixture WithNewToken(AuthCookieData cookieData)
            {
                WithExtendSession(cookieData);
                TokenRefresh.Refresh(Arg.Any<string>(), Arg.Any<string>(), AuthenticationModeKeys.Adfs)
                            .Returns((
                                         NewAccessToken, NewRefreshToken
                                     ));
                TokenRefresh.Refresh(Arg.Any<string>(), Arg.Any<string>(), AuthenticationModeKeys.Sso)
                            .Returns((
                                         NewAccessToken, NewRefreshToken
                                     ));

                return this;
            }

            public TokenExtenderFixture WithAccessToken(AuthCookieData cookieData)
            {
                WithExtendSession(cookieData);
                TokenRefresh.Refresh(Arg.Any<string>(), Arg.Any<string>(), AuthenticationModeKeys.Sso)
                            .Returns((
                                         StoredAccessToken, StoredRefreshToken
                                     ));
                return this;
            }

            public TokenExtenderFixture WithExtendSession(AuthCookieData cookieData)
            {
                AuthSettings.AuthenticationModeEnabled(cookieData.AuthMode).Returns(true);
                UserIdentityAccessManager.GetSigninData(cookieData.LogId, cookieData.UserId, cookieData.AuthMode)
                                         .Returns((new UserIdentityAccessData
                                         {
                                             RefreshToken = StoredRefreshToken,
                                             AccessToken = StoredAccessToken
                                         }, Fixture.PastDate()));

                return this;
            }

            public TokenExtenderFixture WithOlderThan12_1()
            {
                InprotechVersionChecker.CheckMinimumVersion(12, 1).Returns(false);
                return this;
            }

            public TokenExtenderFixture WithDisabledAuthModes()
            {
                AuthSettings.AuthenticationModeEnabled(Arg.Any<string>()).Returns(false);
                return this;
            }

            public TokenExtenderFixture WithSessionTimeout(int sessionTimeout)
            {
                AuthSettings.SessionTimeout.Returns(sessionTimeout);
                return this;
            }
        }
    }
}