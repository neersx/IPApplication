using System;
using System.Linq;
using Inprotech.IntegrationServer.PtoAccess.Epo.CpaXmlConversion;

namespace Inprotech.IntegrationServer.PtoAccess.Epo.OPS
{
    public static class OpsModelExtensions
    {
        public static string ApplicationNumber(this bibliographicdata bibliographicdata)
        {
            
            if (bibliographicdata.applicationreference == null)
                return null;

            var appRef = bibliographicdata.applicationreference
               .Where(i => i.documentid.Any(j => string.Compare(j.country.Text[0], "EP", StringComparison.OrdinalIgnoreCase) == 0))
               .LatestByChangeGazetteNum(i => i.changegazettenum)
               .SelectMany(i => i.documentid)
               .FirstOrDefault();

            return appRef == null ? null : appRef.docnumber.Text[0];
        }
    }
}
