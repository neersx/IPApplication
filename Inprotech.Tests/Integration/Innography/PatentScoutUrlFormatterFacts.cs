using System;
using Inprotech.Integration.Innography;
using Inprotech.Integration.Innography.Ids;
using NSubstitute;
using Xunit;

namespace Inprotech.Tests.Integration.Innography
{
    public class PatentScoutUrlFormatterFacts
    {
        readonly IPatentScoutSettingsResolver _settingsResolver = Substitute.For<IPatentScoutSettingsResolver>();

        PatentScoutUrlFormatter CreateSubject()
        {
            _settingsResolver.Resolve().Returns(new InnographySetting
            {
                ApiBase = new Uri("https://ps.innography.com")
            });

            return new PatentScoutUrlFormatter(_settingsResolver);
        }

        [Theory]
        [InlineData("")]
        [InlineData(null)]
        public void ShouldReturnNullIfIpIdWasEmpty(string ipId)
        {
            var subject = CreateSubject();

            Assert.Null(subject.CreatePatentScoutReferenceLink(ipId, Fixture.Boolean()));
        }

        [Theory]
        [InlineData("hdsalkf")]
        [InlineData("I-dskjdsa")]
        [InlineData("5137631")]
        public void ShouldReturnNullIfIpIdNotInExpectedFormat(string ipId)
        {
            var subject = CreateSubject();

            Assert.Null(subject.CreatePatentScoutReferenceLink(ipId, Fixture.Boolean()));
        }

        [Fact]
        public void ShouldFormatDirectly()
        {
            var subject = CreateSubject();

            var r = subject.CreatePatentScoutReferenceLink("I-000111059603", false);

            Assert.Equal("https://ps.innography.com/patent/I-000111059603", r.ToString());
        }

        [Fact]
        public void ShouldFormatForSingleSignOn()
        {
            var subject = CreateSubject();

            var r = subject.CreatePatentScoutReferenceLink("I-000111059603", true);

            Assert.Equal("https://ps.innography.com/oss?r=patent/I-000111059603", r.ToString());
        }
    }
}