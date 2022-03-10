using System.Collections.Generic;
using System.Linq;
using System.Xml.Linq;
using System.Xml.XPath;
using Inprotech.Web.Picklists;
using Inprotech.Web.Search.CaseSupportData;
using InprotechKaizen.Model;
using InprotechKaizen.Model.Persistence;

namespace Inprotech.Web.Search.Case.CaseSearch
{

    public class TextTopicBuilder : ITopicBuilder
    {
        readonly IDbContext _dbContext;
        readonly ITypeOfMark _typeOfMark;
        public TextTopicBuilder(IDbContext dbContext, ITypeOfMark typeOfMark)
        {
            _dbContext = dbContext;
            _typeOfMark = typeOfMark;
        }

        public CaseSavedSearch.Topic Build(XElement filterCriteria)
        {
            var topic = new CaseSavedSearch.Topic("Text");
            var textType = filterCriteria.XPathSelectElement("CaseTextGroup/CaseText")?.GetStringValue("TypeKey");
            var textTopic = new TextTopic
            {
                Id = filterCriteria.GetAttributeIntValue("ID"),
                TitleMarkValue = filterCriteria.Element("Title")?.GetStringValue(),
                TitleMarkOperator = !string.IsNullOrEmpty(filterCriteria.GetAttributeOperatorExactValue("Title", "Operator"))
                    ? filterCriteria.GetAttributeOperatorValue("Title", "Operator")
                                : (!string.IsNullOrEmpty(filterCriteria.GetAttributeOperatorExactValue("Title","UseSoundsLike"))
                        ? filterCriteria.GetAttributeOperatorValue("Title", "UseSoundsLike")
                        : "2"),
                TitleUseSoundsLike = filterCriteria.GetAttributeOperatorValue("Title","UseSoundsLike"),
                TypeOfMarkValue=GetTypeOfMarkValue(filterCriteria.Element("TypeOfMarkKey")?.GetIntegerNullableValue()),
                TypeOfMarkOperator=filterCriteria.GetAttributeOperatorValue("TypeOfMarkKey", "Operator"),
                TextTypeValue = filterCriteria.XPathSelectElement("CaseTextGroup/CaseText")?.GetStringValue("Text"),
                TextType= string.IsNullOrEmpty(textType) ? null : textType,
                TextTypeOperator=filterCriteria.GetAttributeOperatorValueForXPathElement("CaseTextGroup/CaseText","Operator", Operators.StartsWith),
                KeywordTextValue = filterCriteria.GetAttributeOperatorValue("KeyWord", "Operator") != "0" && filterCriteria.GetAttributeOperatorValue("KeyWord", "Operator") != "1" ? filterCriteria.Element("KeyWord")?.GetStringValue() : string.Empty,
                KeywordOperator = filterCriteria.GetAttributeOperatorValue("KeyWord", "Operator"),
                KeywordValue= filterCriteria.GetAttributeOperatorValue("KeyWord", "Operator") == "0" || filterCriteria.GetAttributeOperatorValue("KeyWord", "Operator") == "1" ? GetKeywordTextValue(filterCriteria.Element("KeyWord")?.GetStringValue()) : null,
            };
            topic.FormData = textTopic;
            return topic;
        }

        KeyValuePair<int, string>? GetTypeOfMarkValue(int? typeOfMarkKey)
        {
            if (!typeOfMarkKey.HasValue) return null;
            return _typeOfMark.Get().FirstOrDefault(_ => _.Key == typeOfMarkKey);
        }

        Keyword GetKeywordTextValue(string value)
        {
            var key = _dbContext.Set<InprotechKaizen.Model.Keywords.Keyword>().SingleOrDefault(_ => _.KeyWord == value);
            return key == null ? null : new Keyword{ Key = key.KeyWord, CaseStopWord = key.StopWord == 1 || key.StopWord == 3};
        }
    }

    public class TextTopic
    {
        public int Id { get; set; }
        
        public string TitleMarkValue { get; set; }
        public string TitleMarkOperator { get; set; }
        public string TitleUseSoundsLike { get; set; }
        
        public KeyValuePair<int, string>? TypeOfMarkValue { get; set; }
        public string TypeOfMarkOperator { get; set; }
   
        public string TextTypeValue { get; set; }
        public string TextType { get; set; }
        public string TextTypeOperator { get; set; }

        public string KeywordTextValue { get; set; }

        public Keyword KeywordValue { get; set; }
        public string KeywordOperator { get; set; }
        
    }
}
