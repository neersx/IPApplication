using System;
using System.IO;
using System.Linq;
using Inprotech.Integration.ExternalApplications;
using Inprotech.Tests.Integration.DbHelpers;
using Inprotech.Tests.Integration.DbHelpers.Builders;
using Inprotech.Tests.Integration.Utils;
using InprotechKaizen.Model.Documents;
using InprotechKaizen.Model.SchemaMappings;
using Newtonsoft.Json.Linq;

namespace Inprotech.Tests.Integration.IntegrationTests.ApplicationLinkApi
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

            var t = IntegrationDbSetup.Do(x =>
            {
                var inprotech = x.IntegrationDbContext.Set<ExternalApplication>()
                        .Single(_ => _.Name == "INPROTECH");

                inprotech.ExternalApplicationToken = new ExternalApplicationToken
                {
                    CreatedOn = DateTime.Now,
                    CreatedBy = 0,
                    Token = Guid.NewGuid().ToString(),
                    IsActive = true
                };

                x.IntegrationDbContext.SaveChanges();

                return inprotech.ExternalApplicationToken;
            });
            
            return new SchemaMappingApiTestData
            {
                ApiKey = t.Token,
                SchemaMappingId = mapping.Id,
                CaseRef = @case.Irn
            };
        }

        public dynamic SetupDtd(string fileName, bool isValidMapping = true)
        {
            var docItemTrue = InsertWithNewId(new DocItem
            {
                Sql = "SELECT cast(1 as bit)",
                Name = Fixture.Prefix("docitemTrue"),
                Description = Fixture.Prefix("doctiem"),
                ItemType = 0
            });

            var docItem = InsertWithNewId(new DocItem
            {
                Sql = "SELECT 1",
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

            var content = JObject.Parse(isValidMapping ? GetValidMapping(docItemTrue, docItem) : GetErroneousMinimalMapping());

            var root = new JObject
            {
                {"name", "rootNode"},
                {"namespace", "http://tempuri.org/a"},
                {"fileName", fileName},
                {"fileRef", fileName}
            };

            var mapping = Insert(new InprotechKaizen.Model.SchemaMappings.SchemaMapping
            {
                Version = 1,
                Name = Path.GetFileNameWithoutExtension(fileName),
                Content = content.ToString(),
                RootNode = root.ToString(),
                SchemaPackage = sp
            });

            var t = IntegrationDbSetup.Do(x =>
            {
                var inprotech = x.IntegrationDbContext.Set<ExternalApplication>()
                                 .Single(_ => _.Name == "INPROTECH");
                
                inprotech.ExternalApplicationToken = new ExternalApplicationToken
                {
                    CreatedOn = DateTime.Now,
                    CreatedBy = 0,
                    Token = Guid.NewGuid().ToString(),
                    IsActive = true
                };

                x.IntegrationDbContext.SaveChanges();

                return inprotech.ExternalApplicationToken;
            });

            return new SchemaMappingApiTestData
            {
                ApiKey = t.Token,
                SchemaMappingId = mapping.Id
            };
        }

        static string GetValidMapping(DocItem docItemTrue, DocItem docItem)
        {
            return $@"{{""mappingEntries"": {{
                            ""73326c218da1a3f554a08d219793de89"": {{
                                ""fixedValue"": ""en""
                            }},
                            ""4560aafbaa57f61bec5f16f85e02a504"": {{
                                ""fixedValue"": ""applicant""
                            }},
                            ""637933f85975ea63015bd73d83dfe00a"": {{
                                ""fixedValue"": ""1""
                            }},
                            ""6f96f5d8e941660fa331728304cda753"": {{
                                ""fixedValue"": ""ID1""
                            }},
                            ""7ea017049655c0a7c996a6b688db6a1a"": {{
                                ""fixedValue"": ""en""
                            }},
                            ""e106dd0bd06d21eeae72e3ac60a0ce39"": {{
                                ""fixedValue"": ""e2e""
                            }},
                            ""253be677e76d02f2600cbd5eb38f63fe"": {{
                                ""docItemBinding"": {{
                                    ""nodeId"": ""8b76526e995ab01ff4286a38e41aa932"",
                                    ""columnId"": 0,
                                    ""docItemId"": {docItemTrue.Id}
                                }}
                            }},
                            ""8b76526e995ab01ff4286a38e41aa932"": {{
                                ""docItem"": {{
                                    ""id"": {docItemTrue.Id},
                                    ""parameters"": []
                                }}
                            }},
                            ""a5fe9d3c4de1371930d9b4bd85774015"": {{
                                ""docItem"": {{
                                    ""id"": {docItem.Id},
                                    ""parameters"": []
                                }}
                            }}
                        }}
                    }}";
        }

        static string GetErroneousMinimalMapping()
        {
            return $@"{{""mappingEntries"": 
                            {{""73326c218da1a3f554a08d219793de89"": 
                                {{""fixedValue"": ""en"" }}
                             }}
                     }}";
        }
    }

    internal class SchemaMappingApiTestData
    {
        public string ApiKey { get; set; }

        public int SchemaMappingId { get; set; }

        public string StorageFile { get; set; }

        public string CaseRef { get; set; }
    }
}