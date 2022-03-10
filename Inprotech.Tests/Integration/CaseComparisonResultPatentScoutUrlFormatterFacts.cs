using System;
using Inprotech.Integration;
using Inprotech.Integration.Innography;
using InprotechKaizen.Model.Components.Cases.Comparison.Results;
using NSubstitute;
using Xunit;
using Case = InprotechKaizen.Model.Components.Cases.Comparison.Results.Case;

namespace Inprotech.Tests.Integration
{
    public class CaseComparisonResultPatentScoutUrlFormatterFacts
    {
        readonly IPatentScoutUrlFormatter _patentScoutUrlFormatter = Substitute.For<IPatentScoutUrlFormatter>();

        ISourceCaseUrlFormatter CreateSubject(Uri returnUri = null)
        {
            if (returnUri != null)
            {
                _patentScoutUrlFormatter.CreatePatentScoutReferenceLink(Arg.Any<string>(), Arg.Any<bool>())
                                        .Returns(returnUri);
            }

            return new CaseComparisonResultPatentScoutUrlFormatter(_patentScoutUrlFormatter);
        }

        [Theory]
        [InlineData(true)]
        [InlineData(false)]
        public void ShouldReturnResultFromPatentScoutUrlFormatterIfSourceIdDefined(bool isCpaSso)
        {
            var sourceId = Fixture.String();
            var uriToPatentScout = new Uri("http://app.patentscout.com");
            var subject = CreateSubject(uriToPatentScout);
            var comparisonResult = new ComparisonResult("Innography")
            {
                Case = new Case
                {
                    SourceId = sourceId
                }
            };

            var r = subject.Format(comparisonResult, isCpaSso);

            Assert.Equal(uriToPatentScout, r);

            _patentScoutUrlFormatter.Received(1)
                                    .CreatePatentScoutReferenceLink(sourceId, isCpaSso);
        }

        [Fact]
        public void ShouldReturnNullIfNoSourceIdDefined()
        {
            var subject = CreateSubject();
            var comparisonResult = new ComparisonResult("Innography") {Case = new Case()};
            var r = subject.Format(comparisonResult, Fixture.Boolean());

            Assert.Null(r);
            _patentScoutUrlFormatter.DidNotReceiveWithAnyArgs()
                                    .CreatePatentScoutReferenceLink(null, false);
        }

        [Fact]
        public void ShouldThrowArgumentNullExceptionIfComparisonResultDoesNotHaveCaseInIt()
        {
            Assert.Throws<ArgumentNullException>(
                                                 () =>
                                                 {
                                                     var subject = CreateSubject();
                                                     subject.Format(new ComparisonResult("Innography"), Fixture.Boolean());
                                                 });
        }

        [Fact]
        public void ShouldThrowArgumentNullExceptionIfComparisonResultNotPassed()
        {
            Assert.Throws<ArgumentNullException>(
                                                 () =>
                                                 {
                                                     var subject = CreateSubject();
                                                     subject.Format(null, Fixture.Boolean());
                                                 });
        }
    }
}