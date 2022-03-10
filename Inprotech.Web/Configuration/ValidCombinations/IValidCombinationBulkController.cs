namespace Inprotech.Web.Configuration.ValidCombinations
{
    public interface IValidCombinationBulkController
    {
        void Copy(CountryModel fromJurisdiction, CountryModel[] toJurisdictions);
    }
}
