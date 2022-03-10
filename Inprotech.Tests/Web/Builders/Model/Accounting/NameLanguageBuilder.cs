using Inprotech.Tests.Fakes;
using Inprotech.Tests.Web.Builders.Model.Cases;
using Inprotech.Tests.Web.Builders.Model.Names;
using InprotechKaizen.Model.Names;

namespace Inprotech.Tests.Web.Builders.Model.Accounting
{
    internal class NameLanguageBuilder : IBuilder<NameLanguage>
    {
        readonly InMemoryDbContext _db;

        public NameLanguageBuilder(InMemoryDbContext db)
        {
            _db = db;
        }

        public int? NameId { get; set; }
        public short? Sequence { get; set; }
        public int? LanguageId { get; set; }
        public string ActionId { get; set; }
        public string PropertyTypeId { get; set; }

        public NameLanguage Build()
        {
            var nameLanguage = new NameLanguage
            {
                NameId = NameId ?? new NameBuilder(_db).Build().Id,
                Sequence = Sequence ?? 0,
                LanguageId = LanguageId ?? Fixture.Integer(),
                ActionId = ActionId ?? new ActionBuilder().Build().Code,
                PropertyTypeId = PropertyTypeId ?? new PropertyTypeBuilder().Build().Code
            }.In(_db);

            return nameLanguage;
        }

        public NameLanguage BuildPropertyNameLanguage()
        {
            var nameLanguage = new NameLanguage
            {
                NameId = NameId ?? new NameBuilder(_db).Build().Id,
                Sequence = Sequence ?? 0,
                LanguageId = LanguageId ?? Fixture.Integer(),
                PropertyTypeId = PropertyTypeId ?? new PropertyTypeBuilder().Build().Code
            }.In(_db);

            return nameLanguage;
        }

        public NameLanguage BuildNameOnlyLanguage()
        {
            var nameLanguage = new NameLanguage
            {
                NameId = NameId ?? new NameBuilder(_db).Build().Id,
                Sequence = Sequence ?? 0,
                LanguageId = LanguageId ?? Fixture.Integer()
            }.In(_db);

            return nameLanguage;
        }
    }
}