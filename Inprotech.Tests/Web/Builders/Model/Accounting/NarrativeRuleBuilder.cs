using Inprotech.Tests.Fakes;
using InprotechKaizen.Model.Accounting;

namespace Inprotech.Tests.Web.Builders.Model.Accounting
{
    public class NarrativeRuleBuilder : IBuilder<NarrativeRule>
    {
        readonly InMemoryDbContext _db;

        public NarrativeRuleBuilder(InMemoryDbContext db)
        {
            _db = db;
        }

        public int? DebtorId { get; set; }
        public string WipCode { get; set; }
        public int? StaffId { get; set; }
        public string CaseTypeId { get; set; }
        public string PropertyTypeId { get; set; }
        public string CaseCategoryId { get; set; }
        public string SubTypeId { get; set; }
        public int? TypeOfMarkId { get; set; }
        public bool? IsLocalCountry { get; set; }
        public bool? IsForeignCountry { get; set; }
        public string CountryCode { get; set; }

        public NarrativeRule Build()
        {
            var narrativePrefix = Fixture.RandomString(6);
            var narrative = new Narrative
            {
                NarrativeId = Fixture.Short(),
                NarrativeCode = narrativePrefix,
                NarrativeTitle = Fixture.String(narrativePrefix) + " " + Fixture.RandomString(43),
                NarrativeText = Fixture.String(narrativePrefix)
            }.In(_db);

            var narrativeRule = new NarrativeRule
            {
                StaffId = StaffId,
                DebtorId = DebtorId,
                WipCode = WipCode ?? Fixture.RandomString(6),
                CaseTypeId = CaseTypeId,
                PropertyTypeId = PropertyTypeId,
                CaseCategoryId = CaseCategoryId,
                SubTypeId = SubTypeId,
                TypeOfMark = TypeOfMarkId,
                IsLocalCountry = IsLocalCountry,
                IsForeignCountry = IsForeignCountry,
                CountryCode = CountryCode,
                NarrativeId = narrative.NarrativeId
            };
            narrativeRule.In(_db);

            return narrativeRule;
        }
    }
}