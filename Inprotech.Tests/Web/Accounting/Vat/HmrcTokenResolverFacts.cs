using System;
using System.Linq;
using Inprotech.Contracts;
using Inprotech.Tests.Fakes;
using Inprotech.Tests.Web.Builders.Model.Security;
using Inprotech.Web.Accounting.VatReturns;
using InprotechKaizen.Model;
using InprotechKaizen.Model.Components.Security;
using InprotechKaizen.Model.Security;
using NSubstitute;
using Xunit;

namespace Inprotech.Tests.Web.Accounting.Vat
{
    public class HmrcTokenResolverFacts
    {
        public class Resolver : FactBase
        {
            [Fact]
            public void SaveAndEncryptsTokens()
            {
                var encryptedTokens = Fixture.String();
                var vrn = "987654321";
                var f = new HmrcTokenResolverFixture(Db);
                f.SecurityContext.User.Returns(new UserBuilder(Db).Build());
                f.CryptoService.Encrypt(Arg.Any<string>()).Returns(encryptedTokens);
                f.Subject.SaveTokens(new HmrcTokens(), vrn);

                var savedToken = Db.Set<ExternalCredentials>().Single(v => v.ProviderName == KnownExternalSettings.HmrcVatSettings + vrn);
                Assert.Equal(encryptedTokens, savedToken.Password);
            }

            [Fact]
            public void RetrievesAndDecryptsTokens()
            {
                var tokenString = "{\"AccessToken\": \"AAA\", \"RefreshToken\": \"BBB\"}";
                var vrn = "123456789000";
                var f = new HmrcTokenResolverFixture(Db);
                f.CryptoService.Decrypt(Arg.Any<string>()).Returns(tokenString);
                f.SecurityContext.User.Returns(new UserBuilder(Db).Build());
                new ExternalCredentials(f.SecurityContext.User, "taxDude", tokenString, KnownExternalSettings.HmrcVatSettings+ vrn).In(Db);

                f.Subject.Resolve(vrn);
                f.CryptoService.Received(1).Decrypt(tokenString);
            }

            [Theory]
            [InlineData("", true)]
            [InlineData("123456789", true)]
            public void ValidatesVrn(string vrn, bool valid)
            {
                var f = new HmrcTokenResolverFixture(Db);
                var result = f.Subject.ProviderName(vrn);

                Assert.Equal(valid, result == KnownExternalSettings.HmrcVatSettings + vrn);
            }

            [Fact]
            public void ValidatesVrnThrowsWhenInvalid()
            {
                var f = new HmrcTokenResolverFixture(Db);

                Assert.Throws<Exception>(() => f.Subject.ProviderName("12345678"));
            }
        }

        public class HmrcTokenResolverFixture : IFixture<HmrcTokenResolver>
        {
            public HmrcTokenResolverFixture(InMemoryDbContext db)
            {
                DbContext = db;
                SecurityContext = Substitute.For<ISecurityContext>();
                CryptoService = Substitute.For<ICryptoService>();
                Subject = new HmrcTokenResolver(DbContext, SecurityContext, CryptoService);
            }

            public InMemoryDbContext DbContext { get; set; }
            public ISecurityContext SecurityContext { get; set; }
            public ICryptoService CryptoService { get; set; }
            public HmrcTokenResolver Subject { get; }
        }
    }
}