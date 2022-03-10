using System;
using System.Security.Claims;
using CPA.SingleSignOn.Client.Models;
using CPA.SingleSignOn.Client.Services;
using Inprotech.Infrastructure.Security;
using Inprotech.Web.Security;
using NSubstitute;
using NSubstitute.ExceptionExtensions;
using Xunit;

namespace Inprotech.Tests.Web.Security
{
    public class TokenRefreshFacts
    {
        public class TokenRefreshFixture : IFixture<ITokenRefresh>
        {
            public TokenRefreshFixture()
            {
                TokenManagement = Substitute.For<ITokenManagementService>();
                AdfsAuthenticator = Substitute.For<IAdfsAuthenticator>();
                TokenValidationService = Substitute.For<ITokenValidationService>();

                Subject = new TokenRefresh(AdfsAuthenticator, TokenValidationService, TokenManagement);
            }

            public IAdfsAuthenticator AdfsAuthenticator { get; set; }
            public ITokenManagementService TokenManagement { get; set; }
            public ITokenValidationService TokenValidationService { get; set; }

            public string StoredAccessToken => "Access";
            public string StoredRefreshToken => "Refresh";
            public string NewAccessToken => "NewAccessToken";
            public string NewRefreshToken => "NewRefresh";

            public ITokenRefresh Subject { get; }

            public TokenRefreshFixture WithNewTokens()
            {
                TokenValidationService.ValidateToPrincipal(Arg.Any<string>()).ThrowsForAnyArgs(new Exception());
                TokenManagement.Refresh(Arg.Any<string>())
                               .Returns(new SSOProviderResponse
                               {
                                   AccessToken = NewAccessToken,
                                   RefreshToken = NewRefreshToken
                               });

                return this;
            }

            public TokenRefreshFixture WithSameAccessToken()
            {
                TokenValidationService.ValidateToPrincipal(Arg.Any<string>()).Returns(new ClaimsPrincipal());
                return this;
            }

            public TokenRefreshFixture WithAdfsToken(string accessToken, string refreshToken)
            {
                AdfsAuthenticator.Refresh(Arg.Any<string>())
                                 .Returns(new SSOProviderResponse
                                 {
                                     AccessToken = accessToken,
                                     RefreshToken = refreshToken
                                 });
                return this;
            }
        }

        [Fact]
        public void ReturnsNewTokensIfSessionNotValid()
        {
            var fixture = new TokenRefreshFixture().WithNewTokens();

            var (accessToken, refreshToken) = fixture.Subject.Refresh(fixture.StoredAccessToken, fixture.StoredRefreshToken, AuthenticationModeKeys.Sso);

            Assert.Equal(fixture.NewAccessToken, accessToken);
            Assert.Equal(fixture.NewRefreshToken, refreshToken);

            fixture.TokenValidationService.Received(1).ValidateToPrincipal(fixture.StoredAccessToken);
            fixture.TokenManagement.Received(1).Refresh(fixture.StoredRefreshToken);
            fixture.AdfsAuthenticator.DidNotReceiveWithAnyArgs().Refresh(Arg.Any<string>());
        }

        [Fact]
        public void ReturnsSameTokensIfSessionValid()
        {
            var fixture = new TokenRefreshFixture().WithSameAccessToken();

            var (accessToken, refreshToken) = fixture.Subject.Refresh(fixture.StoredAccessToken, fixture.StoredRefreshToken, AuthenticationModeKeys.Sso);

            Assert.Equal(fixture.StoredAccessToken, accessToken);
            Assert.Equal(fixture.StoredRefreshToken, refreshToken);

            fixture.TokenValidationService.Received(1).ValidateToPrincipal(fixture.StoredAccessToken);
            fixture.TokenManagement.DidNotReceiveWithAnyArgs().Refresh(Arg.Any<string>());
            fixture.AdfsAuthenticator.DidNotReceiveWithAnyArgs().Refresh(Arg.Any<string>());
        }

        [Fact]
        public void ReturnsTokensForAdfs()
        {
            var fixture = new TokenRefreshFixture();
            fixture = fixture.WithAdfsToken(fixture.NewAccessToken, fixture.NewRefreshToken);

            var (accessToken, refreshToken) = fixture.Subject.Refresh(fixture.StoredAccessToken, fixture.StoredRefreshToken, AuthenticationModeKeys.Adfs);

            Assert.Equal(fixture.NewAccessToken, accessToken);
            Assert.Equal(fixture.NewRefreshToken, refreshToken);

            fixture.TokenValidationService.DidNotReceiveWithAnyArgs().ValidateToPrincipal(Arg.Any<string>());
            fixture.TokenManagement.DidNotReceiveWithAnyArgs().Refresh(Arg.Any<string>());
            fixture.AdfsAuthenticator.Received(1).Refresh(fixture.StoredRefreshToken);
        }

        [Fact]
        public void ThrowsIfAuthModeNotValid()
        {
            var fixture = new TokenRefreshFixture().WithNewTokens();
            fixture = fixture.WithAdfsToken(fixture.NewAccessToken, fixture.NewRefreshToken);

            fixture.Subject.Refresh(fixture.StoredAccessToken, fixture.StoredRefreshToken, AuthenticationModeKeys.Adfs);
            fixture.Subject.Refresh(fixture.StoredAccessToken, fixture.StoredRefreshToken, AuthenticationModeKeys.Sso);

            Assert.Throws<Exception>(() => fixture.Subject.Refresh(fixture.StoredAccessToken, fixture.StoredRefreshToken, AuthenticationModeKeys.Windows));
            Assert.Throws<Exception>(() => fixture.Subject.Refresh(fixture.StoredAccessToken, fixture.StoredRefreshToken, AuthenticationModeKeys.Forms));
        }
    }
}