using System;
using System.Xml;
using System.Xml.Schema;
using Newtonsoft.Json;
using Newtonsoft.Json.Linq;
using Newtonsoft.Json.Serialization;

namespace Inprotech.Integration.SchemaMapping.Data
{
    public class RootNodeInfo
    {
        XmlQualifiedName _qualifiedName;

        public XmlSchemaElement Node { get; set; }

        public string FileName { get; set; }

        public string FileRef { get; set; }

        public XmlQualifiedName QualifiedName => Node != null ? Node.QualifiedName : _qualifiedName;

        public RootNodeInfo ParseJson(string jsonRootNode)
        {
            var root = JsonConvert.DeserializeObject<JObject>(jsonRootNode);
            _qualifiedName = new XmlQualifiedName(root["name"].ToString(), root["namespace"].ToString());
            FileName = root["fileName"].ToString();
            if (IsDtdFile)
                FileRef = Convert.ToString(root["fileRef"]);
            return this;
        }

        public string ToJsonString()
        {
            return JsonConvert.SerializeObject(new
            {
                QualifiedName.Name,
                QualifiedName.Namespace,
                FileName,
                FileRef
            }, new JsonSerializerSettings { ContractResolver = new CamelCasePropertyNamesContractResolver(), NullValueHandling = NullValueHandling.Ignore });
        }

        public bool IsDtdFile => FileName.EndsWith("dtd", StringComparison.InvariantCultureIgnoreCase);
    }
}