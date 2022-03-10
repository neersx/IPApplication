using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using Inprotech.Infrastructure.Security;
using Inprotech.Tests.Fakes;
using Inprotech.Tests.Web.Builders.Model.Cases;
using Inprotech.Tests.Web.Builders.Model.PriorArt;
using Inprotech.Web.PriorArt;
using Inprotech.Web.PriorArt.Maintenance;
using NSubstitute;
using Xunit;

namespace Inprotech.Tests.Web.PriorArt.Maintenance
{
    public class PriorArtMaintenanceValidatorFacts : FactBase
    {
        public class IncludeInSourceDocumentMethod : FactBase
        {
            [Fact]
            public void DoesPriorArtExist()
            {
                var art = new PriorArtBuilder().Build().In(Db);
                var fixture = new PriorArtMaintenanceValidatorFixture(Db);

                Assert.True(fixture.Subject.ExistingPriorArt(art.CountryId, art.OfficialNumber, art.Kind));
            }

            [Fact]
            public void DoesNotPriorArtExist()
            {
                var art = new PriorArtBuilder().Build().In(Db);
                var fixture = new PriorArtMaintenanceValidatorFixture(Db);

                Assert.False(fixture.Subject.ExistingPriorArt(art.CountryId, "XXX", art.Kind));
            }

            [Fact]
            public void DoesLiteratureExistMatchingDescription()
            {
                var literature = new PriorArtBuilder().BuildLiterature().In(Db);
                var fixture = new PriorArtMaintenanceValidatorFixture(Db);

                Assert.True(fixture.Subject.ExistingLiterature(literature.Description, literature.Name, literature.Title, literature.RefDocumentParts, literature.Publisher, literature.City, literature.CountryId));
            }
            
            [Fact]
            public void DoesNotLiteratureExistMatchingDescription()
            {
                var literature = new PriorArtBuilder().BuildLiterature().In(Db);
                var fixture = new PriorArtMaintenanceValidatorFixture(Db);

                Assert.False(fixture.Subject.ExistingLiterature(null, literature.Name, "XXX", literature.RefDocumentParts, literature.Publisher, literature.City, literature.CountryId));
            }
        }

        public class PriorArtMaintenanceValidatorFixture : IFixture<PriorArtMaintenanceValidator>
        {
            public PriorArtMaintenanceValidatorFixture(InMemoryDbContext db)
            {
                Subject = new PriorArtMaintenanceValidator(db);
            }
            public PriorArtMaintenanceValidator Subject { get; }
        }
    }
}
