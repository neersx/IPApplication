using System.Threading.Tasks;
using Inprotech.Integration.IPPlatform.FileApp.Builders;
using Inprotech.Tests.Fakes;
using Inprotech.Tests.Web.Builders.Model.Cases;
using Inprotech.Tests.Web.Builders.Model.Names;
using InprotechKaizen.Model;
using InprotechKaizen.Model.Cases;
using InprotechKaizen.Model.Integration;
using InprotechKaizen.Model.Integration.PtoAccess;
using InprotechKaizen.Model.Names;
using Xunit;

namespace Inprotech.Tests.Integration.IPPlatform.FileApp.Builders
{
    public class FilePctCaseBuilderFacts : FactBase
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
                    .BuildWithCase(Case, 0).In(_db);

                return this;
            }

            public Env WithMatchingEvents(string applicationDate, string publicationDate, string earliestPriorityDate)
            {
                void CreateDatePair(string dateName, int? eventNo, string dateString)
                {
                    new SourceMappedEvents(dateName, eventNo).In(_db);
                    if (string.IsNullOrWhiteSpace(dateString)) return;
                    new CaseEventBuilder
                        {
                            CaseId = Case.Id,
                            EventNo = eventNo,
                            Cycle = 1,
                            EventDate = Fixture.Date(dateString)
                        }.Build()
                         .In(_db);
                }

                CreateDatePair("Application", -4, applicationDate);
                CreateDatePair("Publication", -36, publicationDate);
                CreateDatePair("Earliest Priority", -1, earliestPriorityDate);

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

        [Theory]
        [InlineData("2001-01-01", null, null, "Should return application number date from mapped event from source")]
        [InlineData(null, "2001-01-01", null, "Should return publication number date from mapped event from source")]
        [InlineData(null, null, "2001-01-01", "Should return earliest priority date from mapped event from source")]
#pragma warning disable xUnit1026
        public async Task ShouldPullEventDatesFromConfiguredMappings(
            string applicationDate,
            string publicationDate,
            string earliestPriorityDate,
            string comment)
#pragma warning restore xUnit1026
        {
            var env = BuildEnvironment()
                      .WithOwner()
                      .WithMatchingEvents(applicationDate, publicationDate, earliestPriorityDate);

            var subject = new FilePctCaseBuilder(Db, new EventMappingsResolver(Db));

            var r = await subject.Build(env.Case.Id.ToString());

            Assert.Equal(applicationDate, r.BibliographicalInformation.ApplicationDate);
            Assert.Equal(publicationDate, r.BibliographicalInformation.PublicationDate);
            Assert.Equal(earliestPriorityDate, r.BibliographicalInformation.PriorityDate);
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

            var subject = new FilePctCaseBuilder(Db, new EventMappingsResolver(Db));

            var r = await subject.Build(env.Case.Id.ToString());

            Assert.Null(r.CaseGuid);
        }

        [Fact]
        public async Task ShouldIndicatePostPctPatentType()
        {
            var env = BuildEnvironment().WithOwner();
            var subject = new FilePctCaseBuilder(Db, new EventMappingsResolver(Db));
            var r = await subject.Build(env.Case.Id.ToString());
            Assert.Equal("PATENT_POST_PCT", r.IpType);
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

            var subject = new FilePctCaseBuilder(Db, new EventMappingsResolver(Db));

            var r = await subject.Build(env.Case.Id.ToString());

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

            var subject = new FilePctCaseBuilder(Db, new EventMappingsResolver(Db));

            var r = await subject.Build(env.Case.Id.ToString());

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

            var subject = new FilePctCaseBuilder(Db, new EventMappingsResolver(Db));

            var r = await subject.Build(env.Case.Id.ToString());

            Assert.Equal(innographyId, r.CaseGuid);
        }
    }
}