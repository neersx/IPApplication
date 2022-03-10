using System.IO;
using System.Xml.Linq;
using System.Xml.Serialization;
using Inprotech.IntegrationServer.PtoAccess.Epo.OPS;

namespace Inprotech.Tests.IntegrationServer.PtoAccess.Epo.CpaXmlConversion
{
    internal class WorldPatentFixture
    {
        public bibliographicdata Bibliographicdata { get; private set; }
        public worldpatentdata WorldPatentData { get; private set; }

        public WorldPatentFixture With(XDocument inputXml)
        {
            var serializer = new XmlSerializer(typeof(worldpatentdata));
            WorldPatentData = (worldpatentdata) serializer.Deserialize(new StringReader(inputXml.ToString()));

            var biblioDataConverter = new OpsData();
            Bibliographicdata = biblioDataConverter.GetBibliographicData(inputXml.ToString());

            return this;
        }
    }
}