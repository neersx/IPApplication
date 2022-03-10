using Inprotech.Infrastructure;
using Inprotech.Tests.Fakes;
using Inprotech.Tests.Web.Builders.Model.Cases;
using Inprotech.Web.Cases.Details;
using InprotechKaizen.Model.Cases;
using InprotechKaizen.Model.Configuration.SiteControl;
using NSubstitute;
using Xunit;

namespace Inprotech.Tests.Web.Cases.Details
{
    public class DefaultCaseImageFacts
    {
        public class ForMethod : FactBase
        {
            Case CreateCase(string irn = null, string title = null, bool? withEthicalWallRestriction = false)
            {
                var caseType = new CaseTypeBuilder
                {
                    Id = Fixture.String(),
                    Name = Fixture.String(),
                    ActualCaseTypeId = Fixture.String()
                }.Build().In(Db);

                var propertyType = new PropertyTypeBuilder
                {
                    Name = Fixture.String(),
                    Id = Fixture.String()
                }.Build().In(Db);

                var @case = new Case("123", new Country(), caseType, propertyType)
                {
                    Irn = irn,
                    Title = title
                }.In(Db);

                if (!withEthicalWallRestriction.GetValueOrDefault())
                {
                    new FilteredEthicalWallCase().In(Db).WithKnownId(x => x.CaseId, @case.Id);
                }

                return @case;
            }

            [Fact]
            public void ReturnsCaseImageOfLowestSequenceIfMultipleImageTypeMatchesConfiguredSiteControl()
            {
                var requiredType = Fixture.Integer();
                var otherType1 = Fixture.Integer();
                var otherType2 = Fixture.Integer();

                new SiteControl
                {
                    ControlId = SiteControls.CaseViewSummaryImageType,
                    StringValue = string.Join(", ", otherType1.ToString(), requiredType.ToString(), otherType2.ToString())
                }.In(Db);

                var @case = CreateCase();

                new CaseImage(@case, Fixture.Integer(), 1, otherType2)
                {
                    CaseImageDescription = Fixture.String(),
                    ImageSequence = 1
                }.In(Db);

                new CaseImage(@case, Fixture.Integer(), 1, Fixture.Integer())
                {
                    CaseImageDescription = Fixture.String(),
                    ImageSequence = 2
                }.In(Db);

                var thisImage = new CaseImage(@case, Fixture.Integer(), 1, requiredType)
                {
                    CaseImageDescription = Fixture.String(),
                    ImageSequence = 3
                }.In(Db);

                new CaseImage(@case, Fixture.Integer(), 1, requiredType)
                {
                    CaseImageDescription = Fixture.String(),
                    ImageSequence = 4
                }.In(Db);

                var f = new DefaultCaseImageFixture(Db);
                var r = f.Subject.For(@case.Id);

                Assert.Equal(thisImage.CaseImageDescription, r.CaseImageDescription);
                Assert.Equal(thisImage.ImageId, r.ImageId);
            }

            [Fact]
            public void ReturnsNullIfMatchingCaseImageDoesNotExist()
            {
                var imageType = Fixture.Integer();
                var @case = CreateCase();
                new SiteControl
                {
                    ControlId = SiteControls.CaseViewSummaryImageType,
                    StringValue = imageType.ToString()
                }.In(Db);
                new CaseImage(@case, Fixture.Integer(), 1, Fixture.Integer())
                {
                    CaseImageDescription = Fixture.String()
                }.In(Db);
                var f = new DefaultCaseImageFixture(Db);
                var r = f.Subject.For(@case.Id);
                Assert.Null(r);
            }

            [Fact]
            public void ReturnsNullIfSiteControlNotConfigured()
            {
                var imageType = Fixture.Integer();
                var @case = CreateCase();
                new SiteControl
                {
                    ControlId = SiteControls.ImageTypeForCaseHeader,
                    IntegerValue = imageType
                }.In(Db);
                new CaseImage(@case, Fixture.Integer(), 1, imageType)
                {
                    CaseImageDescription = Fixture.String()
                }.In(Db);
                var f = new DefaultCaseImageFixture(Db);
                var r = f.Subject.For(@case.Id);

                Db.DidNotReceive().Set<CaseImage>();
                Assert.Null(r);
            }

            [Fact]
            public void ReturnsPreferredImageBasedOnSiteControlList()
            {
                var requiredType = Fixture.Integer();
                var otherType1 = Fixture.Integer();
                var otherType2 = Fixture.Integer();

                new SiteControl
                {
                    ControlId = SiteControls.CaseViewSummaryImageType,
                    StringValue = string.Join(",", otherType1.ToString(), requiredType.ToString(), otherType2.ToString())
                }.In(Db);

                var @case = CreateCase();

                new CaseImage(@case, Fixture.Integer(), 1, otherType2)
                {
                    CaseImageDescription = Fixture.String(),
                    ImageSequence = 1
                }.In(Db);

                new CaseImage(@case, Fixture.Integer(), 1, Fixture.Integer())
                {
                    CaseImageDescription = Fixture.String(),
                    ImageSequence = 2
                }.In(Db);

                var thisImage = new CaseImage(@case, Fixture.Integer(), 1, requiredType)
                {
                    CaseImageDescription = Fixture.String(),
                    ImageSequence = 3
                }.In(Db);

                var f = new DefaultCaseImageFixture(Db);
                var r = f.Subject.For(@case.Id);

                Assert.Equal(thisImage.CaseImageDescription, r.CaseImageDescription);
                Assert.Equal(thisImage.ImageId, r.ImageId);
            }

            [Fact]
            public void ShouldReturnCaseHeaderImageIfSiteControlDefined()
            {
                var imageType = Fixture.Integer();

                new SiteControl
                {
                    ControlId = SiteControls.CaseViewSummaryImageType,
                    StringValue = imageType.ToString()
                }.In(Db);

                var @case = CreateCase();

                var thisImage = new CaseImage(@case, Fixture.Integer(), 1, imageType)
                {
                    CaseImageDescription = Fixture.String()
                }.In(Db);

                new CaseImage(@case, Fixture.Integer(), 1, Fixture.Integer())
                {
                    CaseImageDescription = Fixture.String()
                }.In(Db);

                var f = new DefaultCaseImageFixture(Db);
                var r = f.Subject.For(@case.Id);

                Assert.Equal(thisImage.CaseImageDescription, r.CaseImageDescription);
                Assert.Equal(thisImage.ImageId, r.ImageId);
            }

            [Fact]
            public void ShouldReturnCaseHeaderImageOfLowestSequenceIfMultipleImageTypeMatchesConfiguredSiteControl()
            {
                var imageType = Fixture.Integer();

                new SiteControl
                {
                    ControlId = SiteControls.CaseViewSummaryImageType,
                    StringValue = imageType.ToString()
                }.In(Db);

                var @case = CreateCase();

                var thisImage = new CaseImage(@case, Fixture.Integer(), 1, imageType)
                {
                    CaseImageDescription = Fixture.String()
                }.In(Db);

                new CaseImage(@case, Fixture.Integer(), 2, imageType)
                {
                    CaseImageDescription = Fixture.String()
                }.In(Db);

                var f = new DefaultCaseImageFixture(Db);
                var r = f.Subject.For(@case.Id);

                Assert.Equal(thisImage.CaseImageDescription, r.CaseImageDescription);
                Assert.Equal(thisImage.ImageId, r.ImageId);
            }
        }

        public class DefaultCaseImageFixture : IFixture<DefaultCaseImage>
        {
            public DefaultCaseImageFixture(InMemoryDbContext dbContext)
            {
                Subject = new DefaultCaseImage(dbContext);
            }

            public DefaultCaseImage Subject { get; }
        }
    }
}