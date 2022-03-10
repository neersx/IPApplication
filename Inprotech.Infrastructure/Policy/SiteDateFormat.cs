using System.Globalization;

namespace Inprotech.Infrastructure.Policy
{
    public interface ISiteDateFormat
    {
        string Resolve(string culture = null);
    }

    public class SiteDateFormat : ISiteDateFormat
    {
        readonly ISiteControlReader _siteControl;

        public SiteDateFormat(ISiteControlReader siteControl)
        {
            _siteControl = siteControl;
        }

        public string Resolve(string culture = null)
        {
            if (!string.IsNullOrEmpty(culture) && (culture.StartsWith("zh") || culture.StartsWith("ko-") || culture == "ko"))
            {
                return CultureInfo.CurrentCulture.DateTimeFormat.ShortDatePattern;
            }

            var dateFormatSiteControl = _siteControl.Read<int>(SiteControls.DateStyle);
            switch (dateFormatSiteControl)
            {
                case 0:
                    return !string.IsNullOrEmpty(culture) ? CultureInfo.GetCultureInfo(culture).DateTimeFormat.ShortDatePattern : CultureInfo.CurrentCulture.DateTimeFormat.ShortDatePattern;
                case 1:
                    return "dd-MMM-yyyy";
                case 2:
                    return "MMM-dd-yyyy";
                case 3:
                    return "yyyy-MMM-dd";
            }

            return string.Empty;
        }
    }
}
