using System;
using System.Collections.Generic;
using System.Linq;
using System.Xml.Linq;
using Inprotech.Infrastructure.Localisation;
using Inprotech.Web.Picklists;
using InprotechKaizen.Model;
using InprotechKaizen.Model.Configuration;
using InprotechKaizen.Model.Persistence;
using ServiceStack.Text;

namespace Inprotech.Web.Search.Case.CaseSearch
{
    public class AttributesTopicBuilder : ITopicBuilder
    {
        readonly IPreferredCultureResolver _preferredCultureResolver;
        readonly IDbContext _dbContext;

        public AttributesTopicBuilder(IDbContext dbContext, IPreferredCultureResolver preferredCultureResolver)
        {
            _dbContext = dbContext;
            _preferredCultureResolver = preferredCultureResolver;
        }

        public CaseSavedSearch.Topic Build(XElement filterCriteria)
        {
            var topic = new CaseSavedSearch.Topic("attributes");
            var namesTopic = new AttributesTopic
            {
                Id = filterCriteria.GetAttributeIntValue("ID"),
                BooleanAndOr = filterCriteria.Element("AttributeGroup")!= null ? filterCriteria.Element("AttributeGroup").GetAttributeIntValue("BooleanOr") : 0,
                Attribute1 = new AttributeOperatorType
                {
                    AttributeOperator = Operators.EqualTo
                },
                Attribute2 = new AttributeOperatorType
                {
                    AttributeOperator = Operators.EqualTo
                },
                Attribute3 = new AttributeOperatorType
                {
                    AttributeOperator = Operators.EqualTo
                }
            };

            var attributes = filterCriteria.Element("AttributeGroup")?.Elements().ToArray();
            if (attributes != null && attributes.Any())
            {
                var attr1 = attributes[0];
                if (attr1 != null)
                {
                    namesTopic.Attribute1.AttributeType = GetAttributeType(attr1);
                    namesTopic.Attribute1.AttributeOperator = attr1.GetAttributeOperatorValue("Operator");
                    namesTopic.Attribute1.AttributeValue = GetAttributeValue(attr1);
                }

                if (attributes.Length > 1)
                {
                    var attr2 = attributes[1];
                    if (attr2 != null)
                    {
                        namesTopic.Attribute2.AttributeType = GetAttributeType(attr2);
                        namesTopic.Attribute2.AttributeOperator = attr2.GetAttributeOperatorValue("Operator");
                        namesTopic.Attribute2.AttributeValue = GetAttributeValue(attr2);
                    }
                }

                if (attributes.Length > 2)
                {
                    var attr3 = attributes[2];
                    if (attr3 != null)
                    {
                        namesTopic.Attribute3.AttributeType = GetAttributeType(attr3);
                        namesTopic.Attribute3.AttributeOperator = attr3.GetAttributeOperatorValue("Operator");
                        namesTopic.Attribute3.AttributeValue = GetAttributeValue(attr3);
                    }
                }
            }

            topic.FormData = namesTopic;
            return topic;
        }

        Dictionary<string, string> GetAttributeType(XElement filterCriteria)
        {
            var attrType = filterCriteria.GetStringValue("TypeKey");
            if (string.IsNullOrEmpty(attrType)) return null;

            var type = Convert.ToInt16(attrType);
            var culture = _preferredCultureResolver.Resolve();
            var attributeType = _dbContext.Set<TableType>().FirstOrDefault(_ => _.Id == type);
                      
            return attributeType != null? new
                      {
                          Key = attributeType.Id.ToString(),
                          Value = DbFuncs.GetTranslation(attributeType.Name, null, attributeType.NameTId, culture)
                      }.ToStringDictionary() : null;
        }

        TableCodePicklistController.TableCodePicklistItem GetAttributeValue(XElement attribute)
        {
            var attrKey = attribute.GetStringValue("AttributeKey");
            var attrType = attribute.GetStringValue("TypeKey");
            if (string.IsNullOrEmpty(attrType) || string.IsNullOrEmpty(attrKey)) return null;

            var type = Convert.ToInt16(attrType);
            var id = Convert.ToInt32(attrKey);
            var culture = _preferredCultureResolver.Resolve();

            var useOffice = _dbContext.Set<TableType>().Any(_ => _.Id == type && _.DatabaseTable.ToUpper().Equals("OFFICE"));
            dynamic list;
            if (useOffice)
            {
                list = _dbContext.Set<InprotechKaizen.Model.Cases.Office>().FirstOrDefault(_ => _.Id == id);
            }
            else
            {
                list = _dbContext.Set<TableCode>().SingleOrDefault(_ => _.Id == id);
            }

            return list != null ?
                new TableCodePicklistController.TableCodePicklistItem
                {
                    Key = list.Id,
                    Value = DbFuncs.GetTranslation(list.Name, null, list.NameTId, culture),
                    Code = list.UserCode ?? string.Empty,
                    TypeId = type
                }
                : null;
        }
    }

    public class AttributesTopic
    {
        public int Id { get; set; }
        public int BooleanAndOr { get; set; }
        public AttributeOperatorType Attribute1 { get; set; }
        public AttributeOperatorType Attribute2 { get; set; }
        public AttributeOperatorType Attribute3 { get; set; }

    }

    public class AttributeOperatorType
    {
        public Dictionary<string, string> AttributeType { get; set; }
        public string AttributeOperator { get; set; }

        public TableCodePicklistController.TableCodePicklistItem AttributeValue { get; set; }
    }
}
