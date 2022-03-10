using System;
using System.Security.Principal;
using System.Threading;
using Inprotech.Infrastructure.Caching;
using Inprotech.Infrastructure.Security.ExternalApplications;
using InprotechKaizen.Model.Components;
using InprotechKaizen.Model.Components.Security;
using InprotechKaizen.Model.Security;
using NSubstitute;
using Xunit;

namespace Inprotech.Tests.Model.Components
{
    public class WebSecurityContextFacts
    {
        readonly string _user = Fixture.String();
        readonly IPrincipalUser _principalUser = Substitute.For<IPrincipalUser>();

        static void EnsureEnvironment(Action test)
        {
            var current = Thread.CurrentPrincipal;
            try
            {
                test();
            }
            finally
            {
                Thread.CurrentPrincipal = current;
            }
        }

        [Fact]
        public void ShouldNotReturnUserFromTrustedApplicationApiWhenEmpty()
        {
            EnsureEnvironment(
                              () =>
                              {
                                  Thread.CurrentPrincipal = new ExternalApplicationPrincipal(string.Empty);

                                  Assert.Null(new WebSecurityContext(_principalUser, new LifetimeScopeCache()).User);

                                  _principalUser.DidNotReceive().From(Arg.Any<IPrincipal>());
                              });
        }

        [Fact]
        public void ShouldReturnUser()
        {
            EnsureEnvironment(
                              () =>
                              {
                                  Thread.CurrentPrincipal = new GenericPrincipal(new GenericIdentity(_user), new string[0]);

                                  var u = new User(_user, true);

                                  _principalUser.From(Arg.Any<IPrincipal>()).Returns(u);

                                  Assert.Equal(u, new WebSecurityContext(_principalUser, new LifetimeScopeCache()).User);
                              });
        }

        [Fact]
        public void ShouldReturnUserFromTrustedApplicationApi()
        {
            EnsureEnvironment(
                              () =>
                              {
                                  Thread.CurrentPrincipal = new ExternalApplicationPrincipal(_user);

                                  var u = new User(_user, true);

                                  _principalUser.From(Arg.Any<IPrincipal>()).Returns(u);

                                  Assert.Equal(u, new WebSecurityContext(_principalUser, new LifetimeScopeCache()).User);
                              });
        }
    }
}