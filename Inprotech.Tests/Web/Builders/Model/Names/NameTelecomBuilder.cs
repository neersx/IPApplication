using Inprotech.Tests.Fakes;
using InprotechKaizen.Model.Names;

namespace Inprotech.Tests.Web.Builders.Model.Names
{
    public class NameTelecomBuilder : IBuilder<NameTelecom>
    {
        readonly InMemoryDbContext _db;

        public NameTelecomBuilder(InMemoryDbContext db)
        {
            _db = db;
        }

        public Name Name { get; set; }

        public Telecommunication Telecommunication { get; set; }

        public bool AsEntities { get; set; }

        public NameTelecom Build()
        {
            var nt = new NameTelecom(
                                   Name ?? new NameBuilder(_db).Build(),
                                   Telecommunication ?? new TelecommunicationBuilder().Build()
                                  );

            return AsEntities ? nt.In(_db) : nt;
        }
    }
}