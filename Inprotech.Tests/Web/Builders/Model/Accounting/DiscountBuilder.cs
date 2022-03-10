using InprotechKaizen.Model.Accounting;

namespace Inprotech.Tests.Web.Builders.Model.Accounting
{
    public class DiscountBuilder : IBuilder<Discount>
    {
        public int? Id { get; set; }

        public int? NameId { get; set; }

        public short? Sequence { get; set; }

        public string PropertyTypeId { get; set; }

        public string ActionId { get; set; }

        public decimal? DiscountRate { get; set; }

        public string WipCategory { get; set; }

        public decimal? BasedOnAmount { get; set; }

        public string WipTypeId { get; set; }

        public int? EmployeeId { get; set; }

        public int? ProductCode { get; set; }

        public int? CaseOwnerId { get; set; }

        public int? MarginProfileId { get; set; }

        public string WipCode { get; set; }

        public string CaseTypeId { get; set; }

        public string CountryId { get; set; }

        public Discount Build()
        {
            return new Discount
            {
                Id = Id ?? Fixture.Integer(),
                NameId = NameId ?? Fixture.Integer(),
                Sequence = Sequence ?? Fixture.Short(),
                PropertyTypeId = PropertyTypeId ?? Fixture.String(),
                ActionId = ActionId ?? Fixture.String(),
                DiscountRate = DiscountRate ?? Fixture.Decimal(),
                WipCategory = WipCategory ?? Fixture.String(),
                BasedOnAmount = BasedOnAmount ?? Fixture.Decimal(),
                WipTypeId = WipTypeId ?? Fixture.String(),
                EmployeeId = EmployeeId ?? Fixture.Integer(),
                ProductCode = ProductCode ?? Fixture.Integer(),
                CaseOwnerId = CaseOwnerId ?? Fixture.Integer(),
                MarginProfileId = MarginProfileId ?? Fixture.Integer(),
                WipCode = WipCode ?? Fixture.String(),
                CaseTypeId = CaseTypeId ?? Fixture.String(),
                CountryId = CountryId ?? Fixture.String()
            };
        }
    }
}