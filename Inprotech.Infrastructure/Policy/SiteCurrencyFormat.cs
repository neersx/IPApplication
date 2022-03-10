namespace Inprotech.Infrastructure.Policy
{
    public interface ISiteCurrencyFormat
    {
        LocalCurrency Resolve();
    }

    public class SiteCurrencyFormat : ISiteCurrencyFormat
    {
        readonly ISiteControlReader _siteControls;

        public SiteCurrencyFormat(ISiteControlReader siteControls)
        {
            _siteControls = siteControls;
        }

        public LocalCurrency Resolve()
        {
            var localCurrencyCode = _siteControls.Read<string>(SiteControls.CURRENCY);
            var localDecimalPlaces = _siteControls.Read<bool>(SiteControls.CurrencyWholeUnits)
                ? 0
                : 2;

            return new LocalCurrency
            {
                LocalCurrencyCode = localCurrencyCode,
                LocalDecimalPlaces = localDecimalPlaces
            };
        }
    }

    public class LocalCurrency
    {
        public string LocalCurrencyCode { get; set; }
        public int LocalDecimalPlaces { get; set; }
    }
}