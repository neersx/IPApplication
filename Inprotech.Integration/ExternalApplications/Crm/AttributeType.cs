using System.Collections.Generic;
using System.Linq;
using Models = InprotechKaizen.Model.Configuration;

namespace Inprotech.Integration.ExternalApplications.Crm
{
    public class AttributeType
    {
                public AttributeType() { }

                public AttributeType(short id, string name, IEnumerable<Models.TableCode> tableCodes)
        {
            AttributeTypeId = id;
            AttributeTypeDescription = name;

            Attributes = new List<Attribute>();

            tableCodes.ToList().ForEach(tc => Attributes.Add(new Attribute
                                                             {
                                                                 AttributeId = tc.Id,
                                                                 AttributeDescription = tc.Name,
                                                                 AttributeTypeId = tc.TableTypeId
                                                             }));
        }

                public short AttributeTypeId { get; set; }
                public string AttributeTypeDescription { get; set; }
                public List<Attribute> Attributes { get; set; }
    }

    public class Attribute
    {
        public int AttributeId { get; set; }
        public short AttributeTypeId { get; set; }
        public string AttributeDescription { get; set; }
    }
}
