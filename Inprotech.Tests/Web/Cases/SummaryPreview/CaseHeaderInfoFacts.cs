using System.Threading.Tasks;
using Inprotech.Infrastructure;
using Inprotech.Tests.Fakes;
using Inprotech.Tests.Web.Builders.Model.Cases;
using Inprotech.Tests.Web.Builders.Model.Configuration;
using Inprotech.Web.Cases.Details;
using Inprotech.Web.Cases.SummaryPreview;
using InprotechKaizen.Model.Cases;
using InprotechKaizen.Model.Cases.Events;
using InprotechKaizen.Model.Components.Cases;
using InprotechKaizen.Model.Components.Cases.CriticalDates;
using InprotechKaizen.Model.Configuration.SiteControl;
using NSubstitute;
using Xunit;

namespace Inprotech.Tests.Web.Cases.SummaryPreview
{
    public class CaseHeaderInfoFacts : FactBase
    {
        readonly ICaseHeaderPartial _caseHeaderPartial = Substitute.For<ICaseHeaderPartial>();
        readonly INextRenewalDatesResolver _nextRenewalDatesResolver = Substitute.For<INextRenewalDatesResolver>();
        readonly IDefaultCaseImage _defaultCaseImage = Substitute.For<IDefaultCaseImage>();

        readonly int _userIdentity = Fixture.Integer();
        readonly string _culture = Fixture.String();

        ICaseHeaderInfo CreateSubject()
        {
            return new CaseHeaderInfo(Db, _caseHeaderPartial, _nextRenewalDatesResolver, _defaultCaseImage);
        }

        Case CreateCase(string irn = null, string title = null, bool? withEthicalWallRestriction = false, string pt = null)
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
                Id = pt ?? Fixture.String()
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
        public async Task ShouldReturnAgeOfCase()
        {
            var ageOfCase = Fixture.Short();

            var @case = CreateCase();

            _caseHeaderPartial.Retrieve(_userIdentity, _culture, @case.Id)
                              .Returns(new CaseHeader());

            _nextRenewalDatesResolver.Resolve(@case.Id, null)
                                     .Returns(new RenewalDates
                                     {
                                         AgeOfCase = ageOfCase
                                     });

            var r = await CreateSubject().Retrieve(_userIdentity, _culture, @case.Id);

            Assert.Equal(ageOfCase, r.Summary.AgeOfCase);
        }

        [Fact]
        public async Task ShouldReturnTypeOfMark()
        {
            var typeOfMark = Fixture.Integer();
            var typeOfMarkTc = new TableCodeBuilder {TableCode = typeOfMark}.Build().In(Db);

            var @case = CreateCase(null, null, false, "T");
            @case.TypeOfMark = typeOfMarkTc;

            _caseHeaderPartial.Retrieve(_userIdentity, _culture, @case.Id)
                              .Returns(new CaseHeader());
            
            var r = await CreateSubject().Retrieve(_userIdentity, _culture, @case.Id);

            Assert.Equal(typeOfMarkTc.Name, r.Summary.TypeOfMark);
        }

        [Fact]
        public async Task ShouldReturnCurrentOfficialNumber()
        {
            var officialNumber = new OfficialNumberBuilder().Build().In(Db);
            
            var @case = CreateCase();
            @case.OfficialNumbers.Add(officialNumber);
            @case.CurrentOfficialNumber = officialNumber.Number;

            _caseHeaderPartial.Retrieve(_userIdentity, _culture, @case.Id)
                              .Returns(new CaseHeader());
            
            var r = await CreateSubject().Retrieve(_userIdentity, _culture, @case.Id);

            Assert.Equal(officialNumber.Number, r.Summary.OfficialNumber);
        }

        [Fact]
        public async Task ShouldReturnCaseHeaderImageIfSiteControlDefined()
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

            _caseHeaderPartial.Retrieve(_userIdentity, _culture, @case.Id)
                              .Returns(new CaseHeader());

            _defaultCaseImage.For(@case.Id).Returns(thisImage);

            var r = await CreateSubject().Retrieve(_userIdentity, _culture, @case.Id);

            Assert.Equal(thisImage.CaseImageDescription, r.Summary.ImageTitle);
            Assert.Equal(thisImage.ImageId, r.Summary.ImageKey);
        }

        [Fact]
        public async Task ShouldReturnCaseHeaderImageOfLowestSequenceIfMultipleImageTypeMatchesConfiguredSiteControl()
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

            _caseHeaderPartial.Retrieve(_userIdentity, _culture, @case.Id)
                              .Returns(new CaseHeader());
            _defaultCaseImage.For(@case.Id).Returns(thisImage);

            var r = await CreateSubject().Retrieve(_userIdentity, _culture, @case.Id);

            Assert.Equal(thisImage.CaseImageDescription, r.Summary.ImageTitle);
            Assert.Equal(thisImage.ImageId, r.Summary.ImageKey);
        }

        [Fact]
        public async Task ShouldReturnFromCaseHeaderComponent()
        {
            var @case = CreateCase();

            var caseHeader = new CaseHeader
            {
                CaseStatusDescription = Fixture.String(),
                CaseOffice = Fixture.String(),
                CaseCategoryDescription = Fixture.String(),
                CaseKey = @case.Id,
                CountryName = Fixture.String(),
                FileLocation = Fixture.String(),
                IsCRM = Fixture.Boolean(),
                PropertyTypeDescription = Fixture.String(),
                RenewalStatusDescription = Fixture.String(),
                Names = new CaseSummaryName[0],
                Title = Fixture.String(),
                RenewalInstruction = Fixture.String(),
                SubTypeDescription = Fixture.String(),
                Classes = Fixture.String(),
                TotalClasses = Fixture.Integer(),
                BasisDescription = Fixture.String()
            };

            _caseHeaderPartial.Retrieve(_userIdentity, _culture, @case.Id)
                              .Returns(caseHeader);

            var r = await CreateSubject().Retrieve(_userIdentity, _culture, @case.Id);

            Assert.Equal(caseHeader.CaseStatusDescription, r.Summary.CaseStatusDescription);
            Assert.Equal(caseHeader.CaseOffice, r.Summary.CaseOffice);
            Assert.Equal(caseHeader.CaseCategoryDescription, r.Summary.CaseCategoryDescription);
            Assert.Equal(caseHeader.CountryName, r.Summary.CountryName);
            Assert.Equal(caseHeader.FileLocation, r.Summary.FileLocation);
            Assert.Equal(caseHeader.IsCRM, r.Summary.IsCRM);
            Assert.Equal(caseHeader.PropertyTypeDescription, r.Summary.PropertyTypeDescription);
            Assert.Equal(caseHeader.RenewalStatusDescription, r.Summary.RenewalStatusDescription);
            Assert.Equal(caseHeader.Names, r.Names);
            Assert.Equal(caseHeader.Title, r.Summary.Title);
            Assert.Equal(caseHeader.RenewalInstruction, r.Summary.RenewalInstruction);
            Assert.Equal(caseHeader.SubTypeDescription, r.Summary.SubTypeDescription);
            Assert.Equal(caseHeader.Classes, r.Summary.Classes);
            Assert.Equal(caseHeader.TotalClasses, r.Summary.TotalClasses);
            Assert.Equal(caseHeader.BasisDescription, r.Summary.BasisDescription);
        }

        [Fact]
        public async Task ShouldReturnInstructionsReceivedDate()
        {
            var @case = CreateCase();

            _caseHeaderPartial.Retrieve(_userIdentity, _culture, @case.Id)
                              .Returns(new CaseHeader());

            new CaseEventBuilder
            {
                CaseId = @case.Id,
                Cycle = 1,
                EventNo = (int) KnownEvents.InstructionsReceivedDateForNewCase,
                EventDate = Fixture.PastDate()
            }.Build().In(Db);

            var r = await CreateSubject().Retrieve(_userIdentity, _culture, @case.Id);

            Assert.Equal(Fixture.PastDate(), r.Summary.DateOfInstruction);
        }
    }
}