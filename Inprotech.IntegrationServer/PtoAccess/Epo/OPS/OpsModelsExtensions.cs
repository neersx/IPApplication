using System.Collections.Generic;
using System.Linq;
using System.Xml.Serialization;

namespace Inprotech.IntegrationServer.PtoAccess.Epo.OPS
{
    partial class licensee
    {
        [XmlIgnore]
        public licenseeTypelicense typelicenseCustom { get; set; }

        [XmlAttribute("type-license")]
        public string typelicense
        {
            get
            {
                return typelicenseCustom.Convert();
            }
            set
            {
                typelicenseCustom = value.Convert();
            }
        }
    }

    public static class OpsModelsExtensions
    {
        static readonly SortedDictionary<string, licenseeTypelicense> LicenseeTypelicenseMap =
            new SortedDictionary<string, licenseeTypelicense>
            {
                {"right-in-rem", licenseeTypelicense.rightinrem},
                {"right in rem", licenseeTypelicense.rightinrem},
                {"exclusive", licenseeTypelicense.exclusive},
                {"not-exclusive", licenseeTypelicense.notexclusive},
                {"not exclusive", licenseeTypelicense.notexclusive}
            };

        public static licenseeTypelicense Convert(this string typelicenseValue)
        {
            licenseeTypelicense l;

            if (string.IsNullOrWhiteSpace(typelicenseValue) || !LicenseeTypelicenseMap.TryGetValue(typelicenseValue, out l))
                return default(licenseeTypelicense);

            return l;
        }

        public static string Convert(this licenseeTypelicense licenseeTypelicense)
        {
            return LicenseeTypelicenseMap.First(_ => _.Value == licenseeTypelicense).Key;
        }
    }
}
