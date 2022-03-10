using System;
using System.Collections.Generic;
using Inprotech.Integration.Security.Licensing;
using NSubstitute;
using Xunit;

namespace Inprotech.Tests.Integration.Trinogy.Security
{
    public class LicenseAuthorizationFacts
    {
        public class LicenseAuthorizationFixture : IFixture<LicenseAuthorization>
        {
            public LicenseAuthorization Subject { get; private set; }

            public ILicenseSecurityProvider LicenseSecurityProvider { get; private set; }
            public List<RequiresLicenseAttribute> ControllerLevelAttributes { get; private set; }
            public Dictionary<int, LicenseData> ValidLicenses { get; set; }

            public LicenseAuthorizationFixture()
            {
                LicenseSecurityProvider = Substitute.For<ILicenseSecurityProvider>();

                ValidLicenses = new Dictionary<int, LicenseData>();

                LicenseSecurityProvider.ListUserLicenses()
                                .ReturnsForAnyArgs(c => ValidLicenses);

                ControllerLevelAttributes = new List<RequiresLicenseAttribute>();

                Subject = new LicenseAuthorization(LicenseSecurityProvider);
            }
        }

        public class AuthorizeMethod : FactBase
        {
            [Fact]
            public void ReturnsFalseWhenNoneOfLicenseIsGranted()
            {
                var f = new LicenseAuthorizationFixture();
                f.ControllerLevelAttributes.Add(new RequiresLicenseAttribute(LicensedModule.MarketingModule));
                f.ControllerLevelAttributes.Add(new RequiresLicenseAttribute(LicensedModule.CrmWorkBench));

                var r =  f.Subject.Authorize(f.ControllerLevelAttributes);

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
                                        DateTime.Now.AddDays(4)));

                var r = f.Subject.Authorize(f.ControllerLevelAttributes);

                Assert.True(r);
            }
        }
    }
}
