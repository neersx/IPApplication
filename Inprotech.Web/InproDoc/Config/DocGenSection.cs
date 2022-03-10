using System.Configuration;

namespace Inprotech.Web.InproDoc.Config
{
    public class DocGenSection : ConfigurationSection
    {
        [ConfigurationProperty("entryPoints", IsDefaultCollection = false)]
        public EntryPointsCollection EntryPoints => (EntryPointsCollection) base["entryPoints"];
    }
}