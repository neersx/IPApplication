using System;
using System.Collections.Generic;
using Inprotech.Infrastructure.Security;
using Inprotech.Infrastructure.Security.Licensing;
using NSubstitute;
using Xunit;

namespace Inprotech.Tests.Integration.ExternalApplications.Security
{
    public class LicenseAuthorizationFacts
    {
        public class LicenseAuthorizationFixture : IFixture<LicenseAuthorization>
        {
            public LicenseAuthorizationFixture()
            {
                LicenseSecurityProvider = Substitute.For<ILicenseSecurityProvider>();

                ValidLicenses = new Dictionary<int, LicenseData>();

                LicenseSecurityProvider.ListUserLicenses()
                                       .ReturnsForAnyArgs(c => ValidLicenses);

                SystemClock = Substitute.For<Func<DateTime>>();
                SystemClock().Returns(Fixture.Today());

                ControllerLevelAttributes = new List<RequiresLicenseAttribute>();

                Subject = new LicenseAuthorization(LicenseSecurityProvider);
            }

            public ILicenseSecurityProvider LicenseSecurityProvider { get; }
            public List<RequiresLicenseAttribute> ControllerLevelAttributes { get; }
            public Dictionary<int, LicenseData> ValidLicenses { get; set; }
            public Func<DateTime> SystemClock { get; }
            public LicenseAuthorization Subject { get; }
        }

        public class AuthorizeMethod : FactBase
        {
            [Fact]
            public void ReturnsFalseWhenNoneOfLicenseIsGranted()
            {
                var f = new LicenseAuthorizationFixture();
                f.ControllerLevelAttributes.Add(new RequiresLicenseAttribute(LicensedModule.MarketingModule));
                f.ControllerLevelAttributes.Add(new RequiresLicenseAttribute(LicensedModule.CrmWorkBench));

                var r = f.Subject.Authorize(f.ControllerLevelAttributes);

                Assert.False(r);
            }

            [Fact]
            public void ReturnsTrueWhenAdequateLicenseIsGranted()
            {
                var f = new LicenseAuthorizationFixture();
                f.ControllerLevelAttributes.Add(new RequiresLicenseAttribute(LicensedModule.MarketingModule));
                f.ControllerLevelAttributes.Add(new RequiresLicenseAttribute(LicensedModule.CrmWorkBench));

                f.ValidLicenses.Add(25,
                                    new LicenseData(25, "CrmWorkbench",
                                                    f.SystemClock().AddDays(4)));

                var r = f.Subject.Authorize(f.ControllerLevelAttributes);

                Assert.True(r);
            }
        }
    }
}