using System.IO;
using System.Linq;
using System.Xml.Serialization;

namespace Inprotech.IntegrationServer.PtoAccess.Epo.OPS
{
    public interface IOpsData
    {
        worldpatentdata GetPatentData(string xml);
        bibliographicdata GetBibliographicData(string xml);
    }

    public class OpsData : IOpsData
    {
        public worldpatentdata GetPatentData(string xml)
        {
            var serializer = new XmlSerializer(typeof(worldpatentdata));
            return (worldpatentdata)serializer.Deserialize(new StringReader(xml)) ?? new worldpatentdata();
        }

        public bibliographicdata GetBibliographicData(string xml)
        {
            var wpd = GetPatentData(xml);
            
            return wpd.registersearch
               .registerdocuments
               .SelectMany(a => a.registerdocument)
               .Select(b => b.bibliographicdata)
               .FirstOrDefault() ?? new bibliographicdata();
        }
    }
}
