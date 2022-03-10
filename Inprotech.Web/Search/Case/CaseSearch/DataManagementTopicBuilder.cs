using System;
using System.Linq;
using System.Xml.Linq;
using InprotechKaizen.Model;
using InprotechKaizen.Model.Components.Names;
using InprotechKaizen.Model.Components.Security;
using InprotechKaizen.Model.Names;
using InprotechKaizen.Model.Persistence;

namespace Inprotech.Web.Search.Case.CaseSearch
{
    public class DataManagementTopicBuilder : ITopicBuilder
    {
        readonly IDbContext _dbContext;
        readonly INameAccessSecurity _nameAccessSecurity;

        public DataManagementTopicBuilder(IDbContext dbContext, INameAccessSecurity nameAccessSecurity)
        {
            _dbContext = dbContext;
            _nameAccessSecurity = nameAccessSecurity;
        }

        public CaseSavedSearch.Topic Build(XElement filterCriteria)
        {
            var topic = new CaseSavedSearch.Topic("dataManagement");
            var formData = new DataManagementTopic
            {
                Id = filterCriteria.GetAttributeIntValue("ID"),
                BatchIdentifier = filterCriteria.GetStringValue("EDEBatchIdentifier"),
                DataSource = GetEdeDatasource(filterCriteria),
                SentToCPA = filterCriteria.GetIntegerNullableValue("CPASentBatchNo")
            };
            topic.FormData = formData;
            return topic;
        }

        Picklists.Name GetEdeDatasource(XElement filterCriteria)
        {
            var ds = filterCriteria.GetStringValue("EDEDataSourceNameNo");

            if (string.IsNullOrEmpty(ds)) return null;

            var dataSourceKey = Convert.ToInt32(ds);

            var edeName = _dbContext.Set<NameAlias>().SingleOrDefault(_ => _.Name.Id == dataSourceKey && _.AliasType.Code == KnownAliasTypes.EdeIdentifier);

            if (edeName == null) return null;
            var accessibleName = _nameAccessSecurity.CanView(edeName.Name);

            return accessibleName
                ? new Picklists.Name
                {
                    Key = edeName.Name.Id,
                    Code = edeName.Name.NameCode,
                    DisplayName = edeName.Name.Formatted(),
                    Remarks = edeName.Name.Remarks
                }
                : null;
        }
    }

    public class DataManagementTopic
    {
        public int Id { get; set; }
        public Picklists.Name DataSource { get; set; }

        public string BatchIdentifier { get; set; }

        public int? SentToCPA { get; set; }
    }
}
