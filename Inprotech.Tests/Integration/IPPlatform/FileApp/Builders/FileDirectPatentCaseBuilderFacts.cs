using System.Threading.Tasks;
using Inprotech.Integration.IPPlatform.FileApp.Builders;
using Inprotech.Tests.Fakes;
using Inprotech.Tests.Web.Builders.Model.Cases;
using Inprotech.Tests.Web.Builders.Model.Names;
using InprotechKaizen.Model;
using InprotechKaizen.Model.Cases;
using InprotechKaizen.Model.Components.Cases.Filing;
using InprotechKaizen.Model.Integration;
using InprotechKaizen.Model.Integration.PtoAccess;
using InprotechKaizen.Model.Names;
using NSubstitute;
using Xunit;

namespace Inprotech.Tests.Integration.IPPlatform.FileApp.Builders
{
    public class FileDirectPatentCaseBuilderFacts : FactBase
    {
        public class Env
        {
            readonly InMemoryDbContext _db;
            public Case Case;
            public Name Name1;
            public Name Name2;
            public NameType OwnerNameType;

            public Env(InMemoryDbContext db)
            {
                _db = db;
            }

            public Env WithOwner()
            {
                new CaseNameBuilder(_db)
                    {
                        Name = Name1,
                        NameType = OwnerNameType,
                        Sequence = 1
                    }
                    .BuildWithCase(Case).In(_db);

                return this;
            }
        }

        Env BuildEnvironment()
        {
            var @case = new CaseBuilder().Build().In(Db);
            var ownerNameType = new NameTypeBuilder
            {
                NameTypeCode = KnownNameTypes.Owner
            }.Build().In(Db);
            var name1 = new NameBuilder(Db).Build().In(Db);
            var name2 = new NameBuilder(Db).Build().In(Db);

            return new Env(Db)
            {
                Case = @case,
                OwnerNameType = ownerNameType,
                Name1 = name1,
                Name2 = name2
            };
        }

        static readonly IFilingLanguageResolver FilingLanguageResolver = Substitute.For<IFilingLanguageResolver>();

        IFileCaseBuilder CreateSubject()
        {
            return new FileDirectPatentCaseBuilder(Db, FilingLanguageResolver, new EventMappingsResolver(Db));
        }

        [Fact]
        public async Task ShouldDeriveFilingLanguage()
        {
            var env = BuildEnvironment()
                .WithOwner();

            var filingLanguage = Fixture.String();

            FilingLanguageResolver.Resolve(env.Case.Irn).Returns(filingLanguage);

            var r = await CreateSubject().Build(env.Case.Id.ToString());

            Assert.Equal(filingLanguage, r.BibliographicalInformation.FilingLanguage);
        }

        [Fact]
        public async Task ShouldDerivePriorityCountryFromApplication()
        {
            var env = BuildEnvironment()
                .WithOwner();

            var country = env.Case.Country.Id;

            var r = await CreateSubject().Build(env.Case.Id.ToString());

            Assert.Equal(country, r.BibliographicalInformation.PriorityCountry);
        }

        [Fact]
        public async Task ShouldDerivePriorityDateFromApplication()
        {
            var env = BuildEnvironment()
                .WithOwner();

            var eventNo = Fixture.Integer();
            var eventDate = Fixture.PastDate();

            new SourceMappedEvents("Application", eventNo).In(Db);
            new CaseEventBuilder
                {
                    CaseId = env.Case.Id,
                    EventNo = eventNo,
                    Cycle = 1,
                    EventDate = eventDate
                }.Build()
                 .In(Db);

            var r = await CreateSubject().Build(env.Case.Id.ToString());

            Assert.Equal(eventDate.ToString("yyyy-MM-dd"), r.BibliographicalInformation.PriorityDate);
        }

        [Fact]
        public async Task ShouldIgnoreInnographyIdIfNotActiveAgainstCase()
        {
            var innographyId = Fixture.String();
            var env = BuildEnvironment().WithOwner();

            new CpaGlobalIdentifier
            {
                CaseId = env.Case.Id,
                InnographyId = innographyId,
                IsActive = false
            }.In(Db);

            var r = await CreateSubject().Build(env.Case.Id.ToString());

            Assert.Null(r.CaseGuid);
        }

        [Fact]
        public async Task ShouldIndicateDirectPatentType()
        {
            var env = BuildEnvironment().WithOwner();
            var r = await CreateSubject().Build(env.Case.Id.ToString());
            Assert.Equal("DIRECT_PATENT", r.IpType);
        }

        [Fact]
        public async Task ShouldReturnBasicDetails()
        {
            var env = BuildEnvironment();
            new CaseNameBuilder(Db)
                {
                    Name = env.Name1,
                    NameType = env.OwnerNameType,
                    Sequence = 1
                }
                .BuildWithCase(env.Case, 0).In(Db);

            var r = await CreateSubject().Build(env.Case.Id.ToString());

            Assert.Equal(env.Case.Id.ToString(), r.Id);
            Assert.Equal(env.Case.Irn, r.CaseReference);
            Assert.Equal(env.Case.Title, r.BibliographicalInformation.Title);
            Assert.Equal(env.Name1.LastName + ", " + env.Name1.FirstName, r.ApplicantName);
        }

        [Fact]
        public async Task ShouldReturnFirstOwner()
        {
            var env = BuildEnvironment();
            new CaseNameBuilder(Db)
                {
                    Name = env.Name2,
                    NameType = env.OwnerNameType,
                    Sequence = 2
                }
                .BuildWithCase(env.Case, 0)
                .In(Db);
            new CaseNameBuilder(Db)
                {
                    Name = env.Name1,
                    NameType = env.OwnerNameType,
                    Sequence = 1
                }
                .BuildWithCase(env.Case, 0)
                .In(Db);

            var r = await CreateSubject().Build(env.Case.Id.ToString());

            Assert.Equal(env.Name1.LastName + ", " + env.Name1.FirstName, r.ApplicantName);
        }

        [Fact]
        public async Task ShouldReturnInnographyIdIfActiveAgainstCase()
        {
            var innographyId = Fixture.String();
            var env = BuildEnvironment().WithOwner();

            new CpaGlobalIdentifier
            {
                CaseId = env.Case.Id,
                InnographyId = innographyId,
                IsActive = true
            }.In(Db);

            var r = await CreateSubject().Build(env.Case.Id.ToString());

            Assert.Equal(innographyId, r.CaseGuid);
        }
    }
}