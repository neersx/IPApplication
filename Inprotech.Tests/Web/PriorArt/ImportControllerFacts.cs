using System.Threading.Tasks;
using Inprotech.Infrastructure.Security;
using Inprotech.Tests.Extensions;
using Inprotech.Web.PriorArt;
using InprotechKaizen.Model.Components.Cases.PriorArt;
using InprotechKaizen.Model.Persistence;
using NSubstitute;
using Xunit;

namespace Inprotech.Tests.Web.PriorArt
{
    public class ImportControllerFacts
    {
        public class FromCaseEvidenceFinderMethod
        {
            [Fact]
            public void ImportUsingEvidenceImporter()
            {
                var match = new Match();

                var model = new ImportEvidenceModel
                {
                    Evidence = match
                };

                var fixture = new ImportControllerFixture();

                fixture.Subject.FromCaseEvidenceFinder(model);

                fixture.EvidenceImporter.Received(1).ImportMatch(model, match);

                fixture.DbContext.Received(1).SaveChanges();
            }

            [Fact]
            public void RequiresMaintainPriorArtCreatePermission()
            {
                var r = TaskSecurity.Secures<ImportController>(ApplicationTask.MaintainPriorArt, ApplicationTaskAccessLevel.Create);

                Assert.True(r);
            }
        }

        public class FromIpOneDataDocumentFinderMethod
        {
            [Fact]
            public async Task ImportsCompletedModelUsingEvidenceImporter()
            {
                var match = new Match
                {
                    IsComplete = true
                };

                var model = new ImportEvidenceModel
                {
                    Evidence = match
                };

                var fixture = new ImportControllerFixture();

                await fixture.Subject.FromIpOneDataDocumentFinder(model);

                fixture.EvidenceImporter.Received(1).ImportMatch(model, match);

                fixture.DbContext.Received(1).SaveChangesAsync()
                       .IgnoreAwaitForNSubstituteAssertion();
            }

            [Fact]
            public void RequiresMaintainPriorArtCreatePermission()
            {
                var r = TaskSecurity.Secures<ImportController>(ApplicationTask.MaintainPriorArt, ApplicationTaskAccessLevel.Create);

                Assert.True(r);
            }
        }

        public class ImportControllerFixture : IFixture<ImportController>
        {
            public ImportControllerFixture()
            {
                DbContext = Substitute.For<IDbContext>();

                EvidenceImporter = Substitute.For<IEvidenceImporter>();

                Subject = new ImportController(DbContext, EvidenceImporter);
            }

            public IDbContext DbContext { get; set; }

            public IEvidenceImporter EvidenceImporter { get; set; }

            public ImportController Subject { get; }
        }
    }
}