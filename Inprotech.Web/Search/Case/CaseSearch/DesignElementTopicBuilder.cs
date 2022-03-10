using System.Xml.Linq;
using InprotechKaizen.Model;

namespace Inprotech.Web.Search.Case.CaseSearch
{
    public class DesignElementTopicBuilder : ITopicBuilder
    {
        public CaseSavedSearch.Topic Build(XElement filterCriteria)
        {
            var topic = new CaseSavedSearch.Topic("designElement");
            var formData = new DesignElementTopic
            {
                Id = filterCriteria.GetAttributeIntValue("ID"),
                FirmElementOperator = Operators.EqualTo,
                ClientElementOperator = Operators.EqualTo,
                OfficialElementOperator = Operators.EqualTo,
                RegistrationNoOperator = Operators.EqualTo,
                TypefaceOperator = Operators.EqualTo,
                ElementDescriptionOperator = Operators.EqualTo
            };
            topic.FormData = formData;
            return topic;
        }
    }

    public class DesignElementTopic
    {
        public int Id { get; set; }
        public string FirmElementOperator { get; set; }
        public string ClientElementOperator { get; set; }
        public string OfficialElementOperator { get; set; }
        public string RegistrationNoOperator { get; set; }
        public string TypefaceOperator { get; set; }
        public string ElementDescriptionOperator { get; set; }
    }
}
