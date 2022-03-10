using InprotechKaizen.Model.Ede;

namespace Inprotech.Tests.Web.Builders.BulkCaseImport
{
    public class EdeUnresolvedNameBuilder : IBuilder<EdeUnresolvedName>
    {
        public int? BatchId;

        public EdeUnresolvedName Build()
        {
            return new EdeUnresolvedName
            {
                BatchId = BatchId,
                Name = Fixture.String(),
                FirstName = Fixture.String(),
                Email = Fixture.String(),
                EntityType = Fixture.Integer(),
                Fax = Fixture.String(),
                Phone = Fixture.String(),
                NameType = Fixture.String(),
                SenderNameIdentifier = Fixture.String(),
                AttentionFirstName = Fixture.String(),
                AttentionLastName = Fixture.String(),
                AttentionTitle = Fixture.String(),
                AddressLine = Fixture.String(),
                City = Fixture.String(),
                PostCode = Fixture.String(),
                State = Fixture.String(),
                CountryCode = Fixture.String()
            };
        }
    }
}