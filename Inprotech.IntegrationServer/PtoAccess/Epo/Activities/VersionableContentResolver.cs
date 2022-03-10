using System;
using System.IO;
using System.Linq;
using System.Reflection;
using System.Threading.Tasks;
using System.Xml.Serialization;
using Inprotech.Infrastructure.Storage;
using Inprotech.Integration.Artifacts;
using Inprotech.IntegrationServer.PtoAccess.Activities;
using Inprotech.IntegrationServer.PtoAccess.Epo.OPS;
using Newtonsoft.Json;
using Newtonsoft.Json.Serialization;

namespace Inprotech.IntegrationServer.PtoAccess.Epo.Activities
{
    public class VersionableContentResolver : IVersionableContentResolver
    {
        readonly IDataDownloadLocationResolver _dataDownloadLocationResolver;
        readonly IBufferedStringReader _bufferedStringReader;

        public VersionableContentResolver(IDataDownloadLocationResolver dataDownloadLocationResolver,
            IBufferedStringReader bufferedStringReader)
        {
            _dataDownloadLocationResolver = dataDownloadLocationResolver;
            _bufferedStringReader = bufferedStringReader;
        }

        public async Task<string> Resolve(DataDownload dataDownload)
        {
            if (dataDownload == null) throw new ArgumentNullException(nameof(dataDownload));
            var appDetailsPath = _dataDownloadLocationResolver.Resolve(dataDownload, PtoAccessFileNames.ApplicationDetails);

            var appDetails = await _bufferedStringReader.Read(appDetailsPath);

            var serializer = new XmlSerializer(typeof (worldpatentdata));

            var searchResults = (worldpatentdata) serializer.Deserialize(new StringReader(appDetails));

            var data = searchResults.registersearch.registerdocuments.Single().registerdocument;

            return JsonConvert.SerializeObject(data,
                Formatting.Indented,
                new JsonSerializerSettings
                {
                    ContractResolver = new IgnoreMateriallyInsignificantContentContractResolver()
                });
        }

        class IgnoreMateriallyInsignificantContentContractResolver : DefaultContractResolver
        {
            static readonly string[] Ignorables = { "id", "dateproduced", "producedby" };

            protected override JsonProperty CreateProperty(MemberInfo member, MemberSerialization memberSerialization)
            {
                var property = base.CreateProperty(member, memberSerialization);

                if (Ignorables.Contains(property.PropertyName))
                {
                    property.ShouldSerialize = instance => false;
                }

                return property;
            }
        }
    }
}