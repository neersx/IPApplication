using Inprotech.Tests.Fakes;
using Inprotech.Tests.Web.Builders.Model.Cases;
using InprotechKaizen.Model.Cases;
using InprotechKaizen.Model.Names;

namespace Inprotech.Tests.Web.Builders.Model.Names
{
    public class NameTypeClassificationBuilder : IBuilder<NameTypeClassification>
    {
        readonly InMemoryDbContext _db;

        public NameTypeClassificationBuilder(InMemoryDbContext db)
        {
            _db = db;
        }

        public Name Name { get; set; }
        public NameType NameType { get; set; }
        public int? IsAllowed { get; set; }

        public NameTypeClassification Build()
        {
            return new NameTypeClassification(
                                              Name ?? new NameBuilder(_db).Build(),
                                              NameType ?? new NameTypeBuilder().Build())
            {
                IsAllowed = IsAllowed
            };
        }
    }
}