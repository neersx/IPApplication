using System.IO;
using Inprotech.Tests.Integration.DbHelpers;
using Inprotech.Tests.Integration.DbHelpers.Builders;
using Inprotech.Tests.Integration.Utils;
using InprotechKaizen.Model.Documents;
using InprotechKaizen.Model.SchemaMappings;
using Newtonsoft.Json.Linq;

namespace Inprotech.Tests.Integration.IntegrationTests.SchemaMapping
{
    public class SchemaMappingDbSetup : DbSetup
    {
        public dynamic Setup(string fileName)
        {
            var @case = new CaseBuilder(DbContext).Create();

            var docItem = InsertWithNewId(new DocItem
            {
                Sql = "SELECT C.IRN FROM CASES C WHERE C.IRN = :gstrEntryPoint",
                Name = Fixture.Prefix("docitem"),
                Description = Fixture.Prefix("doctiem"),
                ItemType = 0
            });

            var sp = Insert(new SchemaPackage
            {
                IsValid = true,
                Name = Fixture.Prefix("sp")
            });
            
            Insert(new SchemaFile
            {
                Name = fileName,
                SchemaPackage = sp,
                Content = From.EmbeddedAssets(fileName)
            });

            var content = JObject.Parse(
                                        $@"{{
  'mappingEntries': {{
    '71f92e5a392eb332790054869454e917': {{
        'docItemBinding': {{
        'nodeId': '71f92e5a392eb332790054869454e917',
        'columnId': 0,
        'docItemId': {docItem.Id}
      }},
      'docItem': {{
        'id': {docItem.Id},
        'parameters': [
          {{
            'id': 'gstrEntryPoint',
            'type': 'global'
          }}
        ]
      }}
    }}
  }}
}}");

            var root = new JObject
            {
                {"name", "Case"},
                {"namespace", string.Empty},
                {"fileName", fileName}
            };

            var mapping = Insert(new InprotechKaizen.Model.SchemaMappings.SchemaMapping
            {
                Version = 1,
                Name = Path.GetFileNameWithoutExtension(fileName),
                Content = content.ToString(),
                RootNode = root.ToString(),
                SchemaPackage = sp
            });

            return new SchemaMappingApiTestData
            {
                SchemaMappingId = mapping.Id,
                CaseRef = @case.Irn,
                CaseId = @case.Id
            };
        }
    }

    internal class SchemaMappingApiTestData
    {
        public int SchemaMappingId { get; set; }

        public string CaseRef { get; set; }

        public int CaseId { get; set; }
    }
}