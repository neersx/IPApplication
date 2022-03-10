using System;
using System.IO;
using Inprotech.Infrastructure;
using Inprotech.Infrastructure.ResponseEnrichment.Localisation;
using NSubstitute;
using Xunit;

namespace Inprotech.Tests.Infrastructure.ResponseEnrichment.Localisation
{
    public class KendoLocaleFacts : FactBase
    {
        const string PathTemplate = "condor/kendo-intl/";
        const string DefaultLocale = "en";
        const string BasePath = "client";
        readonly string _localePath = Path.Combine(BasePath, PathTemplate);

        [Fact]
        public void ChecksSpecificLocaleFilesExist()
        {
            var userCulture = "dy-dx";
            var f = new KendoLocaleFixture();
            f.FileHelpers.DirectoryExists($"{_localePath}{userCulture}").Returns(true);
            var resultLocale = f.Subject.Resolve(userCulture);
            f.FileHelpers.Received(1).DirectoryExists($"{_localePath}{userCulture}");
            Assert.Equal(userCulture, resultLocale);
        }

        [Fact]
        public void ChecksBaseLocaleFilesExist()
        {
            var userCulture = "dy-dx";
            var f = new KendoLocaleFixture();
            f.FileHelpers.DirectoryExists($"{_localePath}{userCulture}").Returns(false);
            f.FileHelpers.DirectoryExists($"{_localePath}dy").Returns(true);
            var resultLocale = f.Subject.Resolve(userCulture);
            f.FileHelpers.Received(1).DirectoryExists($"{_localePath}{userCulture}");
            Assert.Equal("dy", resultLocale);
        }

        [Fact]
        public void ReturnsEnglishIfNoLocalesExistOnServer()
        {
            var userCulture = "dy-dx";
            var f = new KendoLocaleFixture();
            f.FileHelpers.DirectoryExists($"{_localePath}{Arg.Any<String>()}").Returns(false);
            var resultLocale = f.Subject.Resolve(userCulture);
            f.FileHelpers.Received(1).DirectoryExists($"{_localePath}{userCulture}");
            Assert.Equal(DefaultLocale, resultLocale);
        }

        [Fact]
        public void ReturnsEnglishIfNoneSpecified()
        {
            var f = new KendoLocaleFixture();
            var resultLocale = f.Subject.Resolve(string.Empty);
            f.FileHelpers.DidNotReceiveWithAnyArgs().DirectoryExists(Arg.Any<string>());
            Assert.Equal(DefaultLocale, resultLocale);
        }

        public class KendoLocaleFixture : IFixture<KendoLocale>
        {
            public IFileHelpers FileHelpers { get; set; }
            public KendoLocale Subject { get; set; }
            public KendoLocaleFixture()
            {
                FileHelpers = Substitute.For<IFileHelpers>();
                Subject = new KendoLocale(FileHelpers);
            }
        }
    }
}
