using System.Linq;
using System.Net.Http;
using Inprotech.Infrastructure.Caching;
using Inprotech.Infrastructure.Localisation;
using Inprotech.Infrastructure.Web;
using NSubstitute;
using Xunit;

namespace Inprotech.Tests.Infrastructure.ResponseEnrichment.Localisation
{
    public class PreferredCultureResolverFacts
    {
        public class PreferredCultureResolverFixture : IFixture<PreferredCultureResolver>
        {
            public PreferredCultureResolverFixture()
            {
                PreferredCultureSettings = Substitute.For<IPreferredCultureSettings>();
                RequestContext = Substitute.For<IRequestContext>();

                Subject = new PreferredCultureResolver(PreferredCultureSettings, RequestContext);
            }

            public IPreferredCultureSettings PreferredCultureSettings { get; set; }
            public IRequestContext RequestContext { get; }
            public PreferredCultureResolver Subject { get; }
        }

        public class ResolveAll
        {
            [Fact]
            public void ShouldUseCurrentRequestContext()
            {
                var f = new PreferredCultureResolverFixture();
                f.Subject.Resolve();

                var _ = f.RequestContext.Received(1).Request;
            }
        }

        public class ResolveWithMethod
        {
            [Theory]
            [InlineData("zh-CN", "zh-CHS")]
            [InlineData("en-AU", "en")]
            public void ReturnsSpecificCultureAndParentLanguageAsSecondChoice(string specificCulture, string parentCulture)
            {
                var f = new PreferredCultureResolverFixture();

                f.PreferredCultureSettings.ResolveAll().Returns(new[] {specificCulture});

                var result = f.Subject.ResolveWith(new HttpRequestMessage().Headers).ToArray();

                Assert.Equal(specificCulture, result.First());
                Assert.Equal(parentCulture, result.Last());
            }

            [Theory]
            [InlineData("en-US,en;q=0.8,en-AU;q=0.6", "en-US,en,en-US,en,en-AU,en")]
            [InlineData("en;q=0.8,zh;q=0.6,de;q=0.4", "en-US,en,zh-CN,zh,de-DE,de")]
            public void ReturnsBrowserSentAcceptLanguageHeader(string acceptLanguage, string expected)
            {
                var f = new PreferredCultureResolverFixture();

                var requestMessage = new HttpRequestMessage();
                requestMessage.Headers.Add("Accept-Language", acceptLanguage);

                f.PreferredCultureSettings.ResolveAll().Returns(new string[0]);

                var all = f.Subject.ResolveWith(requestMessage.Headers).ToArray();
                var result = string.Join(",", all);

                Assert.Equal(expected, result);
            }

            [Fact]
            public void IgnoresUnknownCulture()
            {
                var f = new PreferredCultureResolverFixture();

                f.PreferredCultureSettings.ResolveAll().Returns(new string[0]);

                var requestMessage = new HttpRequestMessage();
                requestMessage.Headers.Add("Accept-Language", "User_Can_Enter_Arbitrary_LanguageCode_From_IE");

                var result = f.Subject.ResolveWith(requestMessage.Headers).ToArray();

                Assert.Empty(result);
            }

            [Fact]
            public void PrefersUserSettingsOverHttpHeaderAcceptLanguage()
            {
                var f = new PreferredCultureResolverFixture();

                var requestMessage = new HttpRequestMessage();
                requestMessage.Headers.Add("Accept-Language", "en-US,en;q=0.8,en-AU;q=0.6");

                f.PreferredCultureSettings.ResolveAll().Returns(new[] {"zh-CN"});

                var result = f.Subject.ResolveWith(requestMessage.Headers).ToArray();

                Assert.Equal("zh-CN", result.First());
            }

            [Fact]
            public void ReturnsUserPreferredSettings()
            {
                var f = new PreferredCultureResolverFixture();

                f.PreferredCultureSettings.ResolveAll().Returns(new[] {"en-AU"});

                var result = f.Subject.ResolveWith(new HttpRequestMessage().Headers).ToArray();

                Assert.Equal("en-AU", result.First());
            }
        }

        public class ResolveMethod
        {
            [Fact]
            public void ShouldReturnTheFirstFromAllCandidates()
            {
                var f = new PreferredCultureResolverFixture();

                var requestMessage = new HttpRequestMessage();
                requestMessage.Headers.Add("Accept-Language", "en-US,en;q=0.8,en-AU;q=0.6");

                f.PreferredCultureSettings.ResolveAll().Returns(new[] {"en-AU"});
                f.RequestContext.Request.Returns(requestMessage);

                var result = f.Subject.Resolve();

                Assert.Equal("en-AU", result);
            }
        }
    }
}