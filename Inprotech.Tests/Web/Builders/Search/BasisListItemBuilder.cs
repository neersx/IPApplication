namespace Inprotech.Tests.Web.Builders.Search
{
    public class BasisListItemBuilder:IBuilder<BasisListItem>
    {
        public string ApplicationBasisKey { get; set; }

        public string ApplicationBasisDescription { get; set; }

        public string CountryKey { get; set; }

        public int? IsDefaultCountry { get; set; }

        public string PropertyTypeKey { get; set; }

        public string CaseTypeKey { get; set; }

        public string CaseCategoryKey { get; set; }

        public BasisListItem Build()
        {
            return new BasisListItem
                   {
                       ApplicationBasisKey = ApplicationBasisKey ?? Fixture.String(),
                       ApplicationBasisDescription = ApplicationBasisDescription ?? Fixture.String(),
                       CountryKey = CountryKey ?? Fixture.String(),
                       IsDefaultCountry = IsDefaultCountry ?? Fixture.Integer(),
                       PropertyTypeKey = PropertyTypeKey ?? Fixture.String(),
                       CaseTypeKey = CaseTypeKey ?? Fixture.String(),
                       CaseCategoryKey = CaseCategoryKey ?? Fixture.String()
                   };
        }
    }
}